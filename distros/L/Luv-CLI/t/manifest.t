use v5.38;
use Test::More;
use File::Temp qw(tempdir);

use Luv::CLI::Manifest;

my $dir  = tempdir( CLEANUP => 1 );
my $path = "$dir/luv.json";

subtest 'defaults' => sub {
    my $m = Luv::CLI::Manifest->new(
        path         => $path,
        project_name => 'testgame'
    );
    is $m->project_name, 'testgame', 'project_name set';
    is $m->output_name, 'testgame.love',
        'output_name defaults from project_name';
    is $m->source_dir,  'src',    'source_dir default';
    is $m->library_dir, 'lib',    'library_dir default';
    is $m->assets_dir,  'assets', 'assets_dir default';
    is $m->build_dir,   'build',  'build_dir default';
};

subtest 'save and load round-trip' => sub {
    my $m = Luv::CLI::Manifest->new(
        path         => $path,
        project_name => 'roundtrip'
    );
    $m->add_dependency(
        'baton',
        url => 'https://example.com/baton',
        ref => 'main'
    );
    $m->save;

    ok -e $path, 'manifest file written';

    my $loaded = Luv::CLI::Manifest->new( path => $path );
    $loaded->load;

    is $loaded->project_name, 'roundtrip', 'project_name round-trips';
    ok $loaded->has_dependency('baton'), 'dependency round-trips';
    is $loaded->dependencies->{baton}{url}, 'https://example.com/baton',
        'dependency url round-trips';
};

subtest 'add/remove dependency' => sub {
    my $m = Luv::CLI::Manifest->new( path => $path, project_name => 'deps' );
    $m->add_dependency( 'foo', url => 'https://example.com/foo' );
    ok $m->has_dependency('foo'), 'foo added';

    eval { $m->add_dependency( 'foo', url => 'https://example.com/foo2' ) };
    like $@, qr/already exists/, 'duplicate add dies';

    $m->remove_dependency('foo');
    ok !$m->has_dependency('foo'), 'foo removed';

    eval { $m->remove_dependency('foo') };
    like $@, qr/No such dependency/, 'removing missing dep dies';
};

done_testing;
