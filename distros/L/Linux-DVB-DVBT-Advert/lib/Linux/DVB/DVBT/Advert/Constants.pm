package Linux::DVB::DVBT::Advert::Constants ;

=head1 NAME

Linux::DVB::DVBT::Advert::Constants - Advert detection constants file

=head1 SYNOPSIS

	use Linux::DVB::DVBT::Advert::Constants ;
  

=head1 DESCRIPTION

Constants used by advert removal module

=cut

use strict ;

our $VERSION = '1.00' ;
our $DEBUG = 0 ;

#============================================================================================

=head2 Constants

=over 4


=back

=cut

our %CONSTANTS = () ;

#-----------------------------------------------------------------------------
sub _no_once_warning
{
	return \%CONSTANTS ;
}

# ============================================================================================
# END OF PACKAGE

1;

