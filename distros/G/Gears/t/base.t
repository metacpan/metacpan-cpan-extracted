use Test2::V1 -ipP;
use Gears qw(load_component get_component_name);

################################################################################
# This tests whether basic function of the Gears module work
################################################################################

subtest 'should load packages' => sub {
	is load_component('Gears::Logger'), 'Gears::Logger', 'component returned';
	ok lives { Gears::Logger->new }, 'package loaded';
};

subtest 'should build component names' => sub {
	is get_component_name('Logger', 'Gears'), 'Gears::Logger', 'name with base ok';
	is get_component_name('^Other::Logger', 'Gears'), 'Other::Logger', 'name without base ok';
};

done_testing;

