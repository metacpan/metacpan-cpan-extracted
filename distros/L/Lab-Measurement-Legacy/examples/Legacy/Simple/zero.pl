#-------- 0. Import Lab::Measurement -------

use Lab::Measurement;

my $gate_target    = 0;
my $voltage_target = 0;

#-------- 1. Initialize Instruments --------

my $gate_source = Instrument(
    'YokogawaGS200',
    {
        connection_type         => 'LinuxGPIB',
        gpib_address            => 1,
        gate_protect            => 1,
        gp_max_units            => 8,
        gp_min_units            => -8,
        gp_max_units_per_second => 0.001
    }
);

my $voltage_source = Instrument(
    'YokogawaGS200',
    {
        connection_type         => 'LinuxGPIB',
        gpib_address            => 2,
        gate_protect            => 1,
        gp_max_units            => 8,
        gp_min_units            => -8,
        gp_max_units_per_second => 0.001
    }
);

$gate_source->sweep_to_level( { target => $gate_target } );
$voltage_source->sweep_to_level( { target => $voltage_target } );

