#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path remove_tree);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_encode);

# A tiny path-registry stand-in whose home() can be undef or empty, so the
# home-shorthand branches in Config that guard on a missing home directory can
# be exercised without mutating the real registry.
{
    package Local::MockPaths;
    sub new  { my ( $class, %args ) = @_; return bless { home => $args{home} }, $class; }
    sub home { return $_[0]->{home}; }
}

# Hermetic runtime rooted at a throwaway home. The config root resolves from the
# deepest .developer-dashboard layer under the current working directory, so we
# must chdir into the temp home before building the registry.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );

my $config_file = $config->_global_config_file;

sub set_config {
    my ($data) = @_;
    open my $fh, '>:raw', $config_file or die "Unable to write $config_file: $!";
    print {$fh} json_encode($data);
    close $fh or die "Unable to close $config_file: $!";
    return $config_file;
}

sub clear_config {
    unlink $config_file if -e $config_file;
    return;
}

sub dies_like {
    my ( $code, $re, $desc ) = @_;
    my $err = eval { $code->(); 1 } ? '' : $@;
    like( $err, $re, $desc );
    return;
}

# -------------------------------------------------------------------------
# Block A: hash/array merge helpers + collector normalization (direct calls).
# -------------------------------------------------------------------------
{
    # _merge_hashes left/right defaulting when a falsy side is supplied.
    is_deeply( $config->_merge_hashes( undef, { a => 1 } ), { a => 1 }, '_merge_hashes defaults a missing left side' );
    is_deeply( $config->_merge_hashes( { a => 1 }, undef ), { a => 1 }, '_merge_hashes defaults a missing right side' );
    is_deeply( $config->_merge_hashes( { a => 1 }, { b => 2 } ), { a => 1, b => 2 }, '_merge_hashes keeps both truthy sides' );

    # 138: left value is a HASH but right value is not a HASH at the same key.
    is_deeply( $config->_merge_hashes( { k => { x => 1 } }, { k => 5 } ), { k => 5 }, '_merge_hashes lets a scalar override a nested hash' );
    is_deeply( $config->_merge_hashes( { k => { x => 1 } }, { k => { y => 2 } } ), { k => { x => 1, y => 2 } }, '_merge_hashes recurses when both sides are hashes' );
    is_deeply( $config->_merge_hashes( { k => 1 },          { k => { y => 2 } } ), { k => { y => 2 } }, '_merge_hashes lets a hash override a scalar' );

    # 142/147: left value is an ARRAY but right value is not, and a non-identity
    # array key (neither collectors nor providers) is overwritten wholesale.
    is_deeply( $config->_merge_hashes( { k => [1] }, { k => 5 } ),   { k => 5 },   '_merge_hashes lets a scalar override an array' );
    is_deeply( $config->_merge_hashes( { k => [1] }, { k => [2] } ), { k => [2] }, '_merge_hashes replaces a non-identity array wholesale' );
    is_deeply( $config->_merge_hashes( { k => 1 },   { k => [2] } ), { k => [2] }, '_merge_hashes lets an array override a scalar' );

    # 147 true side: providers merge by id.
    is_deeply(
        $config->_merge_hashes( { providers => [ { id => 'p1', a => 1 } ] }, { providers => [ { id => 'p1', b => 2 } ] } ),
        { providers => [ { id => 'p1', a => 1, b => 2 } ] },
        '_merge_hashes merges providers by id',
    );
    # 143 collectors merge by name (adjacent branch).
    is_deeply(
        $config->_merge_hashes( { collectors => [ { name => 'c1', a => 1 } ] }, { collectors => [ { name => 'c1', b => 2 } ] } ),
        { collectors => [ { name => 'c1', a => 1, b => 2 } ] },
        '_merge_hashes merges collectors by name',
    );

    # 178/179: _merge_named_hash_array defaulting + identity-key edge conditions.
    is_deeply( $config->_merge_named_hash_array( undef, [ { name => 'x' } ], 'name' ), [ { name => 'x' } ], '_merge_named_hash_array defaults a missing left array' );
    is_deeply( $config->_merge_named_hash_array( [ { name => 'x' } ], undef, 'name' ), [ { name => 'x' } ], '_merge_named_hash_array defaults a missing right array' );

    # C1 false: a non-hash item passes straight through.
    is_deeply( $config->_merge_named_hash_array( ['scalar'], [], 'name' ), ['scalar'], '_merge_named_hash_array passes through non-hash items' );
    # C2 false: identity key undefined.
    is_deeply( $config->_merge_named_hash_array( [ { name => 'a' } ], [], undef ), [ { name => 'a' } ], '_merge_named_hash_array passes items through when no identity key is given' );
    # C3 false: identity key empty string.
    is_deeply( $config->_merge_named_hash_array( [ { name => 'a' } ], [], '' ), [ { name => 'a' } ], '_merge_named_hash_array passes items through for an empty identity key' );
    # C4 false: item lacks the identity key.
    is_deeply( $config->_merge_named_hash_array( [ { other => 1 } ], [], 'name' ), [ { other => 1 } ], '_merge_named_hash_array passes items through with no identity value' );
    # C5 false: item identity value is empty string.
    is_deeply( $config->_merge_named_hash_array( [ { name => '' } ], [], 'name' ), [ { name => '' } ], '_merge_named_hash_array passes items through for an empty identity value' );
    # all true + duplicate merge path.
    is_deeply(
        $config->_merge_named_hash_array( [ { name => 'x', a => 1 } ], [ { name => 'x', b => 2 } ], 'name' ),
        [ { name => 'x', a => 1, b => 2 } ],
        '_merge_named_hash_array merges duplicate identities',
    );

    # 208: _merge_named_hash_item returns the right side unless both are hashes.
    is_deeply( $config->_merge_named_hash_item( 'scalar', { a => 1 } ), { a => 1 }, '_merge_named_hash_item returns right when left is not a hash' );
    is( $config->_merge_named_hash_item( { a => 1 }, 'scalar' ), 'scalar', '_merge_named_hash_item returns right when right is not a hash' );
    is_deeply( $config->_merge_named_hash_item( { a => 1 }, { b => 2 } ), { a => 1, b => 2 }, '_merge_named_hash_item merges two hashes' );

    # 245/247/250: collector normalization mode + multiple validation.
    is( $config->_normalize_collector_job('scalar'), 'scalar', '_normalize_collector_job passes non-hash jobs through' );
    is( $config->_normalize_collector_job( { name => 'a' } )->{mode},               'singleton', '_normalize_collector_job defaults an undefined mode to singleton' );
    is( $config->_normalize_collector_job( { name => 'b', mode => '' } )->{mode},    'singleton', '_normalize_collector_job treats an empty mode as singleton' );
    is( $config->_normalize_collector_job( { name => 'c', mode => 'singleton' } )->{multiple}, 1, '_normalize_collector_job forces singleton multiplicity to one' );
    is( $config->_normalize_collector_job( { name => 'd', mode => 'multiple', multiple => 3 } )->{multiple}, 3, '_normalize_collector_job keeps a valid multiple count' );
    is( $config->_normalize_collector_job( { name => 'e', mode => 'multiple' } )->{multiple}, 2, '_normalize_collector_job defaults an absent multiple to two' );
    is( $config->_normalize_collector_job( { name => 'i', mode => 'multiple', multiple => 2 } )->{multiple}, 2, '_normalize_collector_job accepts a positive multiple' );
    dies_like( sub { $config->_normalize_collector_job( { name => 'f', mode => 'bogus' } ) },              qr/unsupported mode 'bogus'/,             '_normalize_collector_job rejects an unsupported mode' );
    dies_like( sub { $config->_normalize_collector_job( { name => 'g', mode => 'multiple', multiple => 'abc' } ) }, qr/must be a positive integer/, '_normalize_collector_job rejects a non-numeric multiple' );
    dies_like( sub { $config->_normalize_collector_job( { name => 'h', mode => 'multiple', multiple => '0' } ) },   qr/must be a positive integer/, '_normalize_collector_job rejects a zero multiple' );

    # 267/269: disable-flag normalization.
    is( $config->_collector_disable_flag(undef), 0, '_collector_disable_flag treats undef as enabled' );
    is( $config->_collector_disable_flag( [] ),  1, '_collector_disable_flag treats a reference as disabled' );
    is( $config->_collector_disable_flag('0'),   0, '_collector_disable_flag treats a false token as enabled' );
    is( $config->_collector_disable_flag(''),    0, '_collector_disable_flag treats an empty string as enabled' );
    is( $config->_collector_disable_flag('yes'), 1, '_collector_disable_flag treats a non-empty value as disabled' );
}

# -------------------------------------------------------------------------
# Block B: SAN normalization + home-path shorthand expansion.
# -------------------------------------------------------------------------
{
    # 459/460: skip undef and reference SAN entries, keep trimmed strings.
    is_deeply(
        $config->_normalize_ssl_subject_alt_names( [ undef, [], '  host  ', '' ] ),
        ['host'],
        '_normalize_ssl_subject_alt_names drops undef/ref/blank entries and trims survivors',
    );

    # 555/558: _normalize_home_path guards on empty path and missing home.
    is( $config->_normalize_home_path(undef), undef, '_normalize_home_path returns undef for an undef path' );
    is( $config->_normalize_home_path(''),    '',    '_normalize_home_path returns empty for an empty path' );

    my $no_home    = bless { paths => Local::MockPaths->new( home => undef ), files => $files }, 'Developer::Dashboard::Config';
    my $blank_home = bless { paths => Local::MockPaths->new( home => '' ),    files => $files }, 'Developer::Dashboard::Config';
    is( $no_home->_normalize_home_path('/some/path'),    '/some/path', '_normalize_home_path returns the path unchanged when home is undef' );
    is( $blank_home->_normalize_home_path('/some/path'), '/some/path', '_normalize_home_path returns the path unchanged when home is empty' );

    # Real-home normalization paths (adjacent, non-target lines).
    is( $config->_normalize_home_path($home),          '$HOME',      '_normalize_home_path collapses an exact home path' );
    is( $config->_normalize_home_path("$home/sub"),    '$HOME/sub',  '_normalize_home_path collapses a home-relative path' );
    is( $config->_normalize_home_path('/elsewhere'),   '/elsewhere', '_normalize_home_path leaves non-home paths alone' );

    # 573/576/577/578: _expand_config_path guards + home substitutions.
    is( $config->_expand_config_path(undef), undef, '_expand_config_path returns undef for an undef path' );
    is( $config->_expand_config_path(''),    '',    '_expand_config_path returns empty for an empty path' );
    is( $config->_expand_config_path('$HOME'),      $home,           '_expand_config_path expands a bare $HOME' );
    is( $config->_expand_config_path('$HOME/sub'),  "$home/sub",     '_expand_config_path expands a $HOME-prefixed path' );
    is( $config->_expand_config_path('~x'),         "$home" . 'x',   '_expand_config_path expands a tilde-prefixed path' );
    is( $config->_expand_config_path('/plain'),     '/plain',        '_expand_config_path leaves a plain path alone' );

    # Home-undef short-circuits every $HOME/~ branch.
    is( $no_home->_expand_config_path('$HOME'),     '$HOME',     '_expand_config_path leaves $HOME alone when home is undef' );
    is( $no_home->_expand_config_path('$HOME/sub'), '$HOME/sub', '_expand_config_path leaves $HOME/... alone when home is undef' );
    is( $no_home->_expand_config_path('~x'),        '~x',        '_expand_config_path leaves ~... alone when home is undef' );
}

# -------------------------------------------------------------------------
# Block C: API-key normalization + merge helpers (direct calls).
# -------------------------------------------------------------------------
{
    # 869: non-hash payload short-circuits to an empty registry.
    is_deeply( $config->_normalize_api_keys('scalar'), {}, '_normalize_api_keys returns empty for a non-hash payload' );

    # 872/874: empty-string keys and non-hash entries are skipped.
    is_deeply(
        $config->_normalize_api_keys( { '' => { secret => 'x' }, bad => 'scalar', good => { secret => 'gs', ajax => ['/ajax/g'] } } ),
        { good => { secret => 'gs', ajax => ['/ajax/g'] } },
        '_normalize_api_keys drops blank-named and non-hash entries',
    );

    # 877: preserve_disabled toggles whether a tombstone survives normalization.
    is_deeply( $config->_normalize_api_keys( { d => { disabled => 1 } }, preserve_disabled => 1 ), { d => { disabled => 1 } }, '_normalize_api_keys keeps tombstones when preserving disabled entries' );
    is_deeply( $config->_normalize_api_keys( { d => { disabled => 1 } } ), {}, '_normalize_api_keys drops tombstones without preserve_disabled' );

    # 880/883: secret defaulting and blank-secret skipping.
    is_deeply(
        $config->_normalize_api_keys( { e1 => { ajax => [] }, e2 => { secret => [] }, e3 => { secret => '  real  ', ajax => ['/ajax/a'] } } ),
        { e3 => { secret => 'real', ajax => ['/ajax/a'] } },
        '_normalize_api_keys defaults missing/reference secrets to blank and skips blank secrets',
    );

    # 900/901: _merge_api_key_hashes defaulting.
    is_deeply( $config->_merge_api_key_hashes( undef, { a => { secret => 'x' } } ), { a => { secret => 'x', ajax => [] } }, '_merge_api_key_hashes defaults a missing left side' );
    is_deeply( $config->_merge_api_key_hashes( { a => { secret => 'x' } }, undef ), { a => { secret => 'x', ajax => [] } }, '_merge_api_key_hashes defaults a missing right side' );

    # 906: a child-layer tombstone deletes an inherited entry; a live entry is kept.
    is_deeply(
        $config->_merge_api_key_hashes( { a => { secret => 'as', ajax => [] } }, { a => { disabled => 1 }, b => { secret => 'bs' } } ),
        { b => { secret => 'bs', ajax => [] } },
        '_merge_api_key_hashes lets a tombstone delete an inherited entry while adding new ones',
    );

    # 922/926/927: disabled-flag classification for raw entries.
    is( $config->_api_key_disabled_flag('scalar'),           0, '_api_key_disabled_flag returns 0 for a non-hash entry' );
    is( $config->_api_key_disabled_flag( { disabled => [] } ), 1, '_api_key_disabled_flag treats a reference flag as disabled' );
    is( $config->_api_key_disabled_flag( { disabled => undef } ), 0, '_api_key_disabled_flag treats an undef flag as enabled' );
    is( $config->_api_key_disabled_flag( { disabled => '' } ),    0, '_api_key_disabled_flag treats a blank flag as enabled' );
    is( $config->_api_key_disabled_flag( { disabled => '0' } ),   0, '_api_key_disabled_flag treats a false token as enabled' );
    is( $config->_api_key_disabled_flag( { disabled => '1' } ),   1, '_api_key_disabled_flag treats a truthy token as disabled' );
    is( $config->_api_key_disabled_flag( {} ),                    0, '_api_key_disabled_flag returns 0 when no flag field exists' );

    # 939/943/947/948: ajax route normalization.
    is_deeply( $config->_normalize_api_ajax_routes('scalar'), [], '_normalize_api_ajax_routes returns empty for a non-array payload' );
    is_deeply(
        $config->_normalize_api_ajax_routes( [ '/ajax/dup', '/ajax/dup', undef, [], '/notajax', '  /ajax/trim  ', '' ] ),
        [ '/ajax/dup', '/ajax/trim' ],
        '_normalize_api_ajax_routes drops undef/ref/non-ajax/blank/duplicate routes and trims survivors',
    );
}

# -------------------------------------------------------------------------
# Block D: JSON hash-file loader error paths.
# -------------------------------------------------------------------------
{
    my $io = tempdir( CLEANUP => 1 );

    # 748: a JSON document that is not an object is rejected.
    my $arr_file = File::Spec->catfile( $io, 'array.json' );
    open my $afh, '>:raw', $arr_file or die $!;
    print {$afh} '[1,2]';
    close $afh;
    dies_like( sub { $config->_load_json_hash_file($arr_file) }, qr/Expected JSON object/, '_load_json_hash_file rejects a non-object document' );

    my $hash_file = File::Spec->catfile( $io, 'hash.json' );
    open my $hfh, '>:raw', $hash_file or die $!;
    print {$hfh} '{"k":"v"}';
    close $hfh;
    is_deeply( $config->_load_json_hash_file($hash_file), { k => 'v' }, '_load_json_hash_file decodes an object document' );

    # 745: an unreadable file makes the open() fail.
    my $blocked = File::Spec->catfile( $io, 'blocked.json' );
    open my $bfh, '>:raw', $blocked or die $!;
    print {$bfh} '{}';
    close $bfh;
    chmod 0000, $blocked;
    dies_like( sub { $config->_load_json_hash_file($blocked) }, qr/Unable to read/, '_load_json_hash_file dies when the file cannot be opened' );
    chmod 0600, $blocked;
}

# -------------------------------------------------------------------------
# Block E: merged-config readers (no skills present yet).
# -------------------------------------------------------------------------
{
    # 385/386: web_settings port/worker defaulting across value shapes.
    set_config( { web => { port => 'abc', workers => 'xyz' } } );
    my $ws1 = $config->web_settings;
    is( $ws1->{port},    7890, 'web_settings defaults a non-numeric port' );
    is( $ws1->{workers}, 1,    'web_settings defaults a non-numeric worker count' );

    set_config( { web => { port => '8080', workers => '0' } } );
    my $ws2 = $config->web_settings;
    is( $ws2->{port},    8080, 'web_settings keeps a numeric port' );
    is( $ws2->{workers}, 1,    'web_settings defaults a zero worker count' );

    set_config( { web => {} } );
    my $ws3 = $config->web_settings;
    is( $ws3->{port},    7890, 'web_settings defaults a missing port' );
    is( $ws3->{workers}, 1,    'web_settings defaults a missing worker count' );

    set_config( { web => { port => '9090', workers => '4' } } );
    my $ws4 = $config->web_settings;
    is( $ws4->{port},    9090, 'web_settings keeps a configured port' );
    is( $ws4->{workers}, 4,    'web_settings keeps a positive worker count' );

    set_config( { web => { host => 'example.test', port => '8443', workers => '2', ssl => 1, no_editor => 1, no_indicators => 1 } } );
    my $ws5 = $config->web_settings;
    is( $ws5->{host},          'example.test', 'web_settings keeps a configured host' );
    is( $ws5->{ssl},           1,              'web_settings reports an enabled ssl flag' );
    is( $ws5->{no_editor},     1,              'web_settings reports an enabled no_editor flag' );
    is( $ws5->{no_indicators}, 1,              'web_settings reports an enabled no_indicators flag' );

    # 349/350: web_workers validation.
    set_config( { web => { workers => 'abc' } } );
    is( $config->web_workers, 1, 'web_workers defaults a non-numeric worker count' );
    set_config( { web => { workers => '0' } } );
    is( $config->web_workers, 1, 'web_workers defaults a zero worker count' );
    set_config( { web => { workers => '4' } } );
    is( $config->web_workers, 4, 'web_workers keeps a positive worker count' );
    clear_config();
    is( $config->web_workers, 1, 'web_workers defaults a missing worker count' );

    # 603: docker_config presence/absence.
    set_config( { docker => { compose => 'x' } } );
    is_deeply( $config->docker_config, { compose => 'x' }, 'docker_config returns configured docker settings' );
    set_config( {} );
    is_deeply( $config->docker_config, {}, 'docker_config returns empty when docker config is absent' );

    # 674: providers presence/absence.
    set_config( { providers => [ { id => 'p1' } ] } );
    is_deeply( $config->providers, [ { id => 'p1' } ], 'providers returns configured provider list' );
    set_config( {} );
    is_deeply( $config->providers, [], 'providers returns empty when providers are absent' );

    # 325/336: global alias readers with hash vs non-hash config.
    set_config( { path_aliases => { a => '$HOME/x' }, file_aliases => { b => '$HOME/y' } } );
    is_deeply( $config->global_path_aliases, { a => "$home/x" }, 'global_path_aliases expands configured path aliases' );
    is_deeply( $config->global_file_aliases, { b => "$home/y" }, 'global_file_aliases expands configured file aliases' );
    set_config( {} );
    is_deeply( $config->global_path_aliases, {}, 'global_path_aliases returns empty when path aliases are absent' );
    is_deeply( $config->global_file_aliases, {}, 'global_file_aliases returns empty when file aliases are absent' );

    clear_config();
}

# -------------------------------------------------------------------------
# Block F: writable-config writers.
# -------------------------------------------------------------------------
{
    # 82: save_global_defaults defaulting.
    clear_config();
    ok( $config->save_global_defaults(), 'save_global_defaults tolerates an undef defaults argument' );
    ok( $config->save_global_defaults( { web => { workers => 2 } } ), 'save_global_defaults accepts an explicit defaults hash' );

    # 360/364: save_global_web_workers validation + web hash seeding.
    clear_config();
    dies_like( sub { $config->save_global_web_workers(undef) }, qr/Missing worker count/, 'save_global_web_workers rejects an undef count' );
    dies_like( sub { $config->save_global_web_workers('') },    qr/Missing worker count/, 'save_global_web_workers rejects an empty count' );
    is( $config->save_global_web_workers(3)->{workers}, 3, 'save_global_web_workers seeds a fresh web hash' );
    is( $config->save_global_web_workers(5)->{workers}, 5, 'save_global_web_workers updates an existing web hash' );

    # 405/411: save_global_web_settings validation + full write.
    dies_like( sub { $config->save_global_web_settings( host => '' ) },      qr/Host cannot be empty/,        'save_global_web_settings rejects an empty host' );
    dies_like( sub { $config->save_global_web_settings( port => 0 ) },       qr/between 1 and 65535/,         'save_global_web_settings rejects a low port' );
    dies_like( sub { $config->save_global_web_settings( port => 99999 ) },   qr/between 1 and 65535/,         'save_global_web_settings rejects a high port' );
    my $saved = $config->save_global_web_settings(
        host                  => '1.2.3.4',
        port                  => 8080,
        workers               => 2,
        ssl                   => 1,
        no_editor             => 1,
        no_indicators         => 1,
        ssl_subject_alt_names => [ 'a', 'b' ],
    );
    is( $saved->{host}, '1.2.3.4', 'save_global_web_settings persists valid settings' );
    is( $saved->{port}, 8080,      'save_global_web_settings normalizes a valid port' );

    # 475/476/496/499: path-alias persistence + removal.
    dies_like( sub { $config->save_global_path_alias( undef, '/x' ) }, qr/Missing path alias name/,   'save_global_path_alias rejects an undef name' );
    dies_like( sub { $config->save_global_path_alias( '', '/x' ) },    qr/Missing path alias name/,   'save_global_path_alias rejects an empty name' );
    dies_like( sub { $config->save_global_path_alias( 'n', undef ) },  qr/Missing path alias target/, 'save_global_path_alias rejects an undef target' );
    dies_like( sub { $config->save_global_path_alias( 'n', '' ) },     qr/Missing path alias target/, 'save_global_path_alias rejects an empty target' );
    dies_like( sub { $config->remove_global_path_alias(undef) },       qr/Missing path alias name/,   'remove_global_path_alias rejects an undef name' );
    dies_like( sub { $config->remove_global_path_alias('') },          qr/Missing path alias name/,   'remove_global_path_alias rejects an empty name' );

    clear_config();
    is( $config->remove_global_path_alias('ghost')->{removed}, 0, 'remove_global_path_alias seeds an absent path-alias hash' );
    ok( $config->save_global_path_alias( 'proj', '/tmp/proj' ), 'save_global_path_alias stores an alias' );
    is( $config->remove_global_path_alias('proj')->{removed}, 1, 'remove_global_path_alias removes an existing alias' );

    # 515/516/536/539: file-alias persistence + removal.
    dies_like( sub { $config->save_global_file_alias( undef, '/x' ) }, qr/Missing file alias name/,   'save_global_file_alias rejects an undef name' );
    dies_like( sub { $config->save_global_file_alias( '', '/x' ) },    qr/Missing file alias name/,   'save_global_file_alias rejects an empty name' );
    dies_like( sub { $config->save_global_file_alias( 'n', undef ) },  qr/Missing file alias target/, 'save_global_file_alias rejects an undef target' );
    dies_like( sub { $config->save_global_file_alias( 'n', '' ) },     qr/Missing file alias target/, 'save_global_file_alias rejects an empty target' );
    dies_like( sub { $config->remove_global_file_alias(undef) },       qr/Missing file alias name/,   'remove_global_file_alias rejects an undef name' );
    dies_like( sub { $config->remove_global_file_alias('') },          qr/Missing file alias name/,   'remove_global_file_alias rejects an empty name' );

    clear_config();
    is( $config->remove_global_file_alias('ghost')->{removed}, 0, 'remove_global_file_alias seeds an absent file-alias hash' );
    ok( $config->save_global_file_alias( 'notes', '/tmp/notes.txt' ), 'save_global_file_alias stores an alias' );
    is( $config->remove_global_file_alias('notes')->{removed}, 1, 'remove_global_file_alias removes an existing alias' );

    # 655: save_writable_api_registry defaulting.
    ok( $config->save_writable_api_registry(undef), 'save_writable_api_registry tolerates an undef registry' );
    ok( $config->save_writable_api_registry( { c => { secret => 'cs', ajax => ['/ajax/c'] } } ), 'save_writable_api_registry persists a registry' );
    is_deeply(
        $config->writable_api_registry,
        { c => { secret => 'cs', ajax => ['/ajax/c'] } },
        'writable_api_registry reads back the persisted registry',
    );

    clear_config();
    unlink $config->_global_api_file if -e $config->_global_api_file;
}

# -------------------------------------------------------------------------
# Block G: collectors() filter path (still no skills).
# -------------------------------------------------------------------------
{
    set_config( { collectors => [ 'scalar-job', { name => 'housekeeper', interval => 60 } ] } );
    local $ENV{DEVELOPER_DASHBOARD_CHECKERS} = 'housekeeper::extra';
    my $jobs = $config->collectors;
    is( scalar( @{$jobs} ), 1, 'collectors filters to the requested checker and drops non-hash jobs' );
    is( $jobs->[0]{name}, 'housekeeper', 'collectors keeps the requested collector' );
    clear_config();
}

# -------------------------------------------------------------------------
# Block H: atomic-write failure paths (isolated scratch, not home-runtime).
# -------------------------------------------------------------------------
{
    my $scratch = tempdir( CLEANUP => 1 );

    # 66: a read-only target directory makes the temp open() fail.
    my $rodir = File::Spec->catdir( $scratch, 'rodir' );
    make_path($rodir);
    chmod 0500, $rodir;
    dies_like( sub { $config->_write_json_atomic( File::Spec->catfile( $rodir, 'x.json' ), '{}' ) }, qr/Unable to write/, '_write_json_atomic dies when the temp file cannot be created' );
    chmod 0700, $rodir;

    # 70: renaming the temp file over an existing directory fails.
    my $target_dir = File::Spec->catdir( $scratch, 'targetdir' );
    make_path($target_dir);
    dies_like( sub { $config->_write_json_atomic( $target_dir, '{}' ) }, qr/Unable to rename/, '_write_json_atomic dies when the rename cannot replace the target' );
}

# -------------------------------------------------------------------------
# Block I: global/repo config read failures.
# -------------------------------------------------------------------------
{
    # 37: load_global open() failure on an unreadable config file.
    set_config( { web => { host => 'x' } } );
    chmod 0000, $config_file;
    dies_like( sub { $config->load_global }, qr/Unable to read/, 'load_global dies when the config file cannot be opened' );
    # 723: _load_writable_global open() failure on the same file.
    dies_like( sub { $config->_load_writable_global }, qr/Unable to read/, '_load_writable_global dies when the config file cannot be opened' );
    chmod 0600, $config_file;
    clear_config();

    # 110: load_repo open() failure vs success.
    my $repo_bad = tempdir( CLEANUP => 1 );
    my $repo_bad_file = File::Spec->catfile( $repo_bad, '.developer-dashboard.json' );
    open my $rbf, '>:raw', $repo_bad_file or die $!;
    print {$rbf} '{"repo":1}';
    close $rbf;
    chmod 0000, $repo_bad_file;
    my $repo_bad_config = Developer::Dashboard::Config->new( files => $files, paths => $paths, repo_root => $repo_bad );
    dies_like( sub { $repo_bad_config->load_repo }, qr/Unable to read/, 'load_repo dies when the repo config file cannot be opened' );
    chmod 0600, $repo_bad_file;

    my $repo_ok = tempdir( CLEANUP => 1 );
    my $repo_ok_file = File::Spec->catfile( $repo_ok, '.developer-dashboard.json' );
    open my $rof, '>:raw', $repo_ok_file or die $!;
    print {$rof} '{"repo":2}';
    close $rof;
    my $repo_ok_config = Developer::Dashboard::Config->new( files => $files, paths => $paths, repo_root => $repo_ok );
    is_deeply( $repo_ok_config->load_repo, { repo => 2 }, 'load_repo decodes a readable repo config file' );
}

# -------------------------------------------------------------------------
# Block J: installed-skill config/api discovery.
# -------------------------------------------------------------------------
{
    my $skills = $paths->skills_root;

    my %skill_config = (
        realcfg   => '{"greeting":"hi"}',
        arrjson   => '[1,2]',
        badjson   => 'not json {',
        collskill => json_encode(
            {
                collectors => [
                    'notahash',
                    {},
                    { name => '' },
                    { name => 'bar' },
                    { name => 'collskill.pre' },
                ],
            }
        ),
    );
    for my $name ( keys %skill_config ) {
        my $dir = File::Spec->catdir( $skills, $name, 'config' );
        make_path($dir);
        my $file = File::Spec->catfile( $dir, 'config.json' );
        open my $fh, '>:raw', $file or die $!;
        print {$fh} $skill_config{$name};
        close $fh;
    }
    # emptyskill: an installed skill dir with no config or api payload.
    make_path( File::Spec->catdir( $skills, 'emptyskill' ) );
    # realapi: an installed skill contributing only an api.json.
    {
        my $dir = File::Spec->catdir( $skills, 'realapi', 'config' );
        make_path($dir);
        my $file = File::Spec->catfile( $dir, 'api.json' );
        open my $fh, '>:raw', $file or die $!;
        print {$fh} '{"client1":{"secret":"s1","ajax":["/ajax/x"]}}';
        close $fh;
    }

    # 828/830: _skill_config_hash guards on a missing/blank name and no layers.
    is_deeply( $config->_skill_config_hash(undef), {}, '_skill_config_hash returns empty for an undef skill name' );
    is_deeply( $config->_skill_config_hash(''),    {}, '_skill_config_hash returns empty for a blank skill name' );
    is_deeply( $config->_skill_config_hash('no-such-skill'), {}, '_skill_config_hash returns empty when a skill has no layers' );

    # 837/839/842: decode failure, non-object, and object payloads.
    is_deeply( $config->_skill_config_hash('badjson'), {}, '_skill_config_hash falls back to empty on a decode failure' );
    is_deeply( $config->_skill_config_hash('arrjson'), {}, '_skill_config_hash falls back to empty on a non-object payload' );
    is_deeply( $config->_skill_config_hash('realcfg'), { greeting => 'hi' }, '_skill_config_hash merges an object payload' );

    # 851/853: _skill_api_hash guards on a missing/blank name and no layers.
    is_deeply( $config->_skill_api_hash(undef), {}, '_skill_api_hash returns empty for an undef skill name' );
    is_deeply( $config->_skill_api_hash(''),    {}, '_skill_api_hash returns empty for a blank skill name' );
    is_deeply( $config->_skill_api_hash('no-such-skill'), {}, '_skill_api_hash returns empty when a skill has no layers' );
    is_deeply( $config->_skill_api_hash('realapi'), { client1 => { secret => 's1', ajax => ['/ajax/x'] } }, '_skill_api_hash merges an object payload' );

    # 774/776: _skill_config_entries skips empty configs and keeps real ones.
    my %entries = map { $_->{skill_name} => $_->{config} } $config->_skill_config_entries;
    ok( exists $entries{realcfg},   '_skill_config_entries keeps a skill with a real config' );
    ok( exists $entries{collskill}, '_skill_config_entries keeps a skill with collectors' );
    ok( !exists $entries{emptyskill}, '_skill_config_entries drops a skill with an empty config' );
    ok( !exists $entries{arrjson},    '_skill_config_entries drops a skill whose config is not an object' );

    # 809/811: _skill_api_entries skips empty api payloads and keeps real ones.
    my %api_entries = map { $_->{skill_name} => $_->{api} } $config->_skill_api_entries;
    ok( exists $api_entries{realapi},    '_skill_api_entries keeps a skill with a real api payload' );
    ok( !exists $api_entries{emptyskill}, '_skill_api_entries drops a skill with an empty api payload' );

    # 965/966/969: _skill_collectors qualification and skipping.
    my %coll = map { $_->{name} => $_ } $config->_skill_collectors;
    ok( exists $coll{'collskill.bar'}, '_skill_collectors qualifies an unprefixed collector name' );
    ok( exists $coll{'collskill.pre'}, '_skill_collectors keeps an already-qualified collector name' );
    is( scalar( keys %coll ), 2, '_skill_collectors drops non-hash and unnamed collector entries' );

    # 835: _skill_config_hash open() failure on an unreadable skill config.
    {
        my $dir = File::Spec->catdir( $skills, 'iofail', 'config' );
        make_path($dir);
        my $file = File::Spec->catfile( $dir, 'config.json' );
        open my $fh, '>:raw', $file or die $!;
        print {$fh} '{}';
        close $fh;
        chmod 0000, $file;
        dies_like( sub { $config->_skill_config_hash('iofail') }, qr/Unable to read/, '_skill_config_hash dies when a skill config cannot be opened' );
        chmod 0700, $file;
        remove_tree( File::Spec->catdir( $skills, 'iofail' ) );
    }
}

done_testing;

__END__

=head1 NAME

t/93-config-coverage.t - branch and condition coverage closure for the layered configuration loader

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable coverage contract for
C<Developer::Dashboard::Config>. It drives the merge, normalization,
persistence, alias-expansion, web-settings, API-key, and installed-skill
discovery helpers through every reachable branch and condition, including the
defensive error paths (unreadable files, non-object JSON, atomic-write rename
and open failures) that the higher-level CLI and web flows rarely hit.

=head1 WHY IT EXISTS

It exists because the configuration loader owns the layered runtime config
contract, and small merge or normalization regressions silently corrupt the
effective config that every command consumes. Keeping these expectations in a
dedicated file makes the TDD loop and the all-metric coverage gate concrete for
this module instead of relying on incidental coverage from unrelated tests.

=head1 WHEN TO USE

Use this file when changing config merge semantics, collector or API-key
normalization, path/file alias persistence, web-service settings, installed
skill config/api discovery, or the atomic config writer.

=head1 HOW TO USE

Run C<perl -Ilib t/93-config-coverage.t> or C<prove -lv t/93-config-coverage.t>
while iterating, then keep it green under C<prove -lr t> and the Devel::Cover
run before release.

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, and the branch/condition
coverage gate rely on this file to keep the configuration loader at full
coverage.

=head1 EXAMPLES

Example 1:

  perl -Ilib t/93-config-coverage.t

Run the focused coverage test directly while changing the configuration loader.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/93-config-coverage.t

Exercise the same test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the change back through the entire repository suite before release.

=for comment FULL-POD-DOC END

=cut
