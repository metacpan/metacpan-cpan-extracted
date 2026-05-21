use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING to run' unless $ENV{RELEASE_TESTING};

eval { require Test::Pod; Test::Pod->VERSION(1.22) }
    or plan skip_all => 'Test::Pod 1.22+ required';
eval { require Test::Pod::Coverage; Test::Pod::Coverage->VERSION(1.08) }
    or plan skip_all => 'Test::Pod::Coverage 1.08+ required';

Test::Pod->import;
Test::Pod::Coverage->import;

my @pms = qw(
    EV::Nats
    EV::Nats::JetStream
    EV::Nats::KV
    EV::Nats::ObjectStore
);

# Sibling-module-only / internal helpers + short-name aliases that are
# documented in-line under the canonical method.
my %internal = map { $_ => 1 } qw(
    decode_json_or_error
    msg_is_tombstone
    HAS_TLS
    HAS_NKEY
    pub
    hpub
    sub
    unsub
    req
);

plan tests => 2 * scalar @pms;

for my $pm (@pms) {
    pod_file_ok(_pm_path($pm), "$pm: POD parses");
    pod_coverage_ok(
        $pm,
        { also_private => [ map { qr/^\Q$_\E$/ } keys %internal ] },
        "$pm: POD covers public methods",
    );
}

sub _pm_path {
    my $pm = shift;
    $pm =~ s{::}{/}g;
    "lib/$pm.pm";
}
