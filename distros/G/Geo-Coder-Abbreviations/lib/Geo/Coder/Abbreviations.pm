package Geo::Coder::Abbreviations;

use warnings;
use strict;
use JSON;
use LWP::Simple;

=head1 NAME

Geo::Coder::Abbreviations - Quick and Dirty Interface to https://github.com/mapbox/geocoder-abbreviations

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Provides an interface to https://github.com/mapbox/geocoder-abbreviations.
One small function for now, I'll add others later.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Geo::Coder::Abbreviations object.
It takes no arguments.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my $data = get('https://raw.githubusercontent.com/mapbox/geocoder-abbreviations/master/tokens/en.json');
	my %abbreviations = map { uc($_->{'full'}) => uc($_->{'canonical'}) } @{JSON->new()->utf8()->decode($data)};

	return bless {
		table => \%abbreviations
	}, $class;
}

=head2 abbreviate

Abbreviate a place.

	use Geo::Coder::Abbreviations;

	my $abbr = Geo::Coder::Abbreviations->new();
	print $abbr->abbreviate('Road'), "\n";	# prints 'RD'

=cut

sub abbreviate {
	my $self = shift;

	return $self->{'table'}->{uc(shift)};
}

=head1 SEE ALSO

L<https://github.com/mapbox/geocoder-abbreviations>

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Abbreviations

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geo-Coder-Abbreviations>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Abbreviations>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Abbreviations/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2020 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1; # End of Geo::Coder::Abbreviations
