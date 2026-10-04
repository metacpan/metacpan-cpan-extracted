#!/usr/bin/env perl

use strict;
use warnings;

# Directories whose opendir should fail even for a privileged user, so the
# "Unable to read" branches can be driven hermetically.
our %FAIL_OPENDIR;

BEGIN {
    no warnings 'once';
    *CORE::GLOBAL::opendir = sub (*$) {
        if ( defined $_[1] && exists $FAIL_OPENDIR{ $_[1] } ) {
            $! = 13;
            return 0;
        }
        return CORE::opendir( $_[0], $_[1] );
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::CLI::Suggest;

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home, workspace_roots => [], project_roots => [] );
my $suggest = Developer::Dashboard::CLI::Suggest->new( paths => $paths );

subtest 'unreadable top-level cli root is reported' => sub {
    my ($root) = grep { -d $_ } $paths->cli_roots;
    if ( !$root ) {
        $root = File::Spec->catdir( $home, '.developer-dashboard', 'cli' );
        make_path($root);
    }
    local $FAIL_OPENDIR{$root} = 1;
    my $err = eval { $suggest->_top_level_candidates; 1 } ? '' : $@;
    like( $err, qr/Unable to read \Q$root\E/, 'top-level candidate scan reports the unreadable root' );
};

subtest 'unreadable skill cli and nested skills directories are reported' => sub {
    my $skill = File::Spec->catdir( $home, 'skill-fixture' );
    my $cli    = File::Spec->catdir( $skill, 'cli' );
    my $nested = File::Spec->catdir( $skill, 'skills' );
    make_path( $cli, $nested );

    {
        local $FAIL_OPENDIR{$cli} = 1;
        my $err = eval { $suggest->_collect_skill_commands( $skill, 'fixture' ); 1 } ? '' : $@;
        like( $err, qr/Unable to read \Q$cli\E/, 'unreadable skill cli dir is reported' );
    }
    {
        local $FAIL_OPENDIR{$nested} = 1;
        my $err = eval { $suggest->_collect_skill_commands( $skill, 'fixture' ); 1 } ? '' : $@;
        like( $err, qr/Unable to read \Q$nested\E/, 'unreadable nested skills dir is reported' );
    }
};

is_deeply( \@warnings, [], 'no warnings escaped' );

done_testing;

__END__

=pod

=head1 NAME

t/303-cli-suggest-full-coverage.t - unreadable-directory branch coverage for CLI::Suggest

=head1 DESCRIPTION

Covers the three opendir failure branches in L<Developer::Dashboard::CLI::Suggest>
through an C<opendir> override so they fail for privileged users as well.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: unreadable-directory branch coverage for CLI::Suggest.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/303-cli-suggest-full-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/303-cli-suggest-full-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/303-cli-suggest-full-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
