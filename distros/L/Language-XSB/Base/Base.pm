package Language::XSB::Base;

our $VERSION;
BEGIN {
    $VERSION = '0.11';
}

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( xsb_init
		  setreg
		  setreg_int
		  getreg
		  getreg_int
		  regtype
		  go );

use Language::XSB::Config;

use Inline C => Config => MYEXTLIB => $XsbConfig{XSB_O},
                INC => "-I$XsbConfig{CONFDIR} -I$XsbConfig{EMUDIR}";
                # CCFLAGS => "-g -O0";

# my $pkg;
# BEGIN { $pkg=__PACKAGE__ }

use Inline C => qq
{

 #include "Base.h"

 int my_xsb_init(char *xsbloader) {
     char *xsb_argv[3]={ "$XsbConfig{CONFDIR}/bin/xsb",
			 xsbloader,
			 NULL, };
     int xsb_argc=2;
     converter=GvSV(gv_fetchpv(PKG "::converter", GV_ADDMULTI, SVt_PV));
     xsb(0, xsb_argc, xsb_argv);
     xsb(1,0,0);
 }

 SV *my_getreg(int index) {
     if (index < 0 || index >= 255 )
	 die ("invalid index \%d for xsb_reg_term", index);
     return term2sv(reg_term(index+1));
 }

 SV *my_getreg_int(int index) {
     if (index < 0 || index >= 255 )
	 die ("invalid index \%d for xsb_reg_term", index);
     return getreg_int(index+1);
 }

 int my_regtype(int index) {
     if (index < 0 || index >= 255 )
	 die ("invalid index \%d for xsb_reg_term", index);
     return regtype(index+1);
 }

 SV *my_setreg(int index, SV *term) {
     return setreg(index+1, term);
 }

 void my_setreg_int(int index, int value) {
     if (index < 0 || index >= 255 )
	 die ("invalid index \%d for xsb_reg_term", index);
     setreg_int(index+1, value);
 }

 int my_go() {
     xsb(1,0,0);
 }

}, NAME => __PACKAGE__, VERSION => $VERSION, PREFIX => 'my_', OPTIMIZE => '-g';


# conversions between Perl and Prolog implemented in Converter module
use Language::Prolog::Types::Converter;
our $converter='Language::Prolog::Types::Converter';

1;
__END__

=head1 NAME

Language::XSB::Base - XSB SLG-WAN access

=head1 SYNOPSIS

  # use Language::XSB::Base;
  # better... :-)
  use Language::XSB;


=head1 ABSTRACT

This module provides direct access to the XSB SLG-WAM.

=head1 DESCRIPTION

This module lets get and set the XSB SLG-WAM registers converting data
between Prolog and Perl formats.

It also has methods to initialize XSB and to make it run.

It should be noted that registers in XSB are indexed from 1, but in
Perl they are indexed from 0!

=head2 EXPORT

=over 4

=item C<xsb_init()>

=item C<setreg($index, $term)>

=item C<setreg_int($index, $integer)>

=item C<getreg($index)>

=item C<getreg_int($index)>

=item C<regtype($index)>

=item C<go()>


=head1 SEE ALSO



=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
