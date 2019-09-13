package Locale::Codes::Country::FR;

use warnings;
use strict;

use Data::Section::Simple;
use Locale::Codes::Country;

our @ISA = ('Locale::Codes::Country');

=head1 NAME

Locale::Codes::Country::FR - French countries

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

A sub-class of L<Locale::Codes> which adds country names in French and
genders of the countries.

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Locale::Codes::Country::FR object.
=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	return bless { }, $class;
}

=head2 en_country2gender

Take a country (in English) and return 'M' and 'F'.
Can be used in OO or procedural mode.

=cut

sub en_country2gender {
	my $arg = shift;
	
	if(ref($arg) ne __PACKAGE__) {
		return __PACKAGE__->new()->en_country2gender($arg);
	}

	my $country = $arg->country2fr(shift);

	# FIXME:  Exceptions e.g. Mexico
	if($country =~ /e$/) {
		return 'F';
	}
	return 'M';
}

=head2 country2fr

Given a country in English, translate into French.
Can be used in OO or procedural mode.

=cut

sub country2fr {
	my $arg = shift;
	
	if(ref($arg) ne __PACKAGE__) {
		return __PACKAGE__->new()->country2fr($arg);
	}

	my $english = shift;

	my $data = Data::Section::Simple::get_data_section('countries');

	my @line = split /\n/, $data;

	for (@line) {
		my($en, $fr) = split /:/;
		if($en eq $english) {
			return $fr;
		}
	}
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

Lots of countries to be done.  This initial release is a POC.

Gender exceptions aren't handled.

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

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-Codes-Country-FR>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-Codes-Country-FR/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2019 Nigel Horne.

This program is released under the following licence: GPL2

=cut

1;
__DATA__
@@ countries
Australia:Australie
Canada:Canada
England:Angleterre
France:France
New Zealand:Nouvelle-Zélande
Scotland:Écosse
United States:Etats-Unis
USA:Etats-Unis
