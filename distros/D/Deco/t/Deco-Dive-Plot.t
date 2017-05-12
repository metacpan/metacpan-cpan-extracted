use Test::More tests => 7;
use Test::Exception;

my $Class = 'Deco::Dive::Plot';

use_ok($Class);
use Deco::Dive;

throws_ok { my $diveplot = new $Class; } qr/Please provide a Deco::Dive/ , "can't create plotter without a dive";


my $dive = new Deco::Dive(configdir => './conf');
# first load some data
$dive->load_data_from_file( file => './t/data/dive.txt');

# and simulate haldane model
$dive->simulate( model => 'haldane');

my $diveplot = $Class->new( $dive );

isa_ok( $diveplot, $Class, "Creating dive-plot");

my $file = 'testplot.png';
if (-e $file) {
   unlink($file);
}

$diveplot->depth( file => $file);
ok( -e $file, "Depth profile created ok");

# do the pressure graph
$file = 'pressures.png';
if (-e $file) {
   unlink($file);
}
$diveplot->pressures( file => $file);
ok( -e $file, "Pressures graph created ok");

# do the no_deco graph
$file = 'no_deco_time.png';
if (-e $file) {
   unlink($file);
}
$diveplot->nodeco( file => $file);
ok( -e $file, "No deco graph created ok");

# do the percentage graph
$file = 'percentages.png';
if (-e $file) {
   unlink($file);
}
$diveplot->percentage( file => $file, width => 650, height => 500);
ok( -e $file, "Percentages graph created ok");
