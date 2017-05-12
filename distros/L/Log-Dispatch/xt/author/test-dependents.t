use strict;
use warnings;

use Cwd qw( abs_path );
use Test::More;

# You'd think Test::Needs would be good enough here but it'll bail out under
# RELEASE_TESTING if the needed module can't be loaded.
BEGIN {
    if ( $] < 5.010 ) {
        plan skip_all =>
            'Test::DependentModules cannot be loaded on Perl 5.8.x';
    }
}

use Test::Needs { 'Test::DependentModules' => '0.22' };

use Test::DependentModules 0.22 qw( test_all_dependents );

plan skip_all =>
    'Must set LOG_DISPATCH_TEST_DEPS to true in order to run these tests'
    unless $ENV{LOG_DISPATCH_TEST_DEPS};

local $ENV{PERL_TEST_DM_LOG_DIR} = abs_path('.');

my %known_failures = map { $_ => 1 } (
    'Log-Dispatch-FileRotate',       # Prints out broken TAP
    'Log-Dispatch-Gtk2-Notify',      # requires Gtk2
    'Log-Dispatch-MacGrowl',         # Mac only
    'Log-Dispatch-Scribe',           # fails its pod coverage test
    'Log-Dispatch-Tk',               # doesn't seem to actually exist on CPAN
    'Log-Dispatch-Win32EventLog',    # Win32 only
    'Log-Dispatch-Wx',               # requires wx
    'Log-Dispatch-XML',    # depends on non-existent Log::Dispatch::Buffer
    'Log-Dispatch-ZMQ',    # requires libzeromq and other deps
);

test_all_dependents(
    'Log::Dispatch',
    {
        filter => sub {
            my $dist = shift;
            return 0 unless $dist eq 'Dist-Zilla' || $dist =~ /^Log-Dispatch/;
            return !$known_failures{$dist};
        }
    },
);
