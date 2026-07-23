use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestMariaDB;
plan skip_all => 'No MariaDB/MySQL server' unless TestMariaDB::server_available();
use EV;
use EV::MariaDB;

# Regression tests for the 0.07 review fixes:
#   Finding 1 - statement handles are validated ids, not raw pointers
#               (was: UAF after close_stmt, segfault on fabricated handle)
#   Finding 2 - the EV::Loop object is kept alive by the connection
#               (was: dangling loop pointer -> watcher ops on freed memory)
#   Finding 3 - change_user(undef db) keeps the current database (POD contract)

my %A = TestMariaDB::connect_args();

sub run_connected {
    my ($body) = @_;
    my $m = EV::MariaDB->new(on_error => sub { diag("on_error: $_[0]"); EV::break });
    $m->on_connect(sub { $body->($m) });
    $m->connect(@A{qw(host user password database port)}, $A{unix_socket});
    my $timeout = EV::timer(10, 0, sub { diag("safety timeout"); EV::break });
    EV::run;
    $m->finish if $m->is_connected;
}

# --- Finding 1a: reusing a handle after close_stmt croaks instead of UAF ---
run_connected(sub {
    my ($m) = @_;
    $m->prepare("select 1", sub {
        my ($stmt, $err) = @_;
        BAIL_OUT("prepare failed: $err") if $err;
        $m->close_stmt($stmt, sub {
            my ($ok, $cerr) = @_;
            ok($ok && !$cerr, 'close_stmt succeeds');
            eval { $m->execute($stmt, [], sub { }) };
            like($@, qr/invalid statement handle/,
                 'Finding 1a: execute on a closed handle croaks (no use-after-free)');
            eval { $m->close_stmt($stmt, sub { }) };
            like($@, qr/invalid statement handle/,
                 'Finding 1a: second close_stmt on the same handle croaks (no double-free)');
            EV::break;
        });
    });
});

# --- Finding 1b: fabricated handles croak instead of dereferencing garbage ---
run_connected(sub {
    my ($m) = @_;
    eval { $m->execute(999_999_999, [], sub { }) };
    like($@, qr/invalid statement handle/,
         'Finding 1b: execute on a fabricated handle croaks (no wild dereference)');
    eval { $m->bind_params(888_888_888, []) };
    like($@, qr/invalid statement handle/,
         'Finding 1b: bind_params on a fabricated handle croaks');
    eval { $m->stmt_reset(777_777_777, sub { }) };
    like($@, qr/invalid statement handle/,
         'Finding 1b: stmt_reset on a fabricated handle croaks');
    EV::break;
});

# --- Finding 3: change_user(undef db) preserves the current database ---
run_connected(sub {
    my ($m) = @_;
    $m->change_user($A{user}, $A{password}, undef, sub {
        my ($ok, $err) = @_;
        ok($ok && !$err, 'change_user(undef db) succeeds') or diag("err: " . ($err // ''));
        $m->query("SELECT DATABASE()", sub {
            my ($rows, $qerr) = @_;
            is($rows->[0][0], $A{database},
               'Finding 3: change_user(undef db) keeps the current database');
            EV::break;
        });
    });
});

# --- Finding 2: a temporary custom loop must be kept alive by the object ---
# Run in a child: build with loop => EV::Loop->new, arm a watcher, drop the
# loop reference, then destroy the object. Pre-fix this dereferenced a freed
# loop (SIGSEGV); post-fix the object holds a reference so it stays valid.
{
    my $child = <<'CHILD';
use lib 't/lib'; use TestMariaDB; use EV; use EV::MariaDB;
my %a = TestMariaDB::connect_args();
my $loop = EV::Loop->new;
my $m = EV::MariaDB->new(loop => $loop, on_error => sub { });
$m->on_connect(sub { $loop->break });
$m->connect(@a{qw(host user password database port)}, $a{unix_socket});
$loop->run;                     # until connected
$m->query("select sleep(1)", sub { });
$loop->run(EV::RUN_NOWAIT);     # arm the read watcher (result not yet ready)
undef $loop;                    # drop our ref; loop survives iff object holds one
undef $m;                       # DESTROY must not touch a freed loop
exit 0;
CHILD
    # Propagate the parent's @INC so the child loads the same EV::MariaDB
    # (blib under `make test`) rather than a possibly-installed copy.
    my @inc = map { ('-I', $_) } @INC;
    my $rc  = system($^X, @inc, '-e', $child);
    my $sig = $rc & 127;
    is($sig, 0,
       'Finding 2: object keeps the EV::Loop alive - no crash on destroy')
        or diag(sprintf("child terminated by signal %d (11/139 = dangling loop pointer)", $sig));
}

done_testing();
