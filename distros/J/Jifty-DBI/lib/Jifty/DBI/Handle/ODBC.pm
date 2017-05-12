package Jifty::DBI::Handle::ODBC;
use Jifty::DBI::Handle;
@ISA = qw(Jifty::DBI::Handle);

use vars qw($VERSION @ISA $DBIHandle $DEBUG);
use strict;

=head1 NAME

  Jifty::DBI::Handle::ODBC - An ODBC specific Handle object

=head1 SYNOPSIS


=head1 DESCRIPTION

This module provides a subclass of L<Jifty::DBI::Handle> that
compensates for some of the idiosyncrasies of ODBC.

=head1 METHODS

=cut

=head2 case_sensitive

Returns a false value.

=cut

sub case_sensitive {
    my $self = shift;
    return (undef);
}

=head2 build_dsn

=cut

sub build_dsn {
    my $self = shift;
    my %args = (
        driver   => undef,
        database => undef,
        host     => undef,
        port     => undef,
        @_
    );

    $args{dbname} ||= delete $args{database};

    my $dsn = "dbi:$args{driver}:$args{dbname}";
    $dsn .= ";host=$args{'host'}" if $args{'host'};
    $dsn .= ";port=$args{'port'}" if $args{'port'};

    $self->{'dsn'} = $dsn;
}

=head2 apply_limits

=cut

sub apply_limits {
    my $self         = shift;
    my $statementref = shift;
    my $per_page     = shift or return;
    my $first        = shift;

    my $limit_clause = " TOP $per_page";
    $limit_clause .= " OFFSET $first" if $first;
    $$statementref =~ s/SELECT\b/SELECT $limit_clause/;
}

=head2 distinct_query

=cut

sub distinct_query {
    my $self         = shift;
    my $statementref = shift;
    my $collection   = shift;

    $$statementref = "SELECT main.* FROM $$statementref";
    $$statementref .= $collection->_group_clause;
    $$statementref .= $collection->_order_clause;
}

=head2 encoding

=cut

sub encoding {
}

1;

__END__

=head1 AUTHOR

Audrey Tang C<cpan@audreyt.org>

=head1 SEE ALSO

L<Jifty::DBI>, L<Jifty::DBI::Handle>, L<DBD::ODBC>

=cut
