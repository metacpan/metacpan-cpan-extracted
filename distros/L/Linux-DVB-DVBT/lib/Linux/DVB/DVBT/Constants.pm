package Linux::DVB::DVBT::Constants ;

=head1 NAME

Linux::DVB::DVBT::Constants - DVBT constant settings 

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Constants ;
  

=head1 DESCRIPTION

This module contains a single global HASH which contains useful constants used both by the XS module (and all the C code) and by the Perl.

The HASH is populated by the XS startup.

=cut


use strict ;

our $VERSION = '1.00' ;
our $DEBUG = 0 ;

#============================================================================================

=head2 GLOBALS

=over 4


=cut

our %CONSTANTS = () ;

# ============================================================================================
# END OF PACKAGE

=back

=cut

1;

