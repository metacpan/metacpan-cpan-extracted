use Test::More tests => 5;
use Deco::Dive;

# meter => no deco time minutes
# these are the values from a published Buhlmann air table
my %TEST = ( 12 => 125,
	18 => 51,
	27 => 20,
	36 => 12,
	42 => 9 );

# and these are our calculations
%TEST = ( 12 => 371,
	18 => 66,
	27 => 34,
	36 => 14,
	42 => 10 );


foreach my $depth (sort keys %TEST ) {
	my $dive = new Deco::Dive ( configdir => './conf' );

	# load buhlman config
	my $model = 'haldane';
	my $file = "./conf/buhlmann.cnf";
	$dive->model( model => $model, config => $file );

	$dive->point(0, $depth); 
	# simulate
	$dive->simulate();

	# and ask the nodeco time, in minutes
	my ($nodeco, $tissue_nr) = $dive->nodeco_time();
	# round nodeco
	$nodeco = sprintf('%.0f', $nodeco);
	
	is( $nodeco, $TEST{$depth}, "no deco time for $depth meter is $nodeco minutes");
}

