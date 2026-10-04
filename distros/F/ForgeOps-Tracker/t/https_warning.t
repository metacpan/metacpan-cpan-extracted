use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use HTTP::Tiny;
use ForgeOps::Tracker;

# Core modules only, on purpose: this runs on a clean Perl with nothing but TEST_REQUIRES installed.

my $expected = q{[ForgeOps] Not sending: the DSN is https, and this perl can't make https requests. }
    . q{Install IO::Socket::SSL and Net::SSLeay (cpanm IO::Socket::SSL Net::SSLeay) to send.};

sub warnings_from {
    my ($code) = @_;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $code->();
    return \@warnings;
}

my %quiet = (detect_changes => 0, track_performance => 0, track_tracing => 0);

subtest 'warns once when the DSN is https and this perl cannot make https requests' => sub {
    no warnings 'redefine';
    local *HTTP::Tiny::can_ssl = sub { return wantarray ? (0, 'IO::Socket::SSL is not installed') : 0 };
    ForgeOps::Tracker::_reset_for_testing();
    my $warnings = warnings_from(sub {
        ForgeOps::Tracker::init(%quiet, dsn => 'https://key@forgeops.invalid/api/v1/events');
        ForgeOps::Tracker::init(%quiet, dsn => 'https://key@forgeops.invalid/api/v1/events');
    });

    is_deeply($warnings, ["$expected\n"], 'exactly one warning across two init calls');
};

subtest 'goes through the configured logger instead of warn when there is one' => sub {
    no warnings 'redefine';
    local *HTTP::Tiny::can_ssl = sub { return 0 };
    ForgeOps::Tracker::_reset_for_testing();
    my @logged;
    my $warnings = warnings_from(sub {
        ForgeOps::Tracker::init(%quiet, dsn => 'https://key@forgeops.invalid/api/v1/events', logger => sub { push @logged, $_[0] });
    });

    is_deeply(\@logged, [$expected]);
    is_deeply($warnings, []);
};

subtest 'says nothing when https works, for an http DSN, or without a DSN' => sub {
    no warnings 'redefine';
    {
        local *HTTP::Tiny::can_ssl = sub { return 1 };
        ForgeOps::Tracker::_reset_for_testing();
        is_deeply(warnings_from(sub { ForgeOps::Tracker::init(%quiet, dsn => 'https://key@forgeops.invalid/api/v1/events') }), []);
    }
    local *HTTP::Tiny::can_ssl = sub { return 0 };
    ForgeOps::Tracker::_reset_for_testing();
    is_deeply(warnings_from(sub { ForgeOps::Tracker::init(%quiet, dsn => 'http://key@127.0.0.1:1/api/v1/events') }), []);
    local $ENV{FORGE_OPS_DSN};
    ForgeOps::Tracker::_reset_for_testing();
    is_deeply(warnings_from(sub { ForgeOps::Tracker::init(%quiet) }), []);
};

done_testing;
