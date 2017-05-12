#! /usr/bin/perl
#---------------------------------------------------------------------

use strict;
use warnings;
use Test::More;

use Dist::Zilla::Tester;

#---------------------------------------------------------------------
# Fake execution of VCS commands:

use Dist::Zilla::Plugin::Repository;    # make sure it's already loaded
use File::Temp qw/tempdir/;
local $ENV{HOME} = tempdir( CLEANUP => 1 );

my %result;

{

    package Dist::Zilla::Plugin::Repository;
    no warnings 'redefine';

    sub _execute {
        my $cmd = shift;
        $result{$cmd} || die "Unexpected command <$cmd>";
    }
}

$result{'git remote show -n origin'} = <<'END GIT';
* remote origin
  Fetch URL: git@github.com:fayland/dist-zilla-plugin-repository.git
  Push  URL: git@github.com:fayland/dist-zilla-plugin-repository.git
  HEAD branch: (not queried)
  Remote branch: (status not queried)
    master
  Local branch configured for 'git pull':
    master merges with remote master
  Local ref configured for 'git push' (status not queried):
    (matching) pushes to (matching)
END GIT

$result{'git remote show -n dzil'} = <<'END GIT DZIL';
* remote dzil
  Fetch URL: git://github.com/rjbs/dist-zilla.git
  Push  URL: git://github.com/rjbs/dist-zilla.git
  HEAD branch: (not queried)
  Remote branches: (status not queried)
    config-mvp-reader
    cpan-meta-prereqs
    master
    new-classic
    prereq-overhaul
  Local ref configured for 'git push' (status not queried):
    (matching) pushes to (matching)
END GIT DZIL

$result{'svn info'} = <<'END SVN';
Path: .
URL: http://example.com/svn/trunk/my-project
Repository Root: http://example.com/svn
Repository UUID: 12345678-9012-3456-7890-123456789012
Revision: 1234
Node Kind: directory
Schedule: normal
Last Changed Author: example
Last Changed Rev: 1234
Last Changed Date: 2008-09-27 15:42:32 -0500 (Sat, 27 Sep 2008)
END SVN

$result{'darcs query repo'} = <<'END DARCS';
          Type: darcs
        Format: darcs-1.0
          Root: /home/user/foobar
      Pristine: PlainPristine "_darcs/pristine"
         Cache: thisrepo:/home/user/foobar
Default Remote: http://example.com/darcs
   Num Patches: 2
END DARCS

$result{'hg paths'} = <<'END HG';
default = https://foobar.googlecode.com/hg/
END HG

#---------------------------------------------------------------------
sub make_ini {
    my $ini = <<'END START';
name     = DZT-Sample
author   = E. Xavier Ample <example@example.org>
license  = Perl_5
copyright_holder = E. Xavier Ample
version  = 0.01

[GatherDir]
[Repository]
END START

    $ini . join( '', map { "$_\n" } @_ );
}    # end make_ini

#---------------------------------------------------------------------
sub build_tzil {
    my $repo = shift || [];

    my @extra_files;
    while (@_) {
        push @extra_files, "source/" . shift;
        push @extra_files, @_ ? shift : '';
    }

    my $tzil = Builder->from_config(
        { dist_root => 't/corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' => make_ini(@$repo),
                @extra_files,
            },
        },
    );

    $tzil->build;

    return $tzil;
}    # end build_tzil

#---------------------------------------------------------------------
sub github_deprecated {
    scalar grep { /github_http is deprecated/ } @{ shift->log_messages };
}    # end github_deprecated

#---------------------------------------------------------------------
sub remote_not_found {
    scalar grep { /Skipping invalid git remote/ } @{ shift->log_messages };
}    # end remote_not_found

#=====================================================================
{
    my $tzil = build_tzil();

    is( $tzil->distmeta->{resources}{repository}, undef, "No repository" );
    ok( !github_deprecated($tzil), "No repository log message" );
}

#---------------------------------------------------------------------
{
    my $url = 'http://example.com';

    my $tzil = build_tzil( ["repository = $url"] );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { url => $url },
        "Just a URL"
    );
    ok( !github_deprecated($tzil), "Just a URL log message" );
}

#---------------------------------------------------------------------
{
    my $url = 'http://example.com/svn/repo';

    my $tzil = build_tzil( [ "repository = $url", 'type = svn' ] );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { url => $url, type => 'svn' },
        "SVN with type"
    );
    ok( !github_deprecated($tzil), "SVN with type log message" );
}

#---------------------------------------------------------------------
{
    my $url = 'http://example.com/svn/repo';
    my $web = 'http://example.com';

    my $tzil =
      build_tzil( [ "repository = $url", "web = $web", 'type = svn' ] );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { web => $web, url => $url, type => 'svn' },
        "SVN with type and web"
    );
    ok( !github_deprecated($tzil), "SVN with type and web log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( [], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'git',
            url  => 'git://github.com/fayland/dist-zilla-plugin-repository.git',
            web  => 'https://github.com/fayland/dist-zilla-plugin-repository'
        },
        "Auto github"
    );
    ok( !github_deprecated($tzil), "Auto github log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( ['github_http = 1'], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'git',
            web  => 'https://github.com/fayland/dist-zilla-plugin-repository'
        },
        "Auto github with http"
    );
    ok( github_deprecated($tzil), "Auto github with http log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( ['github_http = 0'], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'git',
            url  => 'git://github.com/fayland/dist-zilla-plugin-repository.git',
            web  => 'https://github.com/fayland/dist-zilla-plugin-repository'
        },
        "Auto github no http"
    );
    ok( !github_deprecated($tzil), "Auto github no http log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( [ 'git_remote = dzil', 'github_http = 1' ], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'git',
            web  => 'https://github.com/rjbs/dist-zilla'
        },
        "Auto github remote dzil with github_http"
    );
    ok( github_deprecated($tzil),
        "Auto github remote dzil with github_http log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( ['git_remote = dzil'], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'git',
            url  => 'git://github.com/rjbs/dist-zilla.git',
            web  => 'https://github.com/rjbs/dist-zilla'
        },
        "Auto github remote dzil no http"
    );
    ok( !github_deprecated($tzil),
        "Auto github remote dzil no http log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( [], '.svn' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'svn',
            url  => 'http://example.com/svn/trunk/my-project'
        },
        "Auto svn"
    );
    ok( !github_deprecated($tzil), "Auto svn log message" );
}

#---------------------------------------------------------------------
{
    my $web = 'http://example.com';

    my $tzil = build_tzil( ["web = $web"], '.svn' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'svn',
            web  => $web,
            url  => 'http://example.com/svn/trunk/my-project'
        },
        "Auto svn with web"
    );
    ok( !github_deprecated($tzil), "Auto svn with web log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( [], '_darcs' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'darcs',
            url  => 'http://example.com/darcs'
        },
        "Auto darcs from default remote"
    );
    ok( !github_deprecated($tzil),
        "Auto darcs from default remote log message" );
}

#---------------------------------------------------------------------
{
    my $url = 'http://example.com/darcs/fromprefs';

    # Munge the Default Remote so it's not http:
    local $result{'darcs query repo'} = $result{'darcs query repo'};
    $result{'darcs query repo'} =~ s!Remote: http!Remote: ssh!;

    my $tzil = build_tzil( [], '_darcs/prefs/repos' => "ssh:foo\n$url\n" );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { type => 'darcs', url => $url },
        "Auto darcs from prefs/repos"
    );
    ok( !github_deprecated($tzil), "Auto darcs from prefs/repos log message" );
}

#---------------------------------------------------------------------
{
    my $tzil = build_tzil( [], '.hg' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { type => 'hg', url => 'https://foobar.googlecode.com/hg/' },
        "Auto hg"
    );
    ok( !github_deprecated($tzil), "Auto hg log message" );
}

#---------------------------------------------------------------------
{
    my $web = 'http://code.google.com/p/foobar/';
    my $tzil = build_tzil( ["web = $web"], '.hg' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        {
            type => 'hg',
            web  => $web,
            url  => 'https://foobar.googlecode.com/hg/'
        },
        "Auto hg with web"
    );
    ok( !github_deprecated($tzil), "Auto hg with web log message" );
}

#---------------------------------------------------------------------
$result{'git remote show -n nourl'} = <<'END GIT NOURL';
* remote nourl
  Fetch URL: origin
  Push  URL: origin
  HEAD branch: (not queried)
  Remote branches: (status not queried)
END GIT NOURL

{
    my $tzil = build_tzil( ['git_remote = nourl'], '.git' );

    is( $tzil->distmeta->{resources}{repository},
        undef, "Auto git remote nourl" );
    ok( !github_deprecated($tzil), "Auto git remote nourl log message" );
}

{
    my $url = 'git://example.com/example.git';
    my $tzil =
      build_tzil( [ 'git_remote = nourl', "repository = $url" ], '.git' );

    is_deeply(
        $tzil->distmeta->{resources}{repository},
        { type => 'git', url => $url },
        "Auto git remote nourl with repository"
    );
    ok( !github_deprecated($tzil),
        "Auto git remote nourl with repository log message" );
}

#---------------------------------------------------------------------
$result{'git remote show -n github'} = <<'END GITHUB REMOTE NOT FOUND';
* remote github
  Fetch URL: github
  Push  URL: github
  HEAD branch: (not queried)
  Remote branches: (status not queried)
END GITHUB REMOTE NOT FOUND

{
    my $tzil = build_tzil( ['git_remote = github'], '.git' );

    is( $tzil->distmeta->{resources}{repository},
        undef, "Auto git remote github not found" );
    ok( remote_not_found($tzil), "Auto git remote github not found" );
}

#---------------------------------------------------------------------
done_testing;
