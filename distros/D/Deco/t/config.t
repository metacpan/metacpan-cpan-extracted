use Test::More tests => 5;
use Config::General;

my $config_file = './conf/haldane.cnf';
my $conf = new Config::General( -ConfigFile => $config_file,  -LowerCaseNames => 1);
isa_ok( $conf, 'Config::General', 'Config loaded ok');

my %config = $conf->getall; 

is( $config{model}, 'Haldane', 'Model variable loaded OK');

is( $config{tissue}{4}{halftime}, 40 , 'Halftime is correct');
is( $config{tissue}{4}{deltam}, '0.140' , 'DeltaM is correct');
is( $config{tissue}{4}{m0}, '1.70' , 'M0 is correct');



