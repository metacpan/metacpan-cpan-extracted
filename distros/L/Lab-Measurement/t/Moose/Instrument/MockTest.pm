package Moose::Instrument::MockTest;
use 5.010;
use warnings;
use strict;

use Exporter 'import';

use Getopt::Long qw/:config gnu_compat/;
use YAML::XS;
use Carp;
use Module::Load;
use MooseX::Params::Validate;
use Lab::Moose;
use Data::Dumper;

our @EXPORT_OK = qw/mock_instrument/;

my $connection_module;
my $connection_options = '{}';
my $help;

use Lab::Moose::Connection::Mock;

GetOptions(
    'connection|c=s'         => \$connection_module,
    'connection-options|o=s' => \$connection_options,
    'help|h',                => \$help,
);

if ($help) {
    state_help();
    exit 0;
}

sub state_help {
    say <<'EOF';
Run the test. By default, it will run with a mock instrument.

 Options:
 -c, --connection=CONNECTION
                           Use CONNECTION. Defaults to Mock. E.g. for
                           refreshing a log file, you can use LinuxGPIB.
 -o, --connection-options=OPTIONS
                           YAML hash of connection options. Example: use
                           LinuxGPIB with pad=20:
                           -o '{pad: 20}'
 -h, --help                Print this help screen.
EOF
}

sub mock_instrument {
    my ( $type, $logfile ) = validated_list(
        \@_,
        type     => { isa => 'Str' },
        log_file => { isa => 'Str' }
    );

    if ( not defined $connection_module ) {
        return instrument(
            type               => $type,
            connection_type    => 'Mock',
            connection_options => { log_file => $logfile },
        );
    }

    my $hash = Load($connection_options);
    if ( ref $hash ne 'HASH' ) {
        croak "argument of --connection-options not a hash";
    }

    return instrument(
        type               => $type,
        connection_type    => $connection_module,
        connection_options => $hash,
        instrument_options => { log_file => $logfile }
    );
}

1;
