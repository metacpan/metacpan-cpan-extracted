package GunghoTest;
use strict;
use Test::More();

sub plan_or_skip
{
    my $class = shift;
    my %args  = @_;

    if ($args{requires}) {
        eval "use $args{requires}";
        if ($@) {
            Test::More::plan(skip_all => "$args{requires} not available");
            return;
        }
    }
    if ($args{check_env}) {
        my @env = ref($args{check_env}) eq 'ARRAY' ? @{ $args{check_env} } : ($args{check_env});
        foreach my $env (@env) {
            my $v = $ENV{ $env };
            if (! defined $v || length $v < 1) {
                Test::More::plan(skip_all => "Environment variable $env is not specified");
            }
        }
    }

    Test::More::plan(tests => $args{test_count});
    return 1;
}

# Check if we have at least one of the engines available
# (We don't count this as a test failure so to silence automated
# CPAN tests)
sub assert_engine
{
    my %have_engine;
    foreach my $engine qw(POE Danga::Socket IO::Async) {
        $have_engine{ $engine } = do {
            eval "use Gungho::Engine::$engine";
            $@ ? 0 : 1;
        };
    }

    if (! scalar grep { $_ } values %have_engine ) {
        print STDERR <<"        EOM";

================================!!! WARNING !!!================================
No engine modules could be loaded. 

The test suite may pass as it is, but Gungho will be useless unless at least
one engine is available
================================!!! WARNING !!!================================
        EOM
        return 0;
    }
    return 1;
}

1;
