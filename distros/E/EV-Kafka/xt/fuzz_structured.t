use strict;
use warnings;
use Test::More;
use EV::Kafka;

# Structured/mutation parser fuzzing. xt/fuzz_decode.t feeds UNIFORM
# RANDOM bytes to the parsers — that can never build a valid response
# envelope around a poisoned length field, which is exactly why the
# fetch-response int32 overflow (batch_length 0x7FFFFFF9, a one-packet
# remote segfault) survived it at 20k iterations.
#
# Here we build VALID response envelopes (same byte-builder style as the
# t/18/t/21 goldens), record the offset of every length/count/varint
# field while building, then splice hostile values into those fields:
# negative, 0, INT32_MAX, INT32_MIN, off-by-one vs the remaining byte
# count, and huge/overlong uvarints. The parser must return undef or a
# hashref (arrayref for the batch decoder) and never crash, panic, or
# die.

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};

my $iters = $ENV{FUZZ_ITERS} || 2_000;
plan tests => 11;

sub i16 { pack 'n',  $_[0] }
sub i32 { pack 'N',  $_[0] }
sub i64 { pack 'q>', $_[0] }
sub kstr { my $s = shift; i16(length $s) . $s }

# --- Template builders ---------------------------------------------------
# Each returns ($bytes, \@sites) where a site is [offset, kind, width]:
# kind 'i32'/'i16' overwrite in place, kind 'uvar' splices width bytes.

# Metadata v1: brokers, topics, partitions, replica/isr arrays.
sub tpl_metadata_v1 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), $_[0], $_[1]] };
    $at->('i32', 4); $b .= i32(1);                 # brokers count
    $b .= i32(0);                                  # node_id
    $at->('i16', 2); $b .= kstr('host1');          # host
    $b .= i32(9092);                               # port
    $at->('i16', 2); $b .= i16(-1);                # rack: null
    $b .= i32(0);                                  # controller_id
    $at->('i32', 4); $b .= i32(1);                 # topics count
    $b .= i16(0);                                  # topic error
    $at->('i16', 2); $b .= kstr('t1');             # topic name
    $b .= chr(0);                                  # is_internal
    $at->('i32', 4); $b .= i32(1);                 # partitions count
    $b .= i16(0) . i32(0) . i32(0);                # err, pid, leader
    $at->('i32', 4); $b .= i32(1) . i32(0);        # replicas: [0]
    $at->('i32', 4); $b .= i32(1) . i32(0);        # isr: [0]
    return ($b, \@sites);
}

# Metadata v9 (flexible): compact arrays/strings — uvarint length fields.
sub tpl_metadata_v9 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), 'uvar', $_[0]] };
    $b .= i32(0);                                  # throttle
    $at->(1); $b .= "\x02";                        # brokers: 1
    $b .= i32(0);                                  # node_id
    $at->(1); $b .= "\x06" . 'host1';              # host: compact
    $b .= i32(9092);                               # port
    $at->(1); $b .= "\x00";                        # rack: null
    $b .= "\x00";                                  # tagged fields
    $at->(1); $b .= "\x00";                        # cluster_id: null
    $b .= i32(0);                                  # controller_id
    $at->(1); $b .= "\x01";                        # topics: 0
    $b .= "\x00";                                  # tagged fields
    return ($b, \@sites);
}

# Produce v7.
sub tpl_produce_v7 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), $_[0], $_[1]] };
    $at->('i32', 4); $b .= i32(1);                 # topics count
    $at->('i16', 2); $b .= kstr('t1');
    $at->('i32', 4); $b .= i32(1);                 # partitions count
    $b .= i32(0) . i16(0) . i64(42) . i64(-1) . i64(0);
    $b .= i32(0);                                  # throttle
    return ($b, \@sites);
}

# Fetch v4 with one real record batch in the record set.
sub tpl_fetch_v4 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), $_[0], $_[1]] };
    my $batch = EV::Kafka::_test_encode_batch([{ key => 'k', value => 'v' }]);
    $b .= i32(0);                                  # throttle
    $at->('i32', 4); $b .= i32(1);                 # responses count
    $at->('i16', 2); $b .= kstr('t1');
    $at->('i32', 4); $b .= i32(1);                 # partitions count
    $b .= i32(0) . i16(0) . i64(1);                # pid, err, high_watermark
    $b .= i64(1);                                  # last_stable_offset
    $at->('i32', 4); $b .= i32(-1);                # aborted_txns: null
    $at->('i32', 4); $b .= i32(length $batch);     # record_set BYTES
    $b .= $batch;
    return ($b, \@sites);
}

# Fetch v7: adds error_code/session_id and log_start_offset.
sub tpl_fetch_v7 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), $_[0], $_[1]] };
    my $batch = EV::Kafka::_test_encode_batch([{ key => 'k', value => 'v' }]);
    $b .= i32(0);                                  # throttle
    $b .= i16(0) . i32(0);                         # error_code, session_id
    $at->('i32', 4); $b .= i32(1);                 # responses count
    $at->('i16', 2); $b .= kstr('t1');
    $at->('i32', 4); $b .= i32(1);                 # partitions count
    $b .= i32(0) . i16(0) . i64(1);                # pid, err, high_watermark
    $b .= i64(1);                                  # last_stable_offset
    $b .= i64(0);                                  # log_start_offset
    $at->('i32', 4); $b .= i32(-1);                # aborted_txns: null
    $at->('i32', 4); $b .= i32(length $batch);     # record_set BYTES
    $b .= $batch;
    return ($b, \@sites);
}

# ListOffsets v1.
sub tpl_list_offsets_v1 {
    my @sites;
    my $b = '';
    my $at = sub { push @sites, [length($b), $_[0], $_[1]] };
    $at->('i32', 4); $b .= i32(1);                 # topics count
    $at->('i16', 2); $b .= kstr('t1');
    $at->('i32', 4); $b .= i32(1);                 # partitions count
    $b .= i32(0) . i16(0) . i64(-1) . i64(7);
    return ($b, \@sites);
}

# Record batch with sites at every length-bearing field. Sites inside the
# CRC-covered region (offset 21+) are marked crc => 1; mutating them
# requires a CRC fixup or the decoder rejects the batch unread.
sub tpl_batch {
    my $b = EV::Kafka::_test_encode_batch([{ key => 'k', value => 'v' }]);
    my @sites = ([8, 'i32', 4, 0, 'batch_len']);   # batch_length (no CRC)
    push @sites, [57, 'i32', 4, 1, 'record_count'];
    # Walk the one record's varint fields to find their offsets.
    my $pos = 61;
    my $uvar = sub {
        my $start = $pos;
        $pos++;
        $pos++ while ($pos - $start < 10) && (ord(substr($b, $pos - 1, 1)) & 0x80);
        return ($start, $pos - $start);
    };
    for my $f (qw(record_len ts_delta off_delta key_len)) {
        my ($off, $w) = $uvar->();
        push @sites, [$off, 'uvar', $w, 1, $f];
        $pos += 1 if $f eq 'record_len';           # attributes i8 follows
    }
    $pos += 1;                                     # key 'k'
    my ($off, $w) = $uvar->();                     # value_len
    push @sites, [$off, 'uvar', $w, 1, 'value_len'];
    $pos += 1;                                     # value 'v'
    ($off, $w) = $uvar->();                        # headers count
    push @sites, [$off, 'uvar', $w, 1, 'hdr_count'];
    die "template walk overran batch" unless $pos == length $b;
    return ($b, \@sites);
}

# --- Hostile values --------------------------------------------------------

sub hostile_i32 {
    my ($len, $off) = @_;
    my $rem = $len - $off - 4;
    map { pack 'l>', $_ }
        (-1, 0, 1, 2**31 - 1, -2**31, 0x7FFFFFF9,
         $rem - 1, $rem, $rem + 1, $len - 1, $len, $len + 1);
}

sub hostile_i16 {
    my ($len, $off) = @_;
    my $rem = $len - $off - 2;
    map { pack 's>', $_ }
        (-1, 0, 1, 32767, -32768, $rem - 1, $rem, $rem + 1, $len - 1, $len + 1);
}

my @HOSTILE_UVAR = (
    "\x00",                                        # 0 (null/-1 for compact)
    "\x01", "\x02", "\x7F",
    "\x80\x01",                                    # 128
    "\xFF\xFF\xFF\xFF\x07",                        # 2^31-1
    "\x80\x80\x80\x80\x08",                        # 2^31
    "\xFF\xFF\xFF\xFF\x0F",                        # 2^32-1
    "\x80\x80\x80\x80\x10",                        # 2^32
    "\x81\x80\x80\x80\x08",                        # wraps to INT32_MIN len
    "\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x01",    # 2^63-1
    "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7F",# overlong (11 bytes)
);

sub fix_crc {
    my ($b) = @_;
    substr($b, 17, 4) = pack 'N', EV::Kafka::_crc32c(substr($b, 21));
    return $b;
}

# Mutate $bytes at $site with $value (byte string; uvar splices).
sub mutate_at {
    my ($bytes, $site, $value) = @_;
    my ($off, $kind, $width) = @$site;
    substr($bytes, $off, $kind eq 'uvar' ? $width : length $value) = $value;
    return $bytes;
}

my ($checked, $bad) = (0, 0);
sub run_parse {
    my ($desc, $api, $ver, $bytes) = @_;
    $checked++;
    my $r = eval { EV::Kafka::_test_parse_response($api, $ver, $bytes) };
    if ($@) { $bad++; diag "DIE $desc: $@"; return; }
    if (defined $r && ref $r ne 'HASH') {
        $bad++; diag "NON-HASH $desc: " . ref $r;
    }
}
sub run_batch {
    my ($desc, $bytes) = @_;
    $checked++;
    my $r = eval { EV::Kafka::_test_decode_batch($bytes) };
    if ($@) { $bad++; diag "DIE $desc: $@"; return; }
    if (defined $r && ref $r ne 'ARRAY') {
        $bad++; diag "NON-ARRAY $desc: " . ref $r;
    }
}

my @TPL = (
    ['metadata v1',     'metadata',     1, \&tpl_metadata_v1],
    ['metadata v9',     'metadata',     9, \&tpl_metadata_v9],
    ['produce v7',      'produce',      7, \&tpl_produce_v7],
    ['fetch v4',        'fetch',        4, \&tpl_fetch_v4],
    ['fetch v7',        'fetch',        7, \&tpl_fetch_v7],
    ['list_offsets v1', 'list_offsets', 1, \&tpl_list_offsets_v1],
);

# --- Templates must be valid, else the whole exercise is vacuous ---------
{
    my ($bytes) = tpl_metadata_v1();
    my $r = EV::Kafka::_test_parse_response('metadata', 1, $bytes);
    ok((ref $r eq 'HASH') && @{$r->{brokers}} == 1 && @{$r->{topics}} == 1,
        'template metadata v1 parses to expected structure');
}
{
    my ($bytes) = tpl_metadata_v9();
    my $r = EV::Kafka::_test_parse_response('metadata', 9, $bytes);
    ok((ref $r eq 'HASH') && @{$r->{brokers}} == 1
        && $r->{brokers}[0]{host} eq 'host1',
        'template metadata v9 parses to expected structure');
}
{
    my ($bytes) = tpl_produce_v7();
    my $r = EV::Kafka::_test_parse_response('produce', 7, $bytes);
    ok((ref $r eq 'HASH')
        && $r->{topics}[0]{partitions}[0]{base_offset} == 42,
        'template produce v7 parses to expected structure');
}
{
    my ($bytes) = tpl_fetch_v4();
    my $r = EV::Kafka::_test_parse_response('fetch', 4, $bytes);
    my $recs = (ref $r eq 'HASH') ? $r->{topics}[0]{partitions}[0]{records} : undef;
    ok((ref $recs eq 'ARRAY') && @$recs == 1 && $recs->[0]{key} eq 'k',
        'template fetch v4 parses, record batch decoded');
}
{
    my ($bytes) = tpl_fetch_v7();
    my $r = EV::Kafka::_test_parse_response('fetch', 7, $bytes);
    my $recs = (ref $r eq 'HASH') ? $r->{topics}[0]{partitions}[0]{records} : undef;
    ok((ref $recs eq 'ARRAY') && @$recs == 1 && $recs->[0]{value} eq 'v',
        'template fetch v7 parses, record batch decoded');
}
{
    my ($bytes) = tpl_list_offsets_v1();
    my $r = EV::Kafka::_test_parse_response('list_offsets', 1, $bytes);
    ok((ref $r eq 'HASH')
        && $r->{topics}[0]{partitions}[0]{offset} == 7,
        'template list_offsets v1 parses to expected structure');
}
{
    my ($bytes) = tpl_batch();
    my $r = EV::Kafka::_test_decode_batch($bytes);
    ok((ref $r eq 'ARRAY') && @$r == 1 && $r->[0]{key} eq 'k',
        'template record batch decodes');
}

# --- Phase 1: deterministic hostile-field matrix, response parsers --------
($checked, $bad) = (0, 0);
for my $tpl (@TPL) {
    my ($name, $api, $ver, $build) = @$tpl;
    my ($bytes, $sites) = $build->();
    for my $site (@$sites) {
        my ($off, $kind) = @$site;
        my @values = $kind eq 'i32' ? hostile_i32(length $bytes, $off)
                   : $kind eq 'i16' ? hostile_i16(length $bytes, $off)
                   : @HOSTILE_UVAR;
        for my $v (@values) {
            run_parse("$name site\@$off", $api, $ver,
                      mutate_at($bytes, $site, $v));
        }
    }
}
ok(!$bad, "phase 1: $checked deterministic hostile-field response parses survived");

# --- Phase 2: deterministic hostile-field matrix, record-batch decoder ----
($checked, $bad) = (0, 0);
{
    my ($bytes, $sites) = tpl_batch();
    for my $site (@$sites) {
        my ($off, $kind, $width, $crc, $fname) = @$site;
        my @values = $kind eq 'i32' ? hostile_i32(length $bytes, $off)
                   : @HOSTILE_UVAR;
        for my $v (@values) {
            my $mut = mutate_at($bytes, $site, $v);
            $mut = fix_crc($mut) if $crc;
            run_batch("batch $fname\@$off", $mut);
        }
    }
}
ok(!$bad, "phase 2: $checked deterministic hostile-field batch decodes survived");

# --- Phase 3: random structured mutations, response envelopes -------------
($checked, $bad) = (0, 0);
srand 42;
for my $i (1 .. $iters) {
    my $tpl = $TPL[int(rand(scalar @TPL))];
    my ($name, $api, $ver, $build) = @$tpl;
    my ($bytes, $sites) = $build->();
    for (1 .. 1 + int(rand(3))) {
        my $site = $sites->[int(rand(scalar @$sites))];
        my ($off, $kind) = @$site;
        my $v;
        my $r = rand();
        if ($kind eq 'uvar') {
            $v = $HOSTILE_UVAR[int(rand(scalar @HOSTILE_UVAR))];
        } elsif ($r < 0.7) {
            my @hv = $kind eq 'i32' ? hostile_i32(length $bytes, $off)
                                    : hostile_i16(length $bytes, $off);
            $v = $hv[int(rand(scalar @hv))];
        } else {
            $v = join '', map { chr(int(rand(256))) } 1 .. ($kind eq 'i32' ? 4 : 2);
        }
        $bytes = mutate_at($bytes, $site, $v);
    }
    if (rand() < 0.2 && length $bytes) {           # truncate somewhere
        substr($bytes, int(rand(length $bytes))) = '';
    }
    run_parse("$name mut#$i", $api, $ver, $bytes);
}
ok(!$bad, "phase 3: $checked random structured envelope mutations survived");

# --- Phase 4: random structured mutations, record batches ------------------
($checked, $bad) = (0, 0);
for my $i (1 .. $iters) {
    my ($bytes, $sites) = tpl_batch();
    my $need_crc = 0;
    for (1 .. 1 + int(rand(3))) {
        my $site = $sites->[int(rand(scalar @$sites))];
        my ($off, $kind, undef, $crc) = @$site;
        my $v;
        if ($kind eq 'uvar') {
            $v = $HOSTILE_UVAR[int(rand(scalar @HOSTILE_UVAR))];
        } elsif (rand() < 0.7) {
            my @hv = hostile_i32(length $bytes, $off);
            $v = $hv[int(rand(scalar @hv))];
        } else {
            $v = join '', map { chr(int(rand(256))) } 1 .. 4;
        }
        $bytes = mutate_at($bytes, $site, $v);
        $need_crc ||= $crc;
    }
    if (rand() < 0.3) {                            # raw byte corruption, too
        substr($bytes, int(rand(length $bytes)), 1) = chr(int(rand(256)));
        $need_crc = 1;
    }
    $bytes = fix_crc($bytes) if $need_crc && rand() < 0.8;
    run_batch("batch mut#$i", $bytes);
}
ok(!$bad, "phase 4: $checked random structured batch mutations survived");
