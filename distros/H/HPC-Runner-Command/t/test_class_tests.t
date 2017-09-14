use File::Spec::Functions qw( catdir  );
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin, 'lib' );
use Test::Class::Moose::Runner;
##Tests fail on travis without this
use IO::Interactive;

##Run the main applications tests
if ( $ENV{'TRAVIS'} || $ENV{'DEV'} ) {
    Test::Class::Moose::Runner->new(
        test_classes => [
            'TestsFor::HPC::Runner::Command::Test001',
            'TestsFor::HPC::Runner::Command::Test002',
            'TestsFor::HPC::Runner::Command::Test003',
            'TestsFor::HPC::Runner::Command::Test005',
            'TestsFor::HPC::Runner::Command::Test006',
            'TestsFor::HPC::Runner::Command::Test007',
            'TestsFor::HPC::Runner::Command::Test008',
            'TestsFor::HPC::Runner::Command::Test009',
            'TestsFor::HPC::Runner::Command::Test010',
            'TestsFor::HPC::Runner::Command::Test011',
            'TestsFor::HPC::Runner::Command::Test012',
            'TestsFor::HPC::Runner::Command::Test013',
            'TestsFor::HPC::Runner::Command::Test014',
            'TestsFor::HPC::Runner::Command::Test015',
            'TestsFor::HPC::Runner::Command::Test016',
            'TestsFor::HPC::Runner::Command::Test017',
        ],
    )->runtests;
}
elsif ( $ENV{'SCHEDULER'} eq 'SLURM' ) {
    Test::Class::Moose::Runner->new(
        test_classes => [
            'TestsFor::HPC::Runner::Command::Test001',
            'TestsFor::HPC::Runner::Command::Test002',
            'TestsFor::HPC::Runner::Command::Test003',
            'TestsFor::HPC::Runner::Command::Test004',
        ],
    )->runtests;
}
else{
    Test::Class::Moose::Runner->new(
        test_classes => [
            'TestsFor::HPC::Runner::Command::Test001',
        ],
    )->runtests;
}
