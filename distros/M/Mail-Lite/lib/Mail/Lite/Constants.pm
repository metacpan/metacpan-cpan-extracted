#
#===============================================================================
#
#         FILE:  Constants.pm
#
#  DESCRIPTION:  Mail::Lite::Constants -- constants for Mail::Lite.
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Pavel Boldin (), <davinchi@cpan.org>
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  14.09.2008 20:31:33 MSD
#     REVISION:  ---
#===============================================================================

package Mail::Lite::Constants;

use strict;
use warnings;

use Exporter qw/import/;

our @EXPORT = qw/OK STOP ERROR NEXT_RULE STOP_RULE/;

sub OK { 1 };
sub ERROR { ! OK };
sub STOP { "STOP\n" };
sub NEXT_RULE { "NEXT_RULE\n" };
sub STOP_RULE { "STOP_RULE\n" };


1;
