######################################################################
#
# 0009-concurrent-fh.t
# Verify that multiple From* iterators can be open simultaneously
# without IO slot collision (Join, GroupJoin, Concat+Join, To* round-trip).
#
######################################################################

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin ();
use lib "$FindBin::Bin/../lib";
use JSON::LINQ;

my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok {
    my($cond, $name) = @_;
    $T++;
    if ($cond) { $PASS++; print "ok $T - $name\n" }
    else       { $FAIL++; print "not ok $T - $name\n" }
}
sub is {
    my($got, $exp, $name) = @_;
    my $ok = defined $got && defined $exp && "$got" eq "$exp";
    $T++;
    if ($ok) { $PASS++; print "ok $T - $name\n" }
    else {
        $FAIL++;
        my $g = defined $got ? $got : '(undef)';
        my $e = defined $exp ? $exp : '(undef)';
        print "not ok $T - $name\n";
        print "#   got:      $g\n#   expected: $e\n";
    }
}

# Temp file helper - use t/ directory (portable: no /tmp on Windows)
my $TDIR = $FindBin::Bin;
my @tmpfiles;
sub make_jsonl {
    my($suffix, @lines) = @_;
    my $f = "$TDIR/cfh_${suffix}_$$.jsonl";
    push @tmpfiles, $f;
    local *TF;
    open(TF, ">$f") or die "Cannot create $f: $!";
    binmode TF;
    for my $line (@lines) { print TF $line, "\n" }
    close TF;
    return $f;
}
sub make_ltsv {
    my($suffix, @lines) = @_;
    my $f = "$TDIR/cfh_${suffix}_$$.ltsv";
    push @tmpfiles, $f;
    local *TF;
    open(TF, ">$f") or die "Cannot create $f: $!";
    binmode TF;
    for my $line (@lines) { print TF $line, "\n" }
    close TF;
    return $f;
}
sub make_json {
    my($suffix, $content) = @_;
    my $f = "$TDIR/cfh_${suffix}_$$.json";
    push @tmpfiles, $f;
    local *TF;
    open(TF, ">$f") or die "Cannot create $f: $!";
    binmode TF;
    print TF $content;
    close TF;
    return $f;
}

# ----------------------------------------------------------------------
# Test data
# ----------------------------------------------------------------------

# employees.jsonl (outer)
my $emp_jsonl = make_jsonl('emp',
    '{"id":1,"name":"Alice","dept_id":10}',
    '{"id":2,"name":"Bob","dept_id":20}',
    '{"id":3,"name":"Carol","dept_id":10}',
);

# departments.jsonl (inner for Join)
my $dep_jsonl = make_jsonl('dep',
    '{"dept_id":10,"dept":"Engineering"}',
    '{"dept_id":20,"dept":"Sales"}',
    '{"dept_id":30,"dept":"HR"}',
);

# departments.ltsv (inner for Join via FromLTSV)
my $dep_ltsv = make_ltsv('dep',
    "dept_id:10\tdept:Engineering",
    "dept_id:20\tdept:Sales",
    "dept_id:30\tdept:HR",
);

# departments.json (inner for Join via FromJSON)
my $dep_json = make_json('dep',
    '[{"dept_id":10,"dept":"Engineering"},{"dept_id":20,"dept":"Sales"},{"dept_id":30,"dept":"HR"}]'
);

# scores.jsonl (outer for GroupJoin)
my $scores_jsonl = make_jsonl('scores',
    '{"name":"Alice","score":90}',
    '{"name":"Alice","score":85}',
    '{"name":"Bob","score":70}',
);

# players.jsonl (outer for GroupJoin)
my $players_jsonl = make_jsonl('players',
    '{"name":"Alice"}',
    '{"name":"Bob"}',
    '{"name":"Carol"}',
);

# extra.jsonl for Concat+Join test
my $extra_jsonl = make_jsonl('extra',
    '{"id":4,"name":"Dave","dept_id":20}',
    '{"id":5,"name":"Eve","dept_id":10}',
);

# ----------------------------------------------------------------------
# Tests
# ----------------------------------------------------------------------

my @tests = (

    # ------------------------------------------------------------------
    # 1. Join: FromJSONL (outer) x FromJSONL (inner) - both open concurrently
    # ------------------------------------------------------------------

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        is(scalar(@rows), 3, 'Join JSONL x JSONL: row count');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my @names = sort map { $_->{name} } @rows;
        is(join(',', @names), 'Alice,Bob,Carol', 'Join JSONL x JSONL: names');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my %d = map { $_->{name} => $_->{dept} } @rows;
        is($d{Alice}, 'Engineering', 'Join JSONL x JSONL: Alice->Engineering');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my %d = map { $_->{name} => $_->{dept} } @rows;
        is($d{Bob}, 'Sales', 'Join JSONL x JSONL: Bob->Sales');
    },

    # ------------------------------------------------------------------
    # 2. Join: FromJSONL (outer) x FromLTSV (inner) - different From* types
    # ------------------------------------------------------------------

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromLTSV($dep_ltsv),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        is(scalar(@rows), 3, 'Join JSONL x LTSV: row count');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromLTSV($dep_ltsv),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my %d = map { $_->{name} => $_->{dept} } @rows;
        is($d{Carol}, 'Engineering', 'Join JSONL x LTSV: Carol->Engineering');
    },

    # ------------------------------------------------------------------
    # 3. Join: FromJSONL (outer) x FromJSON (inner)
    # ------------------------------------------------------------------

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSON($dep_json),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        is(scalar(@rows), 3, 'Join JSONL x JSON: row count');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSON($dep_json),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my %d = map { $_->{name} => $_->{dept} } @rows;
        is($d{Alice}, 'Engineering', 'Join JSONL x JSON: Alice->Engineering');
    },

    # ------------------------------------------------------------------
    # 4. GroupJoin: FromJSONL (outer) x FromJSONL (inner)
    # ------------------------------------------------------------------

    sub {
        my @rows = JSON::LINQ->FromJSONL($players_jsonl)->GroupJoin(
            JSON::LINQ->FromJSONL($scores_jsonl),
            sub { $_[0]->{name} },
            sub { $_[0]->{name} },
            sub {
                my($player, $score_seq) = @_;
                my @sc = $score_seq->ToArray();
                { name => $player->{name}, count => scalar(@sc) }
            },
        )->ToArray();
        is(scalar(@rows), 3, 'GroupJoin JSONL x JSONL: outer row count');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($players_jsonl)->GroupJoin(
            JSON::LINQ->FromJSONL($scores_jsonl),
            sub { $_[0]->{name} },
            sub { $_[0]->{name} },
            sub {
                my($player, $score_seq) = @_;
                my @sc = $score_seq->ToArray();
                { name => $player->{name}, count => scalar(@sc) }
            },
        )->ToArray();
        my %c = map { $_->{name} => $_->{count} } @rows;
        is($c{Alice}, 2, 'GroupJoin JSONL x JSONL: Alice has 2 scores');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($players_jsonl)->GroupJoin(
            JSON::LINQ->FromJSONL($scores_jsonl),
            sub { $_[0]->{name} },
            sub { $_[0]->{name} },
            sub {
                my($player, $score_seq) = @_;
                my @sc = $score_seq->ToArray();
                { name => $player->{name}, count => scalar(@sc) }
            },
        )->ToArray();
        my %c = map { $_->{name} => $_->{count} } @rows;
        is($c{Bob}, 1, 'GroupJoin JSONL x JSONL: Bob has 1 score');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($players_jsonl)->GroupJoin(
            JSON::LINQ->FromJSONL($scores_jsonl),
            sub { $_[0]->{name} },
            sub { $_[0]->{name} },
            sub {
                my($player, $score_seq) = @_;
                my @sc = $score_seq->ToArray();
                { name => $player->{name}, count => scalar(@sc) }
            },
        )->ToArray();
        my %c = map { $_->{name} => $_->{count} } @rows;
        is($c{Carol}, 0, 'GroupJoin JSONL x JSONL: Carol has 0 scores');
    },

    # ------------------------------------------------------------------
    # 5. Concat + Join: two FromJSONL sources concatenated, then Joined
    # ------------------------------------------------------------------

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Concat(
            JSON::LINQ->FromJSONL($extra_jsonl)
        )->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        is(scalar(@rows), 5, 'Concat+Join JSONL x JSONL: row count (3+2=5)');
    },

    sub {
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Concat(
            JSON::LINQ->FromJSONL($extra_jsonl)
        )->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { { name => $_[0]->{name}, dept => $_[1]->{dept} } },
        )->ToArray();
        my @names = sort map { $_->{name} } @rows;
        is(join(',', @names), 'Alice,Bob,Carol,Dave,Eve',
           'Concat+Join JSONL x JSONL: all names present');
    },

    # ------------------------------------------------------------------
    # 6. ToJSONL round-trip: write then read, verify no corruption
    # ------------------------------------------------------------------

    sub {
        my $out = "$TDIR/cfh_roundtrip_$$.jsonl";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToJSONL($out);
        my @rows = JSON::LINQ->FromJSONL($out)->ToArray();
        is(scalar(@rows), 3, 'ToJSONL round-trip: row count');
    },

    sub {
        my $out = "$TDIR/cfh_roundtrip2_$$.jsonl";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToJSONL($out);
        my @rows = JSON::LINQ->FromJSONL($out)->ToArray();
        my @names = sort map { $_->{name} } @rows;
        is(join(',', @names), 'Alice,Bob,Carol', 'ToJSONL round-trip: names');
    },

    # ------------------------------------------------------------------
    # 7. ToJSON round-trip: write then read via FromJSON
    # ------------------------------------------------------------------

    sub {
        my $out = "$TDIR/cfh_roundtrip_$$.json";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToJSON($out);
        my @rows = JSON::LINQ->FromJSON($out)->ToArray();
        is(scalar(@rows), 3, 'ToJSON round-trip: row count');
    },

    sub {
        my $out = "$TDIR/cfh_roundtrip2_$$.json";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToJSON($out);
        my @rows = JSON::LINQ->FromJSON($out)->ToArray();
        my @names = sort map { $_->{name} } @rows;
        is(join(',', @names), 'Alice,Bob,Carol', 'ToJSON round-trip: names');
    },

    # ------------------------------------------------------------------
    # 8. ToLTSV round-trip: write then read via FromLTSV
    # ------------------------------------------------------------------

    sub {
        my $out = "$TDIR/cfh_roundtrip_$$.ltsv";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToLTSV($out);
        my @rows = JSON::LINQ->FromLTSV($out)->ToArray();
        is(scalar(@rows), 3, 'ToLTSV round-trip: row count');
    },

    sub {
        my $out = "$TDIR/cfh_roundtrip2_$$.ltsv";
        push @tmpfiles, $out;
        JSON::LINQ->FromJSONL($emp_jsonl)->ToLTSV($out);
        my @rows = JSON::LINQ->FromLTSV($out)->ToArray();
        my @names = sort map { $_->{name} } @rows;
        is(join(',', @names), 'Alice,Bob,Carol', 'ToLTSV round-trip: names');
    },

    # ------------------------------------------------------------------
    # 9. $_fh_seq counter increments correctly (sequence isolation check)
    # ------------------------------------------------------------------

    sub {
        my $before = $JSON::LINQ::_fh_seq;
        # Open two JSONL iterators simultaneously via Join
        my @rows = JSON::LINQ->FromJSONL($emp_jsonl)->Join(
            JSON::LINQ->FromJSONL($dep_jsonl),
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{dept_id} },
            sub { $_[0]->{name} },
        )->ToArray();
        my $after = $JSON::LINQ::_fh_seq;
        # _open_fh always uses the numbered-glob strategy on all Perl versions,
        # so $_fh_seq always increments (at least once per From* call).
        # A Join of 2 JSONL streams opens at least 2 filehandles.
        ok($after >= $before + 2, '_fh_seq incremented at least 2 for Join of 2 JSONL');
    },

);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
unlink @tmpfiles;
exit($FAIL ? 1 : 0);
