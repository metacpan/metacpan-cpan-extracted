package Dezi::Admin::Utils;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use JSON;
use Sort::SQL;
use Search::QueryParser::SQL;

our $VERSION = '0.006';

sub json_mime_type {'application/json'}

sub params_to_sql {
    my $req = shift or croak "Plack::Request required";
    my $tbl = shift or croak "table_name required";
    my $columns = shift || [];
    my ( $where, $args, $order_by, $limit, $offset, $sort, $dir );

    # sane defaults
    $limit  = 50;
    $offset = 0;

    my $params = $req->parameters;
    if ( exists $params->{limit} ) {
        $limit = $params->{limit};
        $limit =~ s/\D//g;    # no injection
    }
    if ( exists $params->{start} ) {
        $offset = $req->parameters->{start};
        $offset =~ s/\D//g;    # no injection
    }
    if ( exists $params->{q} ) {

        # postgresql needs 'ILIKE' to work like mysql 'LIKE'
        # but sqlite does not support ILIKE.
        # compromise with 'LIKE' which works everywhere.

        my $qp = Search::QueryParser::SQL->new(
            columns => $columns,
            like    => 'LIKE',
        );

        my $query = $qp->parse( $params->{q} )->dbi;
        $where = $query->[0];
        $args  = $query->[1];
    }
    if ( exists $params->{sort} ) {
        my $dir = $params->{dir} || 'ASC';
        my $order = Sort::SQL->parse( $params->{sort} . ' ' . $dir );
        $order_by = join( ', ', map { join( ' ', @$_ ) } @$order );
        $sort     = $order->[0]->[0];
        $dir      = $order->[0]->[1];
    }

    my $sql       = "select * from $tbl";
    my $sql_count = "select count(*) from $tbl";
    if ($where) {
        $sql       .= " where $where ";
        $sql_count .= " where $where ";
    }
    if ($order_by) {
        $sql .= " order by $order_by ";
    }
    if ( defined $limit ) {
        $sql .= " limit $limit ";
    }
    if ( defined $offset ) {
        $sql .= " offset $offset ";
    }

    return (
        sql       => $sql,
        count     => $sql_count,
        args      => $args,
        where     => $where,
        'sort'    => $sort,
        direction => $dir,
        limit     => $limit,
        offset    => $offset,
    );

}

1;

__END__

=head1 NAME

Dezi::Admin::Utils - Dezi administration utility functions

=head1 SYNOPSIS

 use Dezi::Admin::Utils;
 
 my %sql = Dezi::Admin::Utils::params_to_sql(
    $req, 
    $table_name, 
    [qw( name color )]
 );
        
=head1 DESCRIPTION

Dezi::Admin utility functions.

=head1 FUNCTIONS

=head2 json_mime_type

Returns appropriate MIME type string.

=head2 params_to_sql( I<plack_request>, I<table_name>[, I<columns>] )

Returns SQL derived from incoming
parameters in I<plack_request>. Key/value pairs are returned, where keys are:

=over

=item sql

SQL string returning matching rows

=item count

SQL string returning total count

=item args

Array of values to be passed to $sth->execute(). May be undefined,
in which case do not pass to execute().

=item where

WHERE clause.

=item order_by

ORDER BY clause.

=item limit

Integer

=item offset

Integer

=item sort

Column name in ORDER BY clause.

item direction

ORDER BY direction (C<ASC> or C<DESC>).

=back

Options I<columns> should be an array
ref of column names for I<where>.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-admin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Admin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Admin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Admin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Admin>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Admin/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
