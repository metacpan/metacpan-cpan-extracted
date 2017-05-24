# Process Command Line Options (i.e. flag -d | -debug):
package Lab::Generic::CLOptions;

our $VERSION = '3.543';

use Getopt::Long qw/:config pass_through/;

our $DEBUG        = 0;
our $IO_INTERFACE = undef;

GetOptions(
    "debug|d"      => \$DEBUG,
    "terminal|t=s" => \$IO_INTERFACE
) or die "error in CLOptions";

1;
