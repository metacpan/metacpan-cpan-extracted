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

# Internal helpers + short-name aliases that are documented in-line under
# the canonical method.
my %internal = map { $_ => 1 } qw(
    HAS_TLS HAS_NKEY CLONE_SKIP
    pub hpub sub unsub req hreq
    timer watch_disconnect unwatch_disconnect is_subscribed
    json_api decoded later fail_later err_status with_timeout subjects_under
    all_pages offset_pages create_bucket_stream put_subject
    noting_direct get_msg get_msg_using decode_json_or_error msg_is_tombstone
    reply_of ack_reply
    subject expect_publish tombstone
    purge_best_effort purge_each put_chunks fetch_chunks digest_ok raw_meta meta_at
    nuid b64url b64url_dec
    encode_name encode_name_legacy decode_name_legacy decode_name_best meta_name
);

plan tests => 2 * scalar @pms;

for my $pm (@pms) {
    pod_file_ok(pm_path($pm), "$pm: POD parses");
    pod_coverage_ok(
        $pm,
        { also_private => [ map { qr/^\Q$_\E$/ } keys %internal ] },
        "$pm: POD covers public methods",
    );
}

sub pm_path {
    my $pm = shift;
    $pm =~ s{::}{/}g;
    "lib/$pm.pm";
}
