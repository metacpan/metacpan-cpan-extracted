use Data::Dumper;
use Devel::TRay 'hide_core=1:hide_cpan=1:hide_eval=1';

my $modules = [ 
	'Foo', 
	'Foo::Bar', 
	'Data::Dumper', 
	'Yandex::Geo::Company', 
	'Session', 
	'Xportal', 
	'Sub::Defer', 
	'Method::Generate::Constructor',
	'MetaCPAN::Client::Request',
	'MetaCPAN::Client::Role::HasUA'
	'main'
];
my %h = map { $_, DB::_is_cpan_published($_, 2) } @$modules;
warn Dumper \%h;


sub test_for {
	my $pkg = shift;
	use MetaCPAN::Client;
	my $mcpan = MetaCPAN::Client->new( version => 'v1' );
	warn Dumper $mcpan->module($pkg)->distribution;
	warn Dumper $mcpan->distribution($pkg);
}

# test_for('main');
# test_for('Session');
test_for('Sub::Defer');
