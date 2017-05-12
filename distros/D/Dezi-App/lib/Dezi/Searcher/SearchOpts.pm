package Dezi::Searcher::SearchOpts;
use Moose;
with 'Dezi::Role';
use Carp;
use Types::Standard qw( Int ArrayRef Str Maybe );
use namespace::autoclean;

our $VERSION = '0.014';

has 'start' => (
    is      => 'rw',
    isa     => Int,
    lazy    => 1,
    default => sub {0}
);
has 'max' => (
    is      => 'rw',
    isa     => Maybe [Int],
    lazy    => 1,
    default => sub {1000},
);
has 'order' => ( is => 'rw' );                    # search() must handle isa
has 'limit' => ( is => 'rw', isa => ArrayRef );
has 'default_boolop' => (
    is      => 'rw',
    isa     => Str,
    lazy    => 1,
    default => sub {'AND'}
);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Dezi::Searcher::SearchOpts - options for the Dezi::Searcher->search method

=head1 SYNOPSIS

 use Dezi::Searcher;
 my $searcher = Dezi::Searcher->new();
 my $results  = $searcher->search( 'foo bar', {
     start => 0,
     max   => 1000,
     order => 'title DESC',
     limit => [ [qw( lastmod 100000 200000 )] ],
     default_boolop => 'AND',
 });
 my $opts = $results->opts;  # isa Dezi::Searcher::SearchOpts

=head1 METHODS

The following attributes are defined.

=over

=item start

The starting position. Default is 0.

=item max

The ending position. Default is max_hits() as documented
in Dezi::Searcher.

=item order

Takes a SQL-like text string (parse-able by L<Sort::SQL>),
or an object defined by the Searcher class, which will determine the sort order.

=item limit

Takes an arrayref of arrayrefs. Each child arrayref should
have three values: a field (PropertyName) value, a lower limit
and an upper limit.

=item default_boolop

The default boolean connector for parsing I<query>. Valid values
are B<AND> and B<OR>. The default is
B<AND> (which is different than Lucy::QueryParser, but the
same as Swish-e).

=back

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Searcher::SearchOpts

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>
