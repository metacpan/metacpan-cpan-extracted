package Locale::US;
BEGIN {
  $Locale::US::VERSION = '3.04';
}

use strict;
use warnings;

use Data::Dumper;

use Data::Section::Simple;

# Preloaded methods go here.

sub new {
    
    my $class = shift;
    my $self = {} ;

    my $data = Data::Section::Simple::get_data_section('states');
    #die "data: $data";

    my @line = split "\n", $data;
    #die "LINE: @line";

    for ( @line ) {

	my ($code, $state) = split ':';
	#warn "	my ($code, $state) = split ':';";

	$self->{code2state}{$code}  = $state;
	$self->{state2code}{$state} = $code;
    }

    #die Dumper $self;
    bless $self, $class;
}

sub all_state_codes {

    my $self = shift;

    sort keys % { $self->{code2state} } ;

}

sub all_state_names {

    my $self = shift;

    sort keys % { $self->{state2code} } ;

}

1;

__DATA__
@@ states
AL:ALABAMA
AK:ALASKA
AS:AMERICAN SAMOA
AZ:ARIZONA
AR:ARKANSAS
CA:CALIFORNIA
CO:COLORADO
CT:CONNECTICUT
DE:DELAWARE
DC:DISTRICT OF COLUMBIA
FM:FEDERATED STATES OF MICRONESIA
FL:FLORIDA
GA:GEORGIA
GU:GUAM
HI:HAWAII
ID:IDAHO
IL:ILLINOIS
IN:INDIANA
IA:IOWA
KS:KANSAS
KY:KENTUCKY
LA:LOUISIANA
ME:MAINE
MH:MARSHALL ISLANDS
MD:MARYLAND
MA:MASSACHUSETTS
MI:MICHIGAN
MN:MINNESOTA
MS:MISSISSIPPI
MO:MISSOURI
MT:MONTANA
NE:NEBRASKA
NV:NEVADA
NH:NEW HAMPSHIRE
NJ:NEW JERSEY
NM:NEW MEXICO
NY:NEW YORK
NC:NORTH CAROLINA
ND:NORTH DAKOTA
MP:NORTHERN MARIANA ISLANDS
OH:OHIO
OK:OKLAHOMA
OR:OREGON
PW:PALAU
PA:PENNSYLVANIA
PR:PUERTO RICO
RI:RHODE ISLAND
SC:SOUTH CAROLINA
SD:SOUTH DAKOTA
TN:TENNESSEE
TX:TEXAS
UT:UTAH
VT:VERMONT
VI:VIRGIN ISLANDS
VA:VIRGINIA
WA:WASHINGTON
WV:WEST VIRGINIA
WI:WISCONSIN
WY:WYOMING
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Locale::US - Two letter codes for state identification in the United States and vice versa.

=head1 SYNOPSIS

  use Locale::US;
 
  my $u = Locale::US->new;

  my $state = $u->{code2state}{$code};
  my $code  = $u->{state2code}{$state};

  my @state = $u->all_state_names;
  my @code  = $u->all_state_codes;


=head1 ABSTRACT

Map from US two-letter codes to states and vice versa.

=head1 DESCRIPTION

=head2 MAPPING

=head3 $self->{code2state}

This is a hashref which has two-letter state names as the key and the long name as the value.

=head3 $self->{state2code}

This is a hashref which has the long nameas the key and the two-letter state name as the value.

=head2 DUMPING

=head3 $self->all_state_names

Returns an array (not arrayref) of all state names in alphabetical form

=head3 $self->all_state_codes

Returns an array (not arrayref) of all state codes in alphabetical form.

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item * The state name is returned in C<uc()> format.

=item * neither hash is strict, though they should be.

=back

=head1 SEE ALSO

=head2 Locale::Country

L<Locale::Country>

=head2 Abbreviations

L<http://www.usps.gov/ncsc/lookups/usps_abbreviations.htm>

    Online file with the USPS two-letter codes for the United States and its possessions.

=head2 AUXILIARY CODE:

    lynx -dump http://www.usps.gov/ncsc/lookups/usps_abbreviations.htm > kruft.txt
    kruft2codes.pl

=head1 AUTHOR

Currently maintained by Mike Accardo, <accardo@cpan.org>

Original author T. M. Brannon

=head2 PATCHES

Thanks to stevet AT ibrinc for a patch about second call to new failing.

=head1 COPYRIGHT

    Copyright (c) 2015 Mike Accardo
    Copyright (c) 2002-2014 Terrence Brannon 

All rights reserved.  This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
