#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::opendir override must exist before the module under test is
# compiled. It fails only for exact registered paths, so the failure runs for any
# uid, including root where a chmod-based denial would still succeed.
our %FAIL;

BEGIN {
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && $FAIL{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
}

use Test::More;
use Capture::Tiny qw(capture);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Collector;
use Developer::Dashboard::CollectorRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::UpdateManager;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths     = Developer::Dashboard::PathRegistry->new( home => $home );
my $files     = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config    = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $collector = Developer::Dashboard::Collector->new( paths => $paths );
my $runner    = Developer::Dashboard::CollectorRunner->new( collectors => $collector, files => $files, paths => $paths );
my $updater   = Developer::Dashboard::UpdateManager->new( config => $config, files => $files, paths => $paths, runner => $runner );

my $dir = $updater->updates_dir;
make_path($dir);

{
    no warnings 'redefine';
    local *Developer::Dashboard::UpdateManager::_running_collectors = sub { return () };
    local *Developer::Dashboard::UpdateManager::_stop_collectors    = sub { return };

    my $quiet = File::Spec->catfile( $dir, '01-quiet' );
    open my $fh, '>', $quiet or die "Unable to write $quiet: $!";
    print {$fh} "#!/bin/sh\nexit 0\n";
    close $fh or die "Unable to close $quiet: $!";
    chmod 0755, $quiet or die "Unable to chmod $quiet: $!";

    my $loud = File::Spec->catfile( $dir, '02-loud' );
    open $fh, '>', $loud or die "Unable to write $loud: $!";
    print {$fh} "#!/bin/sh\necho hello-update\n";
    close $fh or die "Unable to close $loud: $!";
    chmod 0755, $loud or die "Unable to chmod $loud: $!";

    my $results;
    my ( $stdout ) = capture { $results = $updater->run };
    is( scalar @{$results}, 2, 'both update scripts ran' );
    is( $results->[0]{output}, '', 'a silent script reports empty output' );
    like( $results->[1]{output}, qr/hello-update/, 'a noisy script reports its output' );
    like( $stdout, qr/hello-update/, 'noisy output is echoed' );

    local $FAIL{$dir} = 1;
    my $ok = eval { capture { $updater->run }; 1 };
    ok( !$ok, 'an unreadable updates directory is fatal' );
    like( $@, qr/Unable to open updates directory \Q$dir\E/, 'the failure names the updates directory' );
}

done_testing;

__END__

=pod

=head1 NAME

t/593-updatemanager-coverage.t - covers the opendir failure and silent-output branches of Developer::Dashboard::UpdateManager

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the opendir failure on a real updates directory and runs a silent update script.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotation, and these paths can only be reached by injecting failures that work for any uid, including root.

=head1 WHEN TO USE

Use this file when you change Developer::Dashboard::UpdateManager, or when a coverage run reports one of these paths as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/593-updatemanager-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/593-updatemanager-coverage.t

Run this coverage-gap test by itself while editing Developer::Dashboard::UpdateManager.

=cut
