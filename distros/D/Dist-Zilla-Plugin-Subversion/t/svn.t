#!perl
use 5.010;
use strict;
use warnings;
use utf8;


use Cwd;
use Dist::Zilla::Tester 4.101550;
use English qw(-no_match_vars);
use File::Temp;
use Modern::Perl;
use Path::Class qw(dir file);
use SVN::Client;
use SVN::Repos;
use Test::Most;
use Test::Moose;
use Text::Template;
use Readonly;

our %MODULES;
my $tests = 12;

BEGIN {
    Readonly our %MODULES => (
        'Dist::Zilla::Plugin::Subversion::ReleaseDist' => 'release',
        'Dist::Zilla::Plugin::Subversion::Tag'         => 'after_release',
    );
    for ( keys %MODULES ) { use_ok($ARG) }
}

for my $module ( keys %MODULES ) {
    isa_ok( $module, 'Moose::Object', $module );
    for (qw(svn_user svn_password working_url)) {
        has_attribute_ok( $module, $ARG, "$module has the $ARG attribute" );
    }
    can_ok( $module, $MODULES{$module} );
}

my $wc       = File::Temp->newdir();
my $repo_dir = File::Temp->newdir();
my $repo_uri = URI::file->new_abs("$repo_dir");
{
    ## no critic (ProhibitCallsToUnexportedSubs)
    my $repos = SVN::Repos::create( "$repo_dir", undef, undef, undef, undef );
}
dir( "$wc", 'trunk' )->mkpath();
my $ini_file = file( "$wc", qw(trunk dist.ini) );
my $ini_template
    = Text::Template->new( type => 'string', source => <<'END_INI');
name     = test
author   = test user
abstract = test release
license  = BSD
version  = 1.{$version || 0}
copyright_holder = test holder

{$repository_plugin}
[Subversion::ReleaseDist]
{ join "\n", @ini_lines }
[Subversion::Tag]
{ join "\n", @ini_lines }
END_INI

my $fh = $ini_file->openw();
print $fh $ini_template->fill_in();
close $fh;
for (qw(tags branches)) { dir( "$wc", $ARG )->mkpath() }

my $test_client = SVN::Client->new();
$test_client->import( "$wc", "$repo_uri", 0 );
for (qw(trunk tags branches)) { dir( "$wc", $ARG )->rmtree() }
$test_client->copy( "$repo_uri/trunk", 'HEAD',
    "$repo_uri/branches/test_branch" );
$test_client->checkout( "$repo_uri/trunk", "$wc", 'HEAD', 1 );

my $version = 1;
for my $branch (qw(trunk branches/test_branch)) {

    my %plugin_test = (
        from_checkout => [],
        working_only  => ["working_url = $repo_uri/$branch"],
        tag_only      => ["tag_url     = $repo_uri/tags"],
    );
    $plugin_test{full_ini} = \@plugin_test{qw(working_only tag_only)};
    eval { require Dist::Zilla::Plugin::Repository; 1 }
        and $plugin_test{repository} = [];

    while ( my ( $test_name, $plugins_ref ) = each %plugin_test ) {
        my $zilla
            = Dist::Zilla::Tester->from_config( { dist_root => "$wc" } );
        $test_client->switch( $zilla->root->stringify(),
            "$repo_uri/$branch", 'HEAD', 1 );

        my $fh = $zilla->root->file('dist.ini')->openw();
        print $fh $ini_template->fill_in(
            hash => {
                ini_lines         => $plugins_ref,
                version           => $version++,
                repository_plugin => exists $plugin_test{repository}
                ? '[Repository]'
                : q{},
            },
        );
        close $fh;

        lives_ok( sub { $zilla->release() }, $test_name );
        my %meta = %{ $zilla->distmeta() };
        my $dist_name = join '-', @meta{qw(name version)};

        lives_and(
            sub {
                isa_ok(
                    $test_client->delete(
                        "$repo_uri/dists/$dist_name.tar.gz", 0
                    ),
                    '_p_svn_client_commit_info_t',
                    "$test_name released"
                );
            },
        );

        lives_and(
            sub {
                isa_ok(
                    $test_client->delete( "$repo_uri/tags/$dist_name", 0 ),
                    '_p_svn_client_commit_info_t', "$test_name tagged" );
            },
        );
    }
    $tests += 3 * keys %plugin_test;
}
done_testing($tests);
