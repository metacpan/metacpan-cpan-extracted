package MockTest;

use 5.010;
use warnings;
use strict;

use Getopt::Long qw/:config no_ignore_case bundling/;
use Exporter 'import';
use Lab::Test;

our @EXPORT = qw/get_connection_type get_gpib_address get_logfile/;

my $connection = 'Mock';
my $gpib_address;
my $logfile;
my $help;

GetOptions(
    'connection|c=s'   => \$connection,
    'gpib-address|g=i' => \$gpib_address,
    'file|f=s'         => \$logfile,
    'help|h'           => \$help,
) or die "Error in GetOptions";

if ($help) {
    state_help();
    exit 1;
}

sub state_help {
    say "
Run the test. By default, it will run with a mock instrument.

 Options:
 -c, --connection=CONNECTION
                           Use CONNECTION. Defaults to Mock. E.g. for
                           refreshing a log file, you can use LinuxGPIB::LOG.
 -g, --gpib-address=ADDR   Use GPIB Address ADDR. Only relevant, if you provide
                           a GPIB connection like LinuxGPIB with the
                           --connection option.
                          
 -f, --file=LOGFILE        Use LOGFILE for mock/log, instead of the
                           default logfile provided by the test.
";
}

sub get_connection_type {
    return $connection;
}

sub get_logfile {
    my $file = shift;
    if ( not $file ) {
        die "no logfile argument given to get_logfile";
    }
    if ($logfile) {
        return $logfile;
    }
    return $file;
}

sub get_gpib_address {
    my $default = shift;
    if ( not $default ) {
        die "no address argument given to get_gpib_address";
    }
    if ( defined $gpib_address ) {
        return $gpib_address;
    }
    return $default;
}

# sub float_equal {
#     my $a = shift;
#     my $b = shift;

#     # 1e-14 is about 100 times bigger than the machine epsilon.
#     return ( relative_error( $a, $b ) < 1e-14 );
# }

1;
