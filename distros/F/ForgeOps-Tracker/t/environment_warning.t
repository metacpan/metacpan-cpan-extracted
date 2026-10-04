use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use ForgeOps::Tracker;

# Core modules only, on purpose: this runs on a clean Perl with nothing but TEST_REQUIRES installed.

my $expected = '[ForgeOps] Not sending: this environment is "development", and only production, staging are enabled. '
    . 'Set FORGE_OPS_ENVIRONMENT=production (or add "development" to the enabled environments) to send from here.';

sub warnings_from {
    my ($code) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $code->();
    return \@warnings;
}

my %quiet = (detect_changes => 0, track_performance => 0, track_tracing => 0);

subtest 'warns once, on stderr, when a DSN is set but the environment does not send' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    my $warnings = warnings_from(sub {
        ForgeOps::Tracker::init(%quiet, dsn => 'http://key@127.0.0.1:1/api/v1/events', environment => 'development');
        ForgeOps::Tracker::init(%quiet, dsn => 'http://key@127.0.0.1:1/api/v1/events', environment => 'development');
        ForgeOps::Tracker::report("boom\n");
    });

    is(scalar(@$warnings), 1, 'exactly one warning across two init calls and a report');
    is($warnings->[0], "$expected\n");
};

subtest 'goes through the configured logger instead of warn when there is one' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    my @logged;
    my $warnings = warnings_from(sub {
        ForgeOps::Tracker::init(
            %quiet,
            dsn         => 'http://key@127.0.0.1:1/api/v1/events',
            environment => 'development',
            logger      => sub { push @logged, $_[0] },
        );
    });

    is_deeply(\@logged, [$expected]);
    is_deeply($warnings, []);
};

subtest 'names every enabled environment, sorted' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    my @logged;
    ForgeOps::Tracker::init(
        %quiet,
        dsn                  => 'http://key@127.0.0.1:1/api/v1/events',
        environment          => 'test',
        enabled_environments => { staging => 1, production => 1, qa => 1 },
        logger               => sub { push @logged, $_[0] },
    );

    like($logged[0], qr/this environment is "test", and only production, qa, staging are enabled\./);
    like($logged[0], qr/or add "test" to the enabled environments/);
};

subtest 'never warns without a DSN, or in an environment that sends' => sub {
    ForgeOps::Tracker::_reset_for_testing();
    my $warnings = warnings_from(sub {
        ForgeOps::Tracker::init(%quiet, dsn => undef, environment => 'development');
    });
    is_deeply($warnings, [], 'no DSN');

    for my $environment (qw(production staging)) {
        ForgeOps::Tracker::_reset_for_testing();
        $warnings = warnings_from(sub {
            ForgeOps::Tracker::init(%quiet, dsn => 'http://key@127.0.0.1:1/api/v1/events', environment => $environment);
        });
        is_deeply($warnings, [], $environment);
    }
};

subtest 'the environment is FORGE_OPS_ENVIRONMENT, else production' => sub {
    local $ENV{FORGE_OPS_ENVIRONMENT} = 'staging';
    is(ForgeOps::Tracker::Configuration->new->{environment}, 'staging');

    delete local $ENV{FORGE_OPS_ENVIRONMENT};
    is(ForgeOps::Tracker::Configuration->new->{environment}, 'production');
};

ForgeOps::Tracker::_reset_for_testing();
done_testing;
