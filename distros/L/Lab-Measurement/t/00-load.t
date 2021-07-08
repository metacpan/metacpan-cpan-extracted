#!perl

# Check that our perl modules compile without error.

use 5.010;
use strict;
use warnings;
use File::Find;
use Module::Load;
use Test::More;
use File::Spec::Functions 'abs2rel';

# Create file list

my @files;

sub installed {
    my $module = shift;
    eval {
        autoload $module;
        1;
    } or return;

    return 1;
}

File::Find::find(
    {
        wanted => sub { -f $_ && /\.pm$/ and push @files, $_ },
        no_chdir => 1
    },
    'lib'
);

@files = map { abs2rel( $_, 'lib' ) } @files;

# Do not keep backslashes in filenames, as they confuse require:
# perl uses slashes in %INC for modules which are 'used'.
# With backslashes the same module could be loaded twice.

@files = map {s(\\)(/)gr} @files;

# Skip modules with special dependencies.

sub skip_modules {
    my @to_be_skipped = @_;
    for my $skip (@to_be_skipped) {
        @files = grep {
            my $file = $_;
            index( $file, $skip ) == -1;
        } @files;
    }
}

diag("checking installed modules");

my $rs232_stuff = [
    qw{
        Lab/Bus/RS232.pm Lab/Bus/MODBUS_RS232.pm
        Lab/Instrument/TemperatureControl/TLK43.pm
        Lab/Bus/RS232.pm
        Lab/Bus/MODBUS_RS232.pm
        }
];

my %depencencies = (

    #    'PDL' => ['Lab/Data/PDL.pm'],
    'PDL::Graphics::Gnuplot' => [
        qw{
            Lab/Moose/Plot.pm
            Lab/Moose/DataFile/Gnuplot.pm
            Lab/Moose/Instrument/DisplayXY.pm
            Lab/Moose/Instrument/SpectrumAnalyzer.pm
            Lab/Moose/Instrument/HP8596E.pm
            Lab/Moose/Instrument/Rigol_DSA815.pm
            Lab/Moose/Instrument/HPE4400B.pm
            }
    ],

    'Statistics::LineFit' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],

    'Device::SerialPort' => $rs232_stuff,
    'threads'            => $rs232_stuff,
    'Thread::Semaphore'  => $rs232_stuff,

    'Math::Interpolate' => ['Lab/XPRESS/Data/XPRESS_dataset.pm'],

    'Math::Round' => ['Lab/Moose/Instrument/Rigol_DG5000.pm'],

    'IPC::Run' => [
        qw{
            Lab/XPRESS/Xpression/PlotterGUI_bidirectional.pm
            Lab/XPRESS/Xpression/bidirectional_gnuplot_pipe.pm
            }
    ],

    'LinuxGpib' => ['LinuxGPIB'],

    'Lab::VISA' => [
        qw{VISA Lab/Bus/IsoBus.pm Lab/Connection/IsoBus.pm
            Lab/Moose/Connection/VISA}
    ],

    'Lab::Zhinst' => ['Zhinst'],

    'Lab::VXI11' => ['Moose/Connection/VXI11.pm'],

    'USB::TMC' => ['Moose/Connection/USB.pm'],
);

for my $module ( keys %depencencies ) {
    if ( installed($module) ) {
        diag("using $module");
    }
    else {
        diag("not using $module");
        skip_modules( @{ $depencencies{$module} } );
    }
}

eval {
    load 'sys/ioctl.ph';
    diag("using sys/ioctl.ph");
    load 'linux/usb/tmc.ph';
    diag("using linux/usb/tmc.ph");
    1;

} or do {
    diag("not using sys/ioctl.ph");
    diag("not using linux/usb/tmc.ph");
    skip_modules('Lab/Bus/USBtmc.pm');
};

plan tests => scalar @files;

for my $file (@files) {
    diag("trying to load $file ...");
    is( require $file, 1, "load $file" );
}

