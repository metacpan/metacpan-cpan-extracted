#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

eval "use Test::Spelling 0.20; 1"
    or plan skip_all => 'Test::Spelling 0.20 required';

# Project-specific terms that aren't in any dictionary
add_stopwords(qw(
    Async EV NOSPACE READWRITE
    async backoff defragment reconnection ttl txn
    etcd gRPC libev libgrpc protobuf-c protobuf
    XS pthread typemap
    auth backend cancellable cluster_id codepoints compact_revision
    cpantesters dbsize Defragment Defragmentation deserialize
    endpoint endpoints failover
    hashref hashrefs IDs ipv4 keepalive keepalives kv kvs
    learner linearizable longjmp memberid mTLS mvccpb
    namespace observe param params pre prev_kv prev_kvs proclaim
    progress_notify protobufs raft RPC RPCs runtime serializable
    serialize Sub-packages subkey subprocess SvUTF8 sync TLS TTL
    UTF UV-cant userland vmactions watch_id YK
    Yegor Korablev vividsnow
));

all_pod_files_spelling_ok();
