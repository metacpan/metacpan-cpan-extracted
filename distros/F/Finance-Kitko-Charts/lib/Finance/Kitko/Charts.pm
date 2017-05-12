package Finance::Kitko::Charts;

use 5.006;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Finance::Kitko::Charts - Retrieve URLs for gold and silver quotes.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Finance::Kitko::Charts;

    my $charts = Finance::Kitko::Charts->new();

    # all share the same API, see bellow
    $data = $charts->gold();
    $data = $charts->silver();
    $data = $charts->platinum();
    $data = $charts->palladium();

=head1 USAGE

Call the method, receive a hash table reference. Keys for different
views ('24h' for 24 hour comparison, 'ny' for New York chart, '30d'
for a month, '60d' for two months, '6m' for six months, '1y' for one
year and '5y' for five years.

=head1 AVAILABLE METHODS

=head2 new

Returns a new Finance::Kitko::Charts object.

=cut

sub new {
    my $c = shift;
    return bless {}, $c;
}

=head2 gold

=cut

sub gold {
    my ($self, %opts) = @_;
    $self->_fetch( gold => %opts );
}

=head2 silver

=cut

sub silver {
    my ($self, %opts) = @_;
    $self->_fetch( silver => %opts );
}

=head2 platinum

=cut

sub platinum {
    my ($self, %opts) = @_;
    $self->_fetch( platinum => %opts );
}


=head2 palladium

=cut

sub palladium {
    my ($self, %opts) = @_;
    $self->_fetch( palladium => %opts );
}

sub _fetch {
    my ($self, $metal, %opts) = @_;

    my %symb = qw(silver ag gold au platinum pt palladium pd);

    return {
            '24h' => sprintf("http://www.kitco.com/images/live/%sw.gif", $metal),
            'ny'  => sprintf("http://www.kitco.com/images/live/ny%sw.gif", $metal),
            '30d' => sprintf("http://www.kitco.com/LFgif/%s0030lnb.gif", $symb{$metal}),
            '60d' => sprintf("http://www.kitco.com/LFgif/%s0060lnb.gif", $symb{$metal}),
            '6m'  => sprintf("http://www.kitco.com/LFgif/%s0182nyb.gif", $symb{$metal}),
            '1y'  => sprintf("http://www.kitco.com/LFgif/%s0365nyb.gif", $symb{$metal}),
            '5y'  => sprintf("http://www.kitco.com/LFgif/%s1825nyb.gif", $symb{$metal})
           };
}

=head1 AUTHOR

Alberto Simões, C<< <ambs at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-kitko-charts at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Kitko-Charts>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Kitko::Charts


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Kitko-Charts>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Kitko-Charts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Kitko-Charts>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Kitko-Charts/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Alberto Simões.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Finance::Kitko::Charts
