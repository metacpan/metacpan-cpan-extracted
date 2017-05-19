use File::Spec::Functions qw( catdir  );
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin, 'lib' );
use Test::Class::Moose::Runner;

##Run the main applications tests

if ( !$ENV{'SCHEDULER'} ) {
    Test::Class::Moose::Runner->new(
        test_classes => [
	    'TestsFor::HPC::Runner::Command::Test001',
	    'TestsFor::HPC::Runner::Command::Test002',
	    # 'TestsFor::HPC::Runner::Command::Test007',
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
elsif ($ENV{'DEV'} eq 'DEV'){
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
        ],
    )->runtests;
}
