use Test::More tests=> 43;
use lib qw( ./lib ../lib );
use Egg::Helper;

can_ok 'Egg::Helper', 'run';

@ARGV= ( 'EggTest', "-mo ". Egg::Helper->helper_temp_dir );
my $result= Egg::Helper->run( project => {
  test_code=> sub {
	my($e, $param, $files)= @_;
	isa_ok $e, 'Egg::Helper::Build::Project';
	my $root= $e->config->{root};
	ok -e $root, qq{-e $root};
	for my $f (@$files) {
		my $path= "$root/". $e->egg_var($param, $f->{filename});
		ok -e $path, qq{-e $path};
	}
	},
  });
ok $result, q{Egg::Helper->run('project', $attr)};
