# Process Command Line Options (i.e. flag -d | -debug):
package Lab::Generic::CLOptions;
$Lab::Generic::CLOptions::VERSION = '3.552';

use Getopt::Long qw/:config pass_through/;

our $DEBUG        = 0;
our $IO_INTERFACE = undef;

GetOptions(
    "debug|d"      => \$DEBUG,
    "terminal|t=s" => \$IO_INTERFACE
) or die "error in CLOptions";

1;
