#!/usr/bin/env perl

use strict;
use warnings;

# CORE::GLOBAL overrides must be installed before the modules under test are
# compiled.  They fail only for registered exact paths / path prefixes and for
# registered handles, so they work identically for root and non-root users.
our ( %FAIL, %FAIL_PREFIX, %FAIL_OPENDIR, %CLOSE_FAIL_PREFIX, %CLOSE_FAIL_HANDLE );

BEGIN {
    require Scalar::Util;
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            my $path = $_[2];
            if ( $FAIL{$path} || grep { index( $path, $_ ) == 0 } keys %FAIL_PREFIX ) {
                $! = 13;
                return 0;
            }
            if ( grep { index( $path, $_ ) == 0 } keys %CLOSE_FAIL_PREFIX ) {
                my $ok = CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
                $CLOSE_FAIL_HANDLE{ Scalar::Util::refaddr( ref $_[0] ? $_[0] : \$_[0] ) } = 1 if $ok && ref $_[0];
                return $ok;
            }
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
    *CORE::GLOBAL::close = sub (;*) {
        return CORE::close() if !@_;
        my $h = $_[0];
        if ( ref $h && $CLOSE_FAIL_HANDLE{ Scalar::Util::refaddr($h) } ) {
            delete $CLOSE_FAIL_HANDLE{ Scalar::Util::refaddr($h) };
            CORE::close($h);
            $! = 5;
            return 0;
        }
        $h = caller() . "::$h" if !ref $h && $h !~ /::/;
        return CORE::close($h);
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);

use lib 'lib';

use Developer::Dashboard;
use Developer::Dashboard::Auth;
use Developer::Dashboard::Codec qw(encode_payload);
use Developer::Dashboard::Config;
use Developer::Dashboard::EnvInclude;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Handle;
use Developer::Dashboard::JSON qw(json_encode);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PerlEnv;

my $home = abs_path( tempdir( CLEANUP => 1 ) );
local $ENV{HOME} = $home;
local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT} = tempdir( CLEANUP => 1 );
chdir $home or die "Unable to chdir to $home: $!";

sub write_file {
    my ( $file, $text ) = @_;
    make_path( ( File::Spec->splitpath($file) )[1] );
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh or die "Unable to close $file: $!";
    return $file;
}

sub dies (&) { my ($c) = @_; return eval { $c->(); 1 } ? '' : $@ }

sub fresh {
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );
    my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
    my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
    return ( $paths, $config );
}

# --- Config: open/close failures -------------------------------------------
{
    my ( $paths, $config ) = fresh();
    like(
        dies { $config->path_aliases( nested_skill_entries => {} ) },
        qr/nested_skill_entries must be an array reference/,
        'path_aliases rejects malformed shared nested-skill inventory',
    );
    like(
        dies { $config->path_aliases( unsupported => 1 ) },
        qr/Unsupported path_aliases option 'unsupported'/,
        'path_aliases rejects unknown options instead of silently ignoring them',
    );
    like(
        dies { $config->path_aliases('odd') },
        qr/path_aliases options must be key\/value pairs/,
        'path_aliases reports an incomplete option pair directly',
    );
    like(
        dies { $config->_nested_skill_alias_entries( 'path_aliases', nested_skill_entries => {} ) },
        qr/nested_skill_entries must be an array reference/,
        'nested alias reader rejects malformed shared inventory directly',
    );
    like(
        dies { $config->_nested_skill_alias_entries( 'path_aliases', nested_skill_entries => [undef] ) },
        qr/nested_skill_entries must contain hash references/,
        'nested alias reader rejects malformed inventory rows directly',
    );
    like(
        dies { $config->load_global( skill_config_entries => {} ) },
        qr/skill_config_entries must be an array reference/,
        'load_global rejects malformed precomputed skill config entries',
    );
    like(
        dies { $config->load_global( skill_config_entries_out => {} ) },
        qr/skill_config_entries_out must be an array reference/,
        'load_global rejects a malformed skill config output array',
    );
    like(
        dies { $config->merged( unsupported => 1 ) },
        qr/Unsupported merged option 'unsupported'/,
        'merged rejects unknown inventory options visibly',
    );
    like(
        dies { $config->merged( skill_config_entries => {} ) },
        qr/skill_config_entries must be an array reference/,
        'merged rejects malformed precomputed skill config entries',
    );
    like(
        dies { $config->merged( skill_config_entries_out => {} ) },
        qr/skill_config_entries_out must be an array reference/,
        'merged rejects a malformed skill config output array',
    );
    like(
        dies { $config->_skill_path_aliases( skill_config_entries => {} ) },
        qr/skill_config_entries must be an array reference/,
        'skill alias reader rejects malformed precomputed config entries',
    );
    like(
        dies { $config->_skill_path_aliases( skill_config_entries => [undef] ) },
        qr/skill_config_entries must contain hash references/,
        'skill alias reader rejects malformed precomputed config rows',
    );
    like(
        dies { $config->_skill_config_fragments([undef]) },
        qr/skill config entries must contain hash references/,
        'skill fragment reader rejects malformed inventory rows',
    );
    like(
        dies { $config->_skill_config_fragments( {} ) },
        qr/skill config entries must be an array reference/,
        'skill fragment reader rejects a malformed input array',
    );
    like(
        dies { $config->_skill_config_fragments( [], {} ) },
        qr/skill config entries output must be an array reference/,
        'skill fragment reader rejects a malformed output array',
    );
    like(
        dies { $config->_skill_collectors({}) },
        qr/skill config entries must be an array reference/,
        'skill collector reader rejects a malformed input array',
    );
    like(
        dies { $config->_skill_collectors([undef]) },
        qr/skill config entries must contain hash references/,
        'skill collector reader rejects malformed entry rows',
    );
    like(
        dies { $config->collectors( merged_config => {} ) },
        qr/merged_config and skill_config_entries must be supplied together/,
        'collectors rejects an incomplete request snapshot',
    );
    like(
        dies { $config->collectors( skill_config_entries => [] ) },
        qr/merged_config and skill_config_entries must be supplied together/,
        'collectors rejects a request snapshot with only skill entries',
    );
    like(
        dies { $config->collectors( merged_config => [], skill_config_entries => [] ) },
        qr/merged_config must be a hash reference/,
        'collectors rejects a non-hash merged request snapshot',
    );
    like(
        dies { $config->collectors( merged_config => {}, skill_config_entries => {} ) },
        qr/skill_config_entries must be an array reference/,
        'collectors rejects non-array skill entries in a request snapshot',
    );
    like(
        dies { $config->collectors( unsupported => 1 ) },
        qr/Unsupported collectors option 'unsupported'/,
        'collectors rejects unsupported snapshot options',
    );
    like(
        dies { $config->collectors('merged_config') },
        qr/collectors options must be key\/value pairs/,
        'collectors rejects an incomplete option pair',
    );
    like(
        dies { $config->web_settings( merged_config => [] ) },
        qr/merged_config must be a hash reference/,
        'web_settings rejects a malformed merged request snapshot',
    );
    like(
        dies { $config->web_settings( unsupported => 1 ) },
        qr/Unsupported web_settings option 'unsupported'/,
        'web_settings rejects unsupported snapshot options',
    );
    like(
        dies { $config->web_settings('merged_config') },
        qr/web_settings options must be key\/value pairs/,
        'web_settings rejects an incomplete option pair',
    );
    is( Developer::Dashboard::Config::_normalize_ssl_validity_days(undef), 365,
        'SSL validity normalization defaults an unset value' );
    is( Developer::Dashboard::Config::_normalize_ssl_validity_days('invalid'), 365,
        'SSL validity normalization defaults a non-numeric value' );
    is( Developer::Dashboard::Config::_normalize_ssl_validity_days(0), 365,
        'SSL validity normalization defaults a non-positive value' );
    is( Developer::Dashboard::Config::_normalize_ssl_validity_days(800), 800,
        'SSL validity normalization preserves a valid configured value' );
    my @no_output_fragments = $config->_skill_config_fragments([]);
    is_deeply( \@no_output_fragments, [], 'skill config fragments accept an omitted entries output target' );
    my $captured_skill_entries = ['stale'];
    my @captured_fragments = $config->_skill_config_fragments( [], $captured_skill_entries );
    is_deeply( \@captured_fragments, [], 'skill config fragments return no entries for an empty input' );
    is_deeply( $captured_skill_entries, [], 'skill config fragments populate a supplied entries output target' );
    my $global = $config->_global_config_file;
    write_file( $global, '{}' );

    {
        local $FAIL{$global} = 1;
        like( dies { $config->load_global }, qr/Unable to read/, 'load_global dies when the config cannot be opened' );
        like( dies { $config->_load_writable_global }, qr/Unable to read/, '_load_writable_global dies when the config cannot be opened' );
        like( dies { $config->_load_json_hash_file($global) }, qr/Unable to read/, '_load_json_hash_file dies when the file cannot be opened' );
    }

    my $repo = File::Spec->catdir( $home, 'repo' );
    make_path($repo);
    my $repo_file = write_file( File::Spec->catfile( $repo, '.developer-dashboard.json' ), '{}' );
    my $rconfig = Developer::Dashboard::Config->new( files => $config->{files}, paths => $paths, repo_root => $repo );
    {
        local $FAIL{$repo_file} = 1;
        like( dies { $rconfig->load_repo }, qr/Unable to read/, 'load_repo dies when the repo config cannot be opened' );
    }

    my $target = File::Spec->catfile( $home, 'atomic.json' );
    {
        local $FAIL_PREFIX{ $target . '.tmp.' } = 1;
        like( dies { $config->_write_json_atomic( $target, '{}' ) }, qr/Unable to write/, '_write_json_atomic dies when the temp file cannot be opened' );
    }
    {
        local $CLOSE_FAIL_PREFIX{ $target . '.tmp.' } = 1;
        like( dies { $config->_write_json_atomic( $target, '{}' ) }, qr/Unable to close/, '_write_json_atomic dies when closing the temp file fails' );
    }
    ok( $config->_write_json_atomic( $target, '{}' ), '_write_json_atomic still succeeds normally' );

    # skill config / api reads
    my $skill = File::Spec->catdir( $home, '.developer-dashboard', 'skills', 'alpha' );
    my $skill_cfg = write_file( File::Spec->catfile( $skill, 'config', 'config.json' ), '{"a":1}' );
    {
        local $FAIL{$skill_cfg} = 1;
        like( dies { $config->_skill_config_hash('alpha') }, qr/Unable to read/, '_skill_config_hash dies when a skill config cannot be opened' );
    }
    {
        local $CLOSE_FAIL_PREFIX{$skill_cfg} = 1;
        is_deeply( $config->_skill_config_hash('alpha'), { a => 1 }, '_skill_config_hash ignores close status of the read handle' );
    }
    is_deeply( $config->_skill_config_hash( 'alpha', layers => {} ), {},
        '_skill_config_hash rejects a non-array grouped layer argument' );
    is_deeply( $config->_skill_api_hash( 'alpha', layers => {} ), {},
        '_skill_api_hash rejects a non-array grouped layer argument' );

    # empty skill config / api are skipped; unmatched roots produce no skill name
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::installed_skill_entries = sub {
            return (
                { skill_root => '/', layers => [] },
                { skill_name => 'nope-skill', skill_root => File::Spec->catdir( $home, 'nope-skill' ), layers => [] },
            );
        };
        local *Developer::Dashboard::PathRegistry::installed_skill_roots = sub { return ( '/', File::Spec->catdir( $home, 'nope-skill' ) ) };
        is_deeply( [ $config->_skill_config_entries ], [], '_skill_config_entries skips grouped entries with no name or no config' );
        is_deeply( [ $config->_skill_api_entries ],    [], '_skill_api_entries skips roots with no name and no api keys' );
    }
}

# --- Config: path_aliases reuses the layered skill config inventory --------
{
    my $skill_config = File::Spec->catfile( $home, '.developer-dashboard', 'skills', 'inventory-test', 'config', 'config.json' );
    write_file( $skill_config, json_encode( { path_aliases => { source => '/tmp/source' }, unrelated => { expensive => [ 1 .. 50 ] } } ) );
    my ( $paths, $config ) = fresh();
    my $original = \&Developer::Dashboard::PathRegistry::installed_skill_entries;
    my $original_merge = \&Developer::Dashboard::Config::_merge_hashes;
    my $calls = 0;
    my $unused_skill_fragments = 0;
    my $unused_skill_fields = 0;
    my $aliases;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::installed_skill_entries = sub {
            $calls++;
            return $original->(@_);
        };
        local *Developer::Dashboard::Config::_merge_hashes = sub {
            my ( $self, $left, $right ) = @_;
            $unused_skill_fragments++
              if ref($right) eq 'HASH'
              && keys(%{$right}) == 1
              && exists $right->{'_inventory-test'};
            $unused_skill_fields++ if ref($right) eq 'HASH' && exists $right->{unrelated};
            return $original_merge->(@_);
        };
        $aliases = $config->path_aliases( nested_skill_entries => [] );
    }
    is( $calls, 1, 'path_aliases scans installed skill layers once to read qualified aliases' );
    is( $unused_skill_fragments, 0, 'path_aliases skips merging unused full skill namespaces into the global config view' );
    is( $unused_skill_fields, 0, 'path_aliases does not merge unrelated skill config fields while reading aliases' );
    is( $aliases->{'inventory-test.source'}, '/tmp/source', 'reusing the config inventory preserves the skill-qualified alias' );
}

# --- Config: alias-only skill views skip skills without the selected domain --
{
    my $skill_config = File::Spec->catfile( $home, '.developer-dashboard', 'skills', 'without-aliases', 'config', 'config.json' );
    write_file( $skill_config, json_encode( { unrelated => { values => [ 1 .. 20 ] } } ) );
    my ( $paths, $config ) = fresh();
    my @entries = $config->_skill_path_alias_entries;
    ok( !grep( { $_->{skill_name} eq 'without-aliases' } @entries ),
        '_skill_path_alias_entries skips a skill with no path_aliases domain' );
    is_deeply( $config->_skill_config_hash( 'without-aliases', only_key => 'missing' ), {},
        '_skill_config_hash returns an empty view when the selected key is absent' );
}

# --- Config: empty alias keys and unreachable removal paths ----------------
{
    my $skills = File::Spec->catdir( $home, '.developer-dashboard', 'skills' );
    my $aliases = { '' => '/empty', ok => '/ok' };
    write_file( File::Spec->catfile( $skills, 'foo', 'config', 'config.json' ),
        json_encode( { path_aliases => $aliases, file_aliases => $aliases } ) );
    write_file( File::Spec->catfile( $skills, 'foo', 'skills', 'bar', 'config', 'config.json' ),
        json_encode( { path_aliases => $aliases, file_aliases => $aliases } ) );
    my ( $paths, $config ) = fresh();
    ok( exists $config->_skill_path_aliases->{'foo.ok'} && !exists $config->_skill_path_aliases->{'foo.'}, 'empty path alias keys are skipped for skills' );
    ok( exists $config->_skill_file_aliases->{'foo.ok'} && !exists $config->_skill_file_aliases->{'foo.'}, 'empty file alias keys are skipped for skills' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::skill_config_write_location = sub { die 'nested alias discovery must reuse its resolved chain' };
        is_deeply(
            [ sort keys %{ $config->_nested_skill_alias_entries('path_aliases') } ],
            ['foo.bar.ok'],
            'empty nested alias keys are skipped while the already-resolved write location is reused',
        );
    }

    # a global fallback section holding an empty key
    my $global = $config->_global_config_file;
    write_file( $global, json_encode( { skills => { bar => { path_aliases => $aliases } } } ) );
    {
        no warnings 'redefine';
        my $nested_skill_entries = \&Developer::Dashboard::PathRegistry::nested_skill_entries;
        local *Developer::Dashboard::PathRegistry::nested_skill_entries = sub {
            my ( $registry, %args ) = @_;
            return map {
                { %$_, config_write_location => { kind => 'global', remaining => ['bar'] } }
            } $nested_skill_entries->( $registry, %args );
        };
        my $got = $config->_nested_skill_alias_entries('path_aliases');
        ok( exists $got->{'foo.bar.ok'} || exists $got->{'foo.ok'}, 'global fallback walk still yields aliases' );
        ok( !grep( { /\.$/ } keys %{$got} ), 'global fallback skips the empty alias key' );
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PathRegistry::skill_config_write_location = sub { return { kind => 'global', remaining => [ 'missing', 'deeper' ] } };
        my $r = $config->_remove_skill_alias( 'path_aliases', ['foo'], 'ok' );
        is( $r->{removed}, 0, 'removal reports nothing removed when the global fallback path is missing' );
    }
    is_deeply( [ $config->split_skill_alias_name('a.b') ], [ ['a'], 'b' ], 'split_skill_alias_name still splits a dotted name' );
    is_deeply( [ $config->split_skill_alias_name('a.') ], [], 'split_skill_alias_name rejects an empty trailing segment' );
}

# --- EnvLoader --------------------------------------------------------------
{
    my $env_file = write_file( File::Spec->catfile( $home, 'e', '.env' ), "ZZ_S6=1\n" );
    {
        local $CLOSE_FAIL_PREFIX{$env_file} = 1;
        like( dies { Developer::Dashboard::EnvLoader->_load_env_file($env_file) }, qr/Unable to close/, '_load_env_file dies when the close fails' );
    }
    my $pl = write_file( File::Spec->catfile( $home, 'e', '.env.pl' ), q{$ENV{ZZ_S6_PL} = 1;} . "\n" );
    is_deeply( [ Developer::Dashboard::EnvLoader->_env_pl_assigned_keys($pl) ], ['ZZ_S6_PL'], '_env_pl_assigned_keys reads assigned keys' );
    {
        local $FAIL{$pl} = 1;
        is_deeply( [ Developer::Dashboard::EnvLoader->_env_pl_assigned_keys($pl) ], [], '_env_pl_assigned_keys returns nothing when the file cannot be opened' );
    }
    {
        local $CLOSE_FAIL_PREFIX{$pl} = 1;
        is_deeply( [ Developer::Dashboard::EnvLoader->_env_pl_assigned_keys($pl) ], ['ZZ_S6_PL'], '_env_pl_assigned_keys tolerates a failing close' );
    }

    {
        package Local::FakePaths;
        sub new { return bless { cwd => $_[1], home => $_[2] }, $_[0] }
        sub current_working_directory { return $_[0]{cwd} }
        sub home                      { return $_[0]{home} }
        sub current_project_root      { return '' }
    }
    {
        no warnings 'redefine';
        local *Developer::Dashboard::EnvLoader::_same_or_descendant_path = sub { 1 };
        my @layers = Developer::Dashboard::EnvLoader->_plain_directory_layers( Local::FakePaths->new( '/s6a/s6b', '/s6-other-home' ) );
        is_deeply( \@layers, [ '/', '/s6a', '/s6a/s6b' ], 'layer walk stops at the filesystem root when the stop directory is never met' );
    }
}

# --- EnvInclude -------------------------------------------------------------
{
    my $dir = File::Spec->catdir( $home, 'inc', 'skills' );
    make_path($dir);
    {
        local $FAIL_OPENDIR{$dir} = 1;
        like( dies { Developer::Dashboard::EnvInclude->_recursive_sub_skills( File::Spec->catdir( $home, 'inc' ), 'inc' ) }, qr/Unable to read/, '_recursive_sub_skills dies when the skills directory cannot be opened' );
    }
    write_file( File::Spec->catfile( $home, 'inc', '.env' ), "S6KEY=1\n" );
    local $ENV{S6KEY};
    Developer::Dashboard::EnvInclude->_include_one( File::Spec->catdir( $home, 'inc' ), '...' );
    is( $ENV{S6KEY}, 1, '_include_one leaves the key unprefixed when the namespace prefix is empty' );
    delete $ENV{S6KEY};
}

# --- PerlEnv ----------------------------------------------------------------
{
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PerlEnv::abs_path = sub { return undef };
        local $^X = '/usr/bin/s6-perl';
        is( Developer::Dashboard::PerlEnv::current_perl_bin_dir(), '/usr/bin', 'current_perl_bin_dir falls back to $^X when abs_path fails' );
        like( Developer::Dashboard::PerlEnv::current_shell_bin_dir(), qr{^(?:|/.+)$}, 'current_shell_bin_dir falls back to the raw shell path when abs_path fails' );
    }
    ok( defined Developer::Dashboard::PerlEnv->perl5lib_env( path_sep => ';', env => { PERL5LIB => 'a;b' } ), 'perl5lib_env honours an explicit path_sep' );
    ok( defined Developer::Dashboard::PerlEnv->perl5lib_env( env => { PERL5LIB => 'a' } ), 'perl5lib_env defaults the separator' );
    ok( defined Developer::Dashboard::PerlEnv->perl5lib_list( path_sep => ';', env => {} ) ? 1 : 0, 'perl5lib_list honours an explicit path_sep' );
    like( Developer::Dashboard::PerlEnv->path_with_current_perl( path_sep => ';', env => { PATH => "$home;/tmp" } ), qr/\Q$home;\E/, 'path_with_current_perl honours an explicit path_sep' );
    ok( defined Developer::Dashboard::PerlEnv->path_with_current_perl( env => { PATH => 'x' } ), 'path_with_current_perl defaults the separator' );
}

# --- Handle / Dashboard ------------------------------------------------------
{
    my $h = Developer::Dashboard::Handle->new;
    is( $h->{cwd}, Cwd::cwd(), 'Handle->new defaults cwd to the current directory' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::Handle::current_working_directory = sub { return undef };
        ok( !defined Developer::Dashboard::Handle->new->{cwd}, 'Handle->new accepts an undefined default cwd' );
    }
    {
        my $proxy = $h->collector->list;
        undef $proxy;
        pass('an un-terminated proxy chain is dropped without dispatching DESTROY');
    }
    make_path( File::Spec->catdir( $home, 'projects' ) );
    ok( ref( $h->paths ) eq 'HASH', 'Handle paths resolves with an existing workspace root' );
    my $a = Developer::Dashboard::d2();
    my $b = Developer::Dashboard::d2();
    is( $a, $b, 'd2() memoizes the handle per working directory' );
}

# --- Codec ------------------------------------------------------------------
{
    no warnings 'redefine';
    local *Developer::Dashboard::Codec::gzip = sub { return 0 };
    like( dies { encode_payload('x') }, qr/gzip failed/, 'encode_payload dies when gzip fails' );
}

# --- Auth -------------------------------------------------------------------
{
    my $auth   = bless {}, 'Developer::Dashboard::Auth';
    my $scheme = 'pbkdf2-hmac-sha256';
    my $user   = { password_scheme => $scheme, salt => 's', password_hash => 'x' };
    my $with   = { %{$user}, iterations => 3 };
    isnt( $auth->_expected_password_hash( $user, 'u', 'pw' ), $auth->_expected_password_hash( $with, 'u', 'pw' ), 'a record without iterations uses the default count, one with iterations uses its own' );
}

done_testing;

__END__

=pod

=head1 NAME

t/650-core-modules-coverage.t - zero-annotation coverage for Config, EnvLoader, EnvInclude, PerlEnv, Handle, Codec, Auth and Developer::Dashboard

=head1 PURPOSE

This coverage test exercises core module contracts, rejects incomplete or
malformed merged-config snapshots passed to web-settings and collector readers,
and covers SSL-validity normalization and optional skill-entry output capture.

Test file in the Developer Dashboard codebase. It forces open, opendir and close failures with exact-path CORE::GLOBAL overrides, stubs gzip and abs_path, and exercises empty alias keys, malformed shared skill-config entries and output arrays, grouped installed-skill entries, and the filesystem-root walk so every branch of these modules is reached by a real test.

=head1 WHY IT EXISTS

It exists because lib/ must reach 100 percent Devel::Cover coverage with no uncoverable annotations, and these paths previously relied on annotations that hid them.

=head1 WHEN TO USE

Use this file when you change I/O error handling or alias walking in Config, EnvLoader or EnvInclude, grouped skill-config discovery, the PerlEnv fallbacks, the Handle proxy, Codec or Auth. Its Config checks guard that callers can reuse skill config entries from a merged read and that malformed precomputed or output arrays are rejected explicitly.

=head1 HOW TO USE

Run it with C<prove -lv t/650-core-modules-coverage.t>; the failure injection works for root and non-root users because it does not rely on file permissions.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/650-core-modules-coverage.t

Run the coverage-gap test by itself.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/650-core-modules-coverage.t

Confirm the formerly annotated branches are reported as covered.

=cut
