use Module::Build;
use File::Find;

my @test_files;

find( sub { return unless /\.t\z/; push @test_files, $File::Find::name }, 't' );

my $build = Module::Build->new(
	module_name       => 'Games::PMM',
	license           => 'perl',
	dist_abstract     => 'Paper Maché Monsters',
	build_requires    => {
		Test::Simple  => '0.47',
	},
	dist_version_from => 'lib/Games/PMM.pm',
	test_files        => join( ' ', @test_files ),
);

$build->create_build_script;
