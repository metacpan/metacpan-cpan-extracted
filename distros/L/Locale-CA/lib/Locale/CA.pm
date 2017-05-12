package Locale::CA;

use warnings;
use strict;
use Data::Section::Simple;

=head1 NAME

Locale::CA - two letter codes for province identification in Canada and vice versa

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Locale::CA;

    my $u = Locale::CA->new();

    my $province = $u->{code2province}{$code};
    my $code  = $u->{province2code}{$province};

    my @province = $u->all_province_names;
    my @code  = $u->all_province_codes;


=head1 SUBROUTINES/METHODS

=head2 new

Creates a Locale::CA object.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	return unless(defined($class));

	my $self = {};

	my $data = Data::Section::Simple::get_data_section('provinces');

	my @line = split "\n", $data;

	for (@line) {
		my($code, $province) = split ':';
		$self->{code2province}{$code} = $province;
		$self->{province2code}{$province} = $code;
	}

	return bless $self, $class;
}

=head2 all_province_codes

Returns an array (not arrayref) of all province codes in alphabetical form.

=cut

sub all_province_codes {
	my $self = shift;

	return(sort keys %{$self->{code2province}});
}

=head2 all_province_names

Returns an array (not arrayref) of all province names in alphabetical form

=cut

sub all_province_names {
	my $self = shift;

	return(sort keys %{$self->{province2code}});
}

=head2 $self->{code2province}

This is a hashref which has two-letter province names as the key and the long
name as the value.

=head2 $self->{province2code}

This is a hashref which has the long name as the key and the two-letter
province name as the value.

=head1 SEE ALSO

=head2 Locale::Country

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

=over 4

=item * The province name is returned in C<uc()> format.

=item * neither hash is strict, though they should be.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Locale::CA

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Locale-CA>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Locale-CA>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Locale-CA>

=item * Search CPAN

L<http://search.cpan.org/dist/Locale-CA/>

=back

=head1 ACKNOWLEDGEMENTS

Based on L<Locale::US> - Copyright (c) 2002 - C<< $present >> Terrence Brannon.

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2015 Nigel Horne.

This program is released under the following licence: GPL

=cut

1; # End of Locale::CA
__DATA__
@@ provinces
AB:ALBERTA
BC:BRITISH COLUMBIA
MB:MANITOBA
NB:NEW BRUNSWICK
NL:NEWFOUNDLAND AND LABRADOR
NT:NORTHWEST TERRITORIES
NS:NOVA SCOTIA
ON:ONTARIO
PE:PRINCE EDWARD ISLAND
QC:QUEBEC
SK:SASKATCHEWAN
YT:YUKON
__END__
