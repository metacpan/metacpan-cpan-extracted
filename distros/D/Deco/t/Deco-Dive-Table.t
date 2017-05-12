use Test::More tests => 7;
use Test::Exception;

my $Class = 'Deco::Dive::Table';

use_ok($Class);
use Deco::Dive;

throws_ok { my $diveplot = new $Class; } qr/Please provide a Deco::Dive/ , "can't create table without a dive object";

my $dive = new Deco::Dive();
$dive->model( config => './conf/haldane.cnf');

my $divetable = $Class->new( $dive );

isa_ok( $divetable, $Class, "Creating dive-table");

# perform calculation
$divetable->_calculate_nostop( );

my $table_nostop = $divetable->no_stop();
like ($table_nostop, qr/No Decomp/, "no stop table returned");

# now do one with a template
my $template= "row #DEPTH# -> #time#\n";
$table_nostop = $divetable->no_stop(template => $template);

like ($table_nostop, qr/^row \d+/, "and now one with template");

# let's do a full table
# first some exceptions
throws_ok { $divetable->controlling_tissue( 99 ) } qr/The tissue number 99/ , "Non existing tissue";

$divetable->controlling_tissue( 6 );
$divetable->calculate();
my $table = $divetable->output();
like ($table, qr/^Group: \d+/, "complete table");
