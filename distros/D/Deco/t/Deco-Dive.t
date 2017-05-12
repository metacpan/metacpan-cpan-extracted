use Test::More tests => 23;
use Test::Exception;

my $Class = 'Deco::Dive';

use_ok($Class);

my $dive = new $Class ( configdir => './conf' );
isa_ok( $dive, $Class, "Creating dive");

# croak on missing parameters
throws_ok { $dive->model( ) } qr/specify the config file or model/ , "Missing parameters";

# croak on non existing config file
throws_ok { $dive->model( model => 'Foobar2' ) } qr/The file .+ does not exist/ , "Model without config file";

# set a right model
my $model = 'haldane';
$file = "./conf/$model.cnf";
ok( $dive->model( model => $model, config => $file ), "can set a $model model");

my $nr = 2;
my $tissue = $dive->tissue( $nr );
isa_ok( $tissue, 'Deco::Tissue', "Tissue $nr is a Deco::Tissue");
is ($tissue->nr(), $nr , "   and numbers match");
is( $dive->{model}, 'haldane', "Model haldane is correct");
is( $dive->{model_name}, 'Original Haldane', "Model name is correct");

# asking for wrong tissue
throws_ok { $dive->tissue( 101 )} qr/Tissue nr 101 is unknown/ , "Asking for unknown tissue";
throws_ok { $dive->tissue() } qr/Please specify a/ , " and forgetting tissue nr";

# croak on missing data
throws_ok { $dive->simulate( model => 'FooBar' ) } qr/Invalid model/ , "Wrong model";
throws_ok { $dive->simulate( model => $model ) } qr/No dive profile data/ , "Croaks on missing data";

# load some data
my $file = "./t/data/dive.txt";
$dive->load_data_from_file( file => $file);

# peek inside the data
my @times  = @{ $dive->{timepoints} };
my @depths = @{ $dive->{depths} };
is( $times[0], 0,  "Starting time is 0 seconds");
is( $depths[0], 0,  "Starting depth is 0 meter");

is( $times[4], 120,  "4th point is 120 seconds");
is( $depths[4], 3.9,  "and 3.9 meter");

# set some gases
$dive->gas( 'O2' => 40, 'n2' => 0.6);
is ($dive->{tissues}->[1]->{o2}->{fraction}, 0.4 , "02 fraction set allright");
throws_ok { $dive->gas( 'Xe' => 12)  } qr/Can't use gas xe/ , "trying to set unsupported gas";
# 
# simulate
$dive->simulate();

my $dive2 = new Deco::Dive;
$dive2->point(10, 5.5);  # 10 seconds 5.5 meter
$dive2->point(40, 7.5);  # 40 seconds 7.5 meter

@times  = @{ $dive2->{timepoints} };
@depths = @{ $dive2->{depths} };
is( $times[0], 10,  "Starting time is 10 seconds");
is( $depths[0], 5.5,  "Starting depth is 5.5 meter");
is( $times[1], 40,  "then at 40 seconds");
is( $depths[1], 7.5,  "... we go to 7.5 meter");


