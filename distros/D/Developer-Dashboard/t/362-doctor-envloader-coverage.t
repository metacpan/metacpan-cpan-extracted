#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# CORE::GLOBAL open override must exist before the modules under test compile.
# Read failures are keyed on exact paths in %FAIL_READ and write failures on
# %FAIL_WRITE so the error branches run deterministically even as root.
our ( %FAIL_READ, %FAIL_WRITE );

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] ) {
            my $write = $_[1] =~ /\A\+?[>]/ ? 1 : 0;
            if ( $write ? $FAIL_WRITE{ $_[2] } : $FAIL_READ{ $_[2] } ) {
                $! = 13;
                return 0;
            }
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::Doctor;
use Developer::Dashboard::EnvLoader;
use Developer::Dashboard::InternalCLI;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

sub write_file {
    my ( $file, $text ) = @_;
    my ( undef, $dir ) = File::Spec->splitpath($file);
    make_path($dir);
    CORE::open( my $fh, '>', $file ) or die "Unable to write $file: $!";
    print {$fh} $text;
    close $fh;
    return $file;
}

# --- EnvLoader ------------------------------------------------------------
{
    my $dir = File::Spec->catdir( $home, 'envcase' );
    make_path($dir);

    no warnings 'once';
    local %ENV = %ENV;
    $ENV{DD_T362_KEEP}  = 'old';
    $ENV{DD_T362_UNSET} = 'present';
    $ENV{DD_T362_UNDEF} = undef;

    # Keys touched only through computed names, so the static assignment scan
    # cannot see them and the %ENV diff has to attribute every change.
    my $file = write_file( File::Spec->catfile( $dir, '.env.pl' ), <<'PERL' );
no warnings;
my ( $fresh, $keep, $unset, $undef ) = map { 'DD_T362_' . $_ } qw(FRESH KEEP UNSET UNDEF);
$ENV{$fresh} = 'new';
$ENV{$keep}  = 'changed';
$ENV{$unset} = undef;
$ENV{$undef} = 'defined-now';
1;
PERL
    my $loaded = Developer::Dashboard::EnvLoader->load_files( files => [$file] );
    is_deeply( $loaded, [$file], 'load_files loads the computed-key .env.pl' );
    is( $ENV{DD_T362_FRESH}, 'new', 'computed new key is set' );

    my $empty = write_file( File::Spec->catfile( $dir, 'empty.txt' ), '' );
    is_deeply( [ Developer::Dashboard::EnvLoader->_env_pl_assigned_keys($dir) ], [], '_env_pl_assigned_keys returns nothing when the source cannot be slurped' );
    is_deeply( [ Developer::Dashboard::EnvLoader->_env_pl_assigned_keys($empty) ], [], '_env_pl_assigned_keys returns nothing for an empty file' );

    my $layers = Developer::Dashboard::EnvLoader->load_skill_cli_layers();
    is_deeply( $layers, [], 'load_skill_cli_layers tolerates a missing skill_layers argument' );
}

# --- Doctor ---------------------------------------------------------------
{
    my $paths  = Developer::Dashboard::PathRegistry->new( home => $home );
    my $doctor = Developer::Dashboard::Doctor->new( paths => $paths );

    my ($helper) = Developer::Dashboard::InternalCLI::helper_names();
    my $staged = write_file( File::Spec->catfile( $home, 'staged-helper' ), 'stale' );
    {
        local $FAIL_READ{$staged} = 1;
        my $ok = eval { $doctor->_helper_issue_for_path( name => $helper, path => $staged ); 1 };
        ok( !$ok && $@ =~ /Unable to read/, '_helper_issue_for_path dies when an existing staged helper cannot be read' );
    }

    my $bashrc = write_file( File::Spec->catfile( $home, '.bashrc' ), <<'BASH' );
case $- in
    *i*) ;;
      *) return;;
esac
eval "$("/opt/bin/dashboard" shell bash)"
BASH
    local $FAIL_WRITE{$bashrc} = 1;
    my $ok = eval { $doctor->_rewrite_bashrc_dashboard_lines($bashrc); 1 };
    ok( !$ok && $@ =~ /Unable to write/, '_rewrite_bashrc_dashboard_lines dies when the bashrc cannot be rewritten' );
}

done_testing;

__END__

=head1 NAME

t/362-doctor-envloader-coverage.t - remaining Doctor and EnvLoader branches

=head1 DESCRIPTION

Covers EnvLoader's .env.pl audit attribution for keys set through computed
names (new, changed, set-to-undef and undef-to-defined), the slurp-failure
return in _env_pl_assigned_keys, and load_skill_cli_layers without a
skill_layers argument. Covers Doctor's unreadable staged helper and unwritable
bashrc failure branches through a CORE::GLOBAL open override.

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It closes the remaining Devel::Cover branch, condition and statement gaps for: remaining Doctor and EnvLoader branches.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate (Problem 20) needs every reachable branch exercised, and these paths were only reachable through failure injection or unusual inputs that the broader tests do not produce.

=head1 WHEN TO USE

Use this file when you change the modules it covers, when a coverage run reports one of their branches or conditions as uncovered, or when you want a focused check before running the full suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/362-doctor-envloader-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release. It is hermetic: it uses temporary directories and a local HOME.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/362-doctor-envloader-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/362-doctor-envloader-coverage.t

Confirm the targeted branches and conditions are reported as covered.

=cut
