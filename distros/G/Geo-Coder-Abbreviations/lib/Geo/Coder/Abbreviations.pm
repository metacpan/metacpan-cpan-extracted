package Geo::Coder::Abbreviations;

use warnings;
use strict;
use JSON;
use LWP::Simple;

=head1 NAME

Geo::Coder::Abbreviations - Quick and Dirty Interface to https://github.com/mapbox/geocoder-abbreviations

=head1 VERSION

Version 0.04

=cut

our %abbreviations;
our $VERSION = '0.04';

=head1 SYNOPSIS

Provides an interface to https://github.com/mapbox/geocoder-abbreviations.
One small function for now, I'll add others later.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Geo::Coder::Abbreviations object.
It takes no arguments.
If you have L<HTTP::Cache::Transparent> installed, it will load much
faster, otherwise it will download the database from the Internet
when the class is first instatiated.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	unless(scalar keys(%abbreviations)) {
		if(eval { require HTTP::Cache::Transparent; }) {
			require File::Spec;	# That should be installed

			File::Spec->import();
			HTTP::Cache::Transparent->import();

			my $cachedir;
			if(my $e = $ENV{'CACHEDIR'}) {
				$cachedir = File::Spec->catfile($e, 'http-cache-transparent');
			} else {
				$cachedir = File::Spec->catfile(File::Spec->tmpdir(), 'cache', 'http-cache-transparent');
			}

			HTTP::Cache::Transparent::init({
				BasePath => $cachedir,
				# Verbose => $opts{'v'} ? 1 : 0,
				NoUpdate => 60 * 60 * 24,
				MaxAge => 30 * 24
			}) || die "$0: $cachedir: $!";
		}

		my $data = get('https://raw.githubusercontent.com/mapbox/geocoder-abbreviations/master/tokens/en.json');

		die unless(defined($data));

		%abbreviations = map {
			my %rc = ();
			if(defined($_->{'type'}) && ($_->{'type'} eq 'way')) {
				foreach my $token(@{$_->{'tokens'}}) {
					$rc{uc($token)} = uc($_->{'canonical'});
				}
			}
			%rc;
		} @{JSON->new()->utf8()->decode($data)};
		# %abbreviations = map { (defined($_->{'type'}) && ($_->{'type'} eq 'way')) ? (uc($_->{'full'}) => uc($_->{'canonical'})) : () } @{JSON->new()->utf8()->decode($data)};
	}

	return bless {
		table => \%abbreviations
	}, $class;
}

=head2 abbreviate

Abbreviate a place.

    use Geo::Coder::Abbreviations;

    my $abbr = Geo::Coder::Abbreviations->new();
    print $abbr->abbreviate('Road'), "\n";	# prints 'RD'
    print $abbr->abbreviate('RD'), "\n";	# prints 'RD'

=cut

sub abbreviate {
	my $self = shift;

	return $self->{'table'}->{uc(shift)};
}

=head1 SEE ALSO

L<https://github.com/mapbox/geocoder-abbreviations>
L<HTTP::Cache::Transparent>

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
