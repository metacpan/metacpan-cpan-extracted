package Locale::India;

BEGIN {
  $Locale::India::VERSION = '0.001';
}


use strict;
use warnings;

use Data::Dumper;

use Data::Section::Simple;

# Constructor

sub new {

	my $class = shift;
	my $self = {} ;

	my $data = Data::Section::Simple::get_data_section('states');

	my @line = split "\n", $data;

	foreach ( @line ) {

		my ($code, $name, $type) = split ':';

		if ($type =~ /state/i) {
			$self->{code2state}{uc $code}  = uc $name;
			$self->{state2code}{uc $name} = uc $code;
		} else {
			$self->{code2ut}{uc $code}  = uc $name;
			$self->{ut2code}{uc $name} = uc $code;
		}
	}

	bless $self, $class;
}

sub get_all_state_codes {

	my $self = shift;

	sort keys % { $self->{code2state} } ;

}

sub get_all_state_names {

	my $self = shift;

	sort keys % { $self->{state2code} } ;

}

sub get_all_ut_codes {

	my $self = shift;

	sort keys % { $self->{code2ut} };

}

sub get_all_ut_names {

	my $self = shift;

	sort keys % { $self->{ut2code} };

}

1;

__DATA__
@@ states
IN-AP:Andhra Pradesh:State
IN-AR:Arunachal Pradesh:State
IN-AS:Assam:State
IN-BR:Bihar:State
IN-CT:Chhattisgarh:State
IN-GA:Goa:State
IN-GJ:Gujarat:State
IN-HR:Haryana:State
IN-HP:Himachal Pradesh:State
IN-JK:Jammu and Kashmir:State
IN-JH:Jharkhand:State
IN-KA:Karnataka:State
IN-KL:Kerala:State
IN-MP:Madhya Pradesh:State
IN-MH:Maharashtra:State
IN-MN:Manipur:State
IN-ML:Meghalaya:State
IN-MZ:Mizoram:State
IN-NL:Nagaland:State
IN-OR:Odisha:State
IN-PB:Punjab:State
IN-RJ:Rajasthan:State
IN-SK:Sikkim:State
IN-TN:Tamil Nadu:State
IN-TG:Telangana:State
IN-TR:Tripura:State
IN-UT:Uttarakhand:State
IN-UP:Uttar Pradesh:State
IN-WB:West Bengal:State
IN-AN:Andaman and Nicobar Islands:Union territory
IN-CH:Chandigarh:Union territory
IN-DN:Dadra and Nagar Haveli:Union territory
IN-DD:Daman and Diu:Union territory
IN-DL:Delhi:Union territory
IN-LD:Lakshadweep:Union territory
IN-PY:Puducherry:Union territory
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Locale::India - ISO 3166-2 defines codes for identifying the principal subdivisions (e.g., provinces or states) of all countries coded in ISO 3166-1. This module is used for state and union territory identification in the India and vice versa.

=head1 SYNOPSIS

  use Locale::India;
 
  my $u = Locale::India->new;

  my $state = $u->{code2state}{$code};
  my $code  = $u->{state2code}{$state};
  my $ut = $u->{code2ut}{$code};
  my $ut_code = $u->{ut2code}{$ut};

  my @state = $u->get_all_state_names;
  my @code  = $u->get_all_state_codes;
  my @ut = $u->get_all_ut_names;
  my $ut_code = $u->get_all_ut_codes;


=head1 ABSTRACT

Map for India state and union territory codes to names and vice versa.

=head1 DESCRIPTION

=head2 MAPPING

=head3 $self->{code2state}

This is a hashref which has state code names as the key and the long state name as the value.

=head3 $self->{state2code}

This is a hashref which has the long state names the key and the state code name as the value.

=head3 $self->{code2ut}

This is a hashref which has union territory code names as the key and the long union territory name as the value.

=head3 $self->{ut2code}

This is a hashref which has the long union territory names the key and the union territory code name as the value.

=head2 DUMPING

=head3 $self->get_all_state_names

Returns an array (not arrayref) of all state names in alphabetical form

=head3 $self->get_all_state_codes

Returns an array (not arrayref) of all state codes in alphabetical form.

=head3 $self->get_all_ut_names

Returns an array (not arrayref) of all union territory names in alphabetical form

=head3 $self->get_all_ut_codes

Returns an array (not arrayref) of all union territory codes in alphabetical form.

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item * The state and union territory names is returned in C<uc()> format.

=item * neither hash is strict, though they should be.

=back

=head1 SEE ALSO

=head2 Locale::Country

L<Locale::Country>

=head2 Abbreviations

L<http://www.iso.org/iso/home/standards/country_codes/updates_on_iso_3166.htm?show=tab3>

    Online file with the state and union territory codes for the India and its possessions.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Manoj Shekhawat.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

License: GPL, Artistic, available in the Debian Linux Distribution at
/usr/share/common-licenses/{GPL,Artistic}

=head1 AUTHOR

Manoj Shekhawat, <mshekhawa@cpan.org>

=cut
