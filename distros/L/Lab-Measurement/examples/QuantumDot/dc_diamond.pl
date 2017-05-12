#-------- 1. Import Lab::Measurement -------

use warnings;
use strict;
use 5.010;

use Lab::Measurement;

#-------- 2. Some constants ----------------

my $gain          = -1e-9;    # A/V amplifier sensit.
my $stepwidthbias = 0.05;     #step width bias
my $stepwidthgate = 0.1;      #step width gate
my $NPLC          = 2;        # integration time, 2*20ms

#-------- 3. Initialize Instruments --------

my $gate_source = Instrument(
    'YokogawaGS200',
    {
        connection_type => 'VISA_GPIB',
        gpib_address    => 2,
        gate_protect    => 0
    }
);

my $bias_source = Instrument(
    'YokogawaGS200',
    {
        connection_type => 'VISA_GPIB',
        gpib_address    => 6,
        gate_protect    => 0
    }
);

my $DMM_I = Instrument(
    'HP34401A',
    {
        connection_type => 'VISA_GPIB',
        gpib_address    => 14,
        nplc            => $NPLC
    }
);

#-------- 4. Define the Sweeps -------------

my $bias_sweep = Sweep(
    'Voltage',
    {
        mode       => 'step',             # step, list, sweep/continuous
        instrument => $bias_source,
        points     => [ -1, 1 ],          # starting point, end point
        stepwidth  => [$stepwidthbias],
        rate       => [ 1, 0.005 ],       # rate to approach start, sweep rate
                                          #  for measurement (unused), V/s
        jump       => 1,                  # jump to next point, no sweep
        delay_before_loop => 3            # settle 3s before starting
    }
);

my $gate_sweep = Sweep(
    'Voltage',
    {
        mode       => 'step',             # step, list, sweep/continuous
        instrument => $gate_source,
        points     => [ -0.5, 0.5 ],      # starting point, end point
        stepwidth  => [$stepwidthgate],
        rate       => [ 0.03, 0.03 ],     # rate to approach start, sweep rate
                                          #  for measurement (unused), V/s
        jump       => 1                   # jump to next point, no sweep
    }
);

#-------- 5. Create a DataFile -------------

my $DataFile = DataFile('DCDiamond');

$DataFile->add_column('Gate');
$DataFile->add_column('Bias');
$DataFile->add_column('Current');

$DataFile->add_plot(
    {
        'type'    => 'pm3d',
        'x-axis'  => 'Gate',
        'y-axis'  => 'Bias',
        'cb-axis' => 'Current',
        'refresh' => 'block'
    }
);

#-------- 6. Measurement Instructions -------

my $my_measurement = sub {

    # this is run for each measurement point

    my $sweep = shift;

    my $value1 = $gate_source->get_value( { read_mode => 'cache' } );
    my $value2 = $bias_source->get_value( { read_mode => 'cache' } );

    # 'cache' means use the value last written by Perl to the device,
    # but do not query the instrument

    my $value3 = $DMM_I->get_value() * $gain;

    $sweep->LOG(
        {
            Gate    => $value1,
            Bias    => $value2,
            Current => $value3,
        }
    );
};

#-------- 7. Put everything together -------

$DataFile->add_measurement($my_measurement);

$bias_sweep->add_DataFile($DataFile);

my $frame = Frame();
$frame->add_master($gate_sweep);
$frame->add_slave($bias_sweep);

#-------- 8. And GO! -----------------------

$frame->start();

