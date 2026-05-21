######################################################################
# 0014-concurrent-fh.t
# Verify that multiple FromLTSV iterators can be open simultaneously.
#
# Background: on Perl 5.005_03 the original code used
#   $fh = \do { local *_ };
# which always resolves to *main::_, so two concurrent FromLTSV calls
# shared the same IO slot.  The fix uses a unique numbered package glob
# per call so each iterator has its own independent IO slot.
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }

use FindBin ();
use lib "$FindBin::Bin/../lib";
use LTSV::LINQ;

my($PASS, $FAIL, $T) = (0, 0, 0);
sub ok {
    my($cond, $name) = @_;
    $T++;
    if ($cond) { $PASS++; print "ok $T - $name\n" }
    else { $FAIL++; print "not ok $T - $name\n" }
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
sub make_ltsv {
    my($suffix, @lines) = @_;
    my $f = "$TDIR/cfh_${suffix}.ltsv";
    push @tmpfiles, $f;
    open(TF, ">$f") or die "Cannot create $f: $!";
    for my $line (@lines) { print TF $line, "\n" }
    close TF;
    return $f;
}

# Prepare all test data up front so closures capture references, not values
my $f1 = make_ltsv('a',
    "id:1\tval:aaa",
    "id:2\tval:bbb",
    "id:3\tval:ccc",
);
my $f2 = make_ltsv('b',
    "id:10\tval:xxx",
    "id:20\tval:yyy",
    "id:30\tval:zzz",
);
my @r1 = LTSV::LINQ->FromLTSV($f1)->ToArray();
my @r2 = LTSV::LINQ->FromLTSV($f2)->ToArray();

my $ford = make_ltsv('orders',
    "id:1\tcust:A\tamount:100",
    "id:2\tcust:B\tamount:200",
    "id:3\tcust:A\tamount:300",
);
my $fcust = make_ltsv('customers',
    "id:A\tname:Alice",
    "id:B\tname:Bob",
);
my @joined = LTSV::LINQ->FromLTSV($ford)->Join(
    LTSV::LINQ->FromLTSV($fcust),
    sub { $_[0]{cust} },
    sub { $_[0]{id} },
    sub { { name => $_[1]{name}, amount => $_[0]{amount} } }
)->OrderByNum(sub { $_[0]{amount} })->ToArray();

my $fdepts = make_ltsv('depts',
    "dept:Eng\tbudget:1000",
    "dept:Mkt\tbudget:500",
    "dept:HR\tbudget:300",
);
my $fmembers = make_ltsv('members',
    "dept:Eng\tname:Alice",
    "dept:Eng\tname:Bob",
    "dept:Mkt\tname:Carol",
);
my @grpjoined = LTSV::LINQ->FromLTSV($fdepts)->GroupJoin(
    LTSV::LINQ->FromLTSV($fmembers),
    sub { $_[0]{dept} },
    sub { $_[0]{dept} },
    sub {
        my($dept, $grp) = @_;
        return { dept => $dept->{dept}, count => $grp->Count() };
    }
)->OrderByStr(sub { $_[0]{dept} })->ToArray();
my %by_dept = map { $_->{dept} => $_->{count} } @grpjoined;

my $fa = make_ltsv('p1', "k:a\tv:1", "k:b\tv:2");
my $fb = make_ltsv('p2', "k:c\tv:3", "k:d\tv:4");
my $fc = make_ltsv('p3', "k:a\tlabel:alpha", "k:c\tlabel:gamma");
my @concat_joined = LTSV::LINQ->FromLTSV($fa)
    ->Concat(LTSV::LINQ->FromLTSV($fb))
    ->Join(
        LTSV::LINQ->FromLTSV($fc),
        sub { $_[0]{k} },
        sub { $_[0]{k} },
        sub { { k => $_[0]{k}, v => $_[0]{v}, label => $_[1]{label} } }
    )->OrderByStr(sub { $_[0]{k} })->ToArray();

my $fsrc = make_ltsv('src',
    "host:web01\tstatus:200",
    "host:web02\tstatus:500",
    "host:web03\tstatus:200",
);
my $fdst = "$TDIR/cfh_dst.ltsv";
push @tmpfiles, $fdst;
my @ok_rows = LTSV::LINQ->FromLTSV($fsrc)->Where(status => '200')->ToArray();
LTSV::LINQ->From([ @ok_rows ])->ToLTSV($fdst);
my @written = LTSV::LINQ->FromLTSV($fdst)->ToArray();

my @tests = (
    # 1. Two FromLTSV iterators - independent reads
    sub { is(scalar(@r1), 3,     'concurrent-fh: f1 record count') },
    sub { is(scalar(@r2), 3,     'concurrent-fh: f2 record count') },
    sub { is($r1[0]{val}, 'aaa', 'concurrent-fh: f1 first val') },
    sub { is($r2[0]{val}, 'xxx', 'concurrent-fh: f2 first val') },
    sub { is($r1[2]{val}, 'ccc', 'concurrent-fh: f1 last val') },
    sub { is($r2[2]{val}, 'zzz', 'concurrent-fh: f2 last val') },
    # 2. Join with two FromLTSV sources
    sub { is(scalar(@joined), 3,         'Join two FromLTSV: result count') },
    sub { is($joined[0]{name},   'Alice', 'Join: first name') },
    sub { is($joined[0]{amount}, '100',   'Join: first amount') },
    sub { is($joined[1]{name},   'Bob',   'Join: second name') },
    sub { is($joined[1]{amount}, '200',   'Join: second amount') },
    sub { is($joined[2]{name},   'Alice', 'Join: third name') },
    sub { is($joined[2]{amount}, '300',   'Join: third amount') },
    # 3. GroupJoin with two FromLTSV sources
    sub { is(scalar(@grpjoined), 3, 'GroupJoin two FromLTSV: result count') },
    sub { is($by_dept{Eng}, 2,      'GroupJoin: Eng count') },
    sub { is($by_dept{Mkt}, 1,      'GroupJoin: Mkt count') },
    sub { is($by_dept{HR},  0,      'GroupJoin: HR count (no members)') },
    # 4. Three FromLTSV simultaneously (Concat + Join)
    sub { is(scalar(@concat_joined), 2,       'Three FromLTSV (Concat+Join): count') },
    sub { is($concat_joined[0]{k},     'a',     'Three FromLTSV: first k') },
    sub { is($concat_joined[0]{label}, 'alpha', 'Three FromLTSV: first label') },
    sub { is($concat_joined[1]{k},     'c',     'Three FromLTSV: second k') },
    sub { is($concat_joined[1]{label}, 'gamma', 'Three FromLTSV: second label') },
    # 5. ToLTSV does not interfere with FromLTSV
    sub { is(scalar(@ok_rows), 2,        'ToLTSV: source filtered count') },
    sub { is(scalar(@written), 2,        'ToLTSV: written record count') },
    sub { is($written[0]{status}, '200', 'ToLTSV: written first status') },
    sub { is($written[1]{host}, 'web03', 'ToLTSV: written second host') },
);

print "1.." . scalar(@tests) . "\n";
$_->() for @tests;
unlink @tmpfiles;
exit($FAIL ? 1 : 0);
