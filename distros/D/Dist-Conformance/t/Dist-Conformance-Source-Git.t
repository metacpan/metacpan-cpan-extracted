#!/usr/bin/env perl
use 5.040;
use warnings FATAL => 'all';
use re '/aasx';
use Test2::V0;
use Test2::Plugin::NoWarnings;
use FindBin::libs;
use File::Temp();
use Mojo::File();
use Test::MockModule();

use Dist::Conformance::Source::Git();

my $CLASS = 'Dist::Conformance::Source::Git';

sub cache () { return File::Temp::tempdir( CLEANUP => 1 ) }

# Records the calls to git, and makes a clone look like a clone.
sub fake_git ($calls) {
    my $mock = Test::MockModule->new( $CLASS, no_auto => 1 );
    $mock->redefine(
        git => sub (@arguments) {
            push @$calls, [@arguments];
            Mojo::File->new( $arguments[-1] )->child('.git')->make_path if $arguments[0] eq 'clone';
            return q{};
        }
    );
    return $mock;
}

subtest new => sub {
    like( dies { $CLASS->new }, qr/url\ is\ required/, 'url is required' );
    like( dies { $CLASS->new( url => q{} ) },                           qr/url\ is\ required/, 'and must not be empty' );
    like( dies { $CLASS->new( url => '--upload-pack=x' ) },             qr/starts\ with\ -/,   'a url that git would read as an option is refused' );
    like( dies { $CLASS->new( url => '/bogus/repo', ref => '--all' ) }, qr/starts\ with\ -/,   'and so is such a ref' );
    is( $CLASS->new( url => '/bogus/repo' )->ref, 'HEAD', 'the ref defaults to the default branch' );
};

subtest cache => sub {
    local $ENV{XDG_CACHE_HOME} = '/bogus/xdg';
    is( $CLASS->new( url => '/bogus/repo' )->cache, '/bogus/xdg/dist-conformance', 'under XDG_CACHE_HOME' );
    local $ENV{XDG_CACHE_HOME} = q{};
    local $ENV{HOME}           = '/bogus/home';
    is( $CLASS->new( url => '/bogus/repo' )->cache,                      '/bogus/home/.cache/dist-conformance', 'under ~/.cache without it' );
    is( $CLASS->new( url => '/bogus/repo', cache => '/bogus/c' )->cache, '/bogus/c',                            'or where it is told' );
};

subtest clone_dir => sub {
    my %dir = map { $_ => $CLASS->new( url => '/bogus/repo', ref => $_, cache => '/bogus/c' )->clone_dir->to_string } qw{main v1};
    like( $dir{main}, qr{\A/bogus/c/[[:xdigit:]]{40}\z}, 'a directory of the cache, named by a SHA-1' );
    isnt( $dir{main}, $dir{v1}, 'two refs of one repository have two clones' );
    is( $CLASS->new( url => '/bogus/repo', ref => 'main', cache => '/bogus/c' )->clone_dir->to_string, $dir{main}, 'and one ref always has the same one' );
};

subtest fetch => sub {
    my @calls;
    my $mock   = fake_git( \@calls );
    my $source = $CLASS->new( url => '/bogus/repo', ref => 'main', cache => cache() );
    ok( $mock->is_mocked('git'), 'git is replaced' );
    my $dir = $source->clone_dir->to_string;
    $source->fetch;
    is(
        \@calls,
        [
            [ qw{clone --quiet --no-checkout -- /bogus/repo}, $dir ],
            [ '-C', $dir, qw{fetch --quiet origin main} ],
            [ '-C', $dir, qw{checkout --quiet --force --detach FETCH_HEAD} ],
        ],
        'the first fetch clones, then fetches the ref and checks it out',
    );
    @calls = ();
    $source->fetch;
    is( [ map { $_->[2] } @calls ], [qw{fetch checkout}], 'a later fetch reuses the clone' );
};

subtest root => sub {
    my @calls;
    my $mock   = fake_git( \@calls );
    my $source = $CLASS->new( url => '/bogus/repo', cache => cache() );
    ok( $mock->is_mocked('git'), 'git is replaced' );
    is( $source->root->to_string, $source->clone_dir->to_string, 'the root is the clone' );
    $source->root;
    is( scalar @calls, 3, 'and one object fetches once' );

    @calls = ();
    my $offline = $CLASS->new( url => '/bogus/repo', cache => $source->cache, offline => 1 );
    is( $offline->root->to_string, $source->clone_dir->to_string, 'offline uses the clone that is there' );
    is( \@calls,                   [],                            'without calling git' );
    my $offline_error = qr/Offline,\ and\ there\ is\ no\ cached\ copy/;
    like( dies { $CLASS->new( url => '/bogus/other', cache => cache(), offline => 1 )->root }, qr/$offline_error\ of\ \/bogus\/other\ at\ HEAD/, 'offline without a clone is an error' );
};

subtest describe => sub {
    is( $CLASS->new( url => '/bogus/repo', ref => 'v1', path => 'skills/x' )->describe, '/bogus/repo at v1 (path skills/x)', 'the url, the ref and the path' );
};

subtest git => sub {
    my $command = qr/git\ clone\ --\ \/bogus\/none\ \/bogus\/never/;
    like( dies { Dist::Conformance::Source::Git::git(qw{clone -- /bogus/none /bogus/never}) }, qr/\A$command\ failed:\ .+/, 'a failure says the command and what git said' );
};

# Real git, against a bare repository in a temporary directory.
subtest 'a bare repository' => sub {
    skip_all 'set RELEASE_TESTING=1 to run git against a bare repository' if !$ENV{RELEASE_TESTING};
    my $work = Mojo::File->new( File::Temp::tempdir( CLEANUP => 1 ) );
    my $bare = $work->child('standards.git');
    my $edit = $work->child('edit');
    my sub in_edit (@arguments) { return Dist::Conformance::Source::Git::git( '-C', "$edit", @arguments ) }
    Dist::Conformance::Source::Git::git( qw{init --quiet --bare}, "$bare" );
    Dist::Conformance::Source::Git::git( qw{init --quiet},        "$edit" );
    in_edit(qw{config user.name Tester});
    in_edit(qw{config user.email tester@test.test});
    my $conformance = $edit->child(qw{std conformance})->make_path;
    $conformance->child('base.yml')->spew("name: base\n");
    in_edit(qw{add -A});
    in_edit(qw{commit --quiet -m one});
    in_edit( qw{push --quiet}, "$bare", 'HEAD:refs/heads/main' );

    my $cache = cache();
    my $first = $CLASS->new( url => "$bare", ref => 'main', path => 'std', cache => $cache );
    is( $first->file('conformance/base.yml'), "name: base\n", 'reads a file of the fetched commit' );

    $edit->child(qw{std conformance base.yml})->spew("name: base\ndescription: two\n");
    in_edit(qw{commit --quiet -a -m two});
    in_edit( qw{push --quiet}, "$bare", 'HEAD:refs/heads/main' );
    is( $first->file('conformance/base.yml'), "name: base\n", 'one object keeps the commit it fetched' );

    my $second = $CLASS->new( url => "$bare", ref => 'main', path => 'std', cache => $cache );
    is( $second->file('conformance/base.yml'), "name: base\ndescription: two\n", 'a new object fetches the latest' );

    $second->base->child(qw{conformance base.yml})->spew('scribbled');
    my $third = $CLASS->new( url => "$bare", ref => 'main', path => 'std', cache => $cache );
    is( $third->file('conformance/base.yml'), "name: base\ndescription: two\n", 'a change in the cache does not survive a fetch' );

    like( dies { $CLASS->new( url => "$bare", ref => 'nope', cache => $cache )->root }, qr/git\ -C\ .+\ fetch\ .+\ failed:/, 'a ref that does not exist is an error' );
};

done_testing;
