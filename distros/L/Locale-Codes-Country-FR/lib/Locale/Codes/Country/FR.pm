package Locale::Codes::Country::FR;

use warnings;
use strict;

use Data::Section::Simple;
use Locale::Codes::Country;
use Scalar::Util;

our @ISA = ('Locale::Codes::Country');

=head1 NAME

Locale::Codes::Country::FR - French countries

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

DO NOT USE YET - THIS IS STILL P.O.C. code.

C<Locale::Codes::Country::FR> is a Perl module that extends L<Locale::Codes::Country> by adding French translations of country names and determining their grammatical gender based on naming conventions.
It provides an easy-to-use interface for converting English country names into French and classifying them as masculine or feminine.
The module supports both object-oriented and procedural usage.
This module will be useful for applications requiring localized country names and gender classification in French.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Locale::Codes::Country::FR object.

=cut

sub new {
	my $class = shift;

	if(!defined($class)) {
		# FIXME: this only works when no arguments are given
		$class = __PACKAGE__;
	} elsif(Scalar::Util::blessed($class)) {
		# If $class is an object, clone it with new arguments
		return bless { %{$class} }, ref($class);
	}

	# Return the blessed object
	return bless { }, $class;
}

=head2 en_country2gender

Take a country (in English) and return 'M' and 'F'.
Can be used in OO or procedural mode.

=cut

sub en_country2gender
{
	my ($self, $country) = @_;

	# Ensure we are working within the object context
	unless(ref $self && (ref($self) eq __PACKAGE__)) {
		return __PACKAGE__->new->en_country2gender($self);
	}

	# Translate country to French equivalent
	$country = $self->country2fr($country);

	return if(!defined($country));

	# Masculine countries that and with an 'e'
	if(($country eq 'Mexique') || ($country eq 'Mozambique')) {
		return 'M';
	}

	# Determine gender based on French spelling convention
	return $country =~ /e$/i ? 'F' : 'M';
}

=head2 country2fr

Given a country in English, translate into French.
Can be used in OO or procedural mode.

=cut

sub country2fr {
	my ($self, $english) = @_;

	# Ensure we are working within the object context
	unless(ref $self && (ref($self) eq __PACKAGE__)) {
		return __PACKAGE__->new->country2fr($self);
	}

	# Load the country data section once
	$self->{country_map} ||= { map { split /:/ } split /\n/, Data::Section::Simple::get_data_section('countries') };

	return $self->{country_map}{$english};
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to the author.
This module is provided as-is without any warranty.

Lots of countries to be done.
This initial release is a POC.
While it covers a basic set of country names,
future improvements may include handling gender exceptions and expanding the dataset.

Gender exceptions aren't handled fully.

Please report any bugs or feature requests to C<bug-locale-codes-country at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Locale-Codes-Country-FR>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

params() returns a ref which means that calling routines can change the hash
for other routines.
Take a local copy before making amendments to the table if you don't want unexpected
things to happen.

=head1 SEE ALSO

L<Locale::Codes>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::Codes::Country::FR

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-Codes-Country-FR>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-Codes-Country-FR/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019-2025 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
__DATA__
@@ countries
Australia:Australie
Algeria::Algérie
Belgium::Belgique
Canada:Canada
England:Angleterre
France:France
Mexico::Mexique
Mozambique::Mozambique
New Zealand:Nouvelle-Zélande
Netherlands::Pays-Bas
Scotland:Écosse
Senegal::Sénégal
United States:États-Unis
USA:États-Unis
