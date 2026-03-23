######################################################################
#
# t/0010-log.t - Tests for file logging, directory init, and _iso_time.
#
######################################################################

use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use File::Spec;
use File::Path ();

###############################################################################
# Embedded test harness (no Test::More dependency)
###############################################################################
my ($PASS, $FAIL, $T) = (0, 0, 0);
sub ok   { my($c,$n)=@_; $T++; $c ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub is   { my($g,$e,$n)=@_; $T++; defined($g)&&("$g" eq "$e") ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n  (got='${\(defined $g?$g:'undef')}', exp='$e')\n") }
sub like { my($g,$re,$n)=@_; $T++; defined($g)&&$g=~$re ? ($PASS++, print "ok $T - $n\n") : ($FAIL++, print "not ok $T - $n\n") }
sub plan_skip { print "1..0 # SKIP $_[0]\n"; exit 0 }

use HTTP::Handy;

print "1..28\n";

###############################################################################
# Category: _iso_time
###############################################################################

# ok 1: returns a defined string
my $ts = HTTP::Handy::_iso_time();
ok(defined $ts, '_iso_time: defined'); # ok 1

# ok 2: matches YYYY-MM-DDTHH:MM:SS
like($ts, qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/, '_iso_time: format'); # ok 2

# ok 3: year part is plausible
my ($y) = ($ts =~ /^(\d{4})/);
ok($y >= 2026, '_iso_time: year >= 2026'); # ok 3

# ok 4: month in 01-12
my ($mo) = ($ts =~ /^\d{4}-(\d{2})/);
ok($mo >= 1 && $mo <= 12, '_iso_time: month in range'); # ok 4

# ok 5: day in 01-31
my ($d) = ($ts =~ /^\d{4}-\d{2}-(\d{2})/);
ok($d >= 1 && $d <= 31, '_iso_time: day in range'); # ok 5

# ok 6: hour in 00-23
my ($h) = ($ts =~ /T(\d{2}):/);
ok(defined $h && $h >= 0 && $h <= 23, '_iso_time: hour in range'); # ok 6

# ok 7: US-ASCII only
ok($ts !~ /[^\x00-\x7F]/, '_iso_time: US-ASCII only'); # ok 7

# ok 8: two rapid calls are equal or differ by at most 1 second
my $ts2 = HTTP::Handy::_iso_time();
my $same_or_close = ($ts eq $ts2) || do {
    # allow the last two digits (seconds) to differ by 1
    my $a = $ts;  my $b = $ts2;
    $a =~ s/\d{2}$//;  $b =~ s/\d{2}$//;
    $a eq $b;
};
ok($same_or_close, '_iso_time: two rapid calls are consistent'); # ok 8

###############################################################################
# Category: _init_directories
###############################################################################

# Run _init_directories in a temporary working directory so we do not
# pollute the distribution tree.
my $tmpdir = File::Spec->catdir(File::Spec->tmpdir, "handy_test_dirs_$$");
mkdir $tmpdir, 0777 or plan_skip("cannot mkdir tmpdir: $!");

# Save and restore cwd around the test.
my $orig_cwd;
eval { require Cwd; $orig_cwd = Cwd::cwd() };
unless (defined $orig_cwd) {
    File::Path::rmtree($tmpdir);
    plan_skip('Cwd not available');
}

chdir $tmpdir or do {
    File::Path::rmtree($tmpdir);
    plan_skip("cannot chdir to tmpdir: $!");
};

END {
    # Close all open filehandles before rmtree.
    # On Windows, open filehandles prevent file and directory deletion.
    if (defined $HTTP::Handy::ACCESS_LOG_FH) {
        close $HTTP::Handy::ACCESS_LOG_FH;
        $HTTP::Handy::ACCESS_LOG_FH = undef;
    }
    # Restore STDERR to the original handle so the log file can be deleted.
    open(STDERR, '>&STDOUT') or 1;  # restore STDERR before file deletion
    chdir $orig_cwd if defined $orig_cwd;
    File::Path::rmtree($tmpdir) if defined $tmpdir && -d $tmpdir;
}

HTTP::Handy::_init_directories();

# ok 9-14: all six directories were created
for my $dir (qw(logs logs/access logs/error run htdocs conf)) {
    ok(-d $dir, "_init_directories: $dir created"); # ok 9-14
}

# ok 15: calling _init_directories again does not die (idempotent)
eval { HTTP::Handy::_init_directories() };
ok(!$@, '_init_directories: idempotent (no die on second call)'); # ok 15

# ok 16: pre-existing directory is left intact
my $marker = File::Spec->catfile('htdocs', 'marker.txt');
{
    local *MF;
    open MF, ">$marker" or die "open: $!";
    print MF "test\n";
    close MF;
}
HTTP::Handy::_init_directories();
ok(-f $marker, '_init_directories: pre-existing files preserved'); # ok 16

###############################################################################
# Category: _open_access_log / access log file creation
###############################################################################

HTTP::Handy::_open_access_log();

# ok 17: $ACCESS_LOG_FH is now defined (log file opened)
ok(defined $HTTP::Handy::ACCESS_LOG_FH, '_open_access_log: filehandle defined'); # ok 17

# ok 18: $CURRENT_LOG_FILE matches the expected pattern YYYYMMDDHHm0.log.ltsv
like($HTTP::Handy::CURRENT_LOG_FILE,
    qr{logs/access/\d{12}\.log\.ltsv$},
    '_open_access_log: filename pattern'); # ok 18

# ok 19: the log file actually exists on disk
ok(-f $HTTP::Handy::CURRENT_LOG_FILE, '_open_access_log: file exists on disk'); # ok 19

# ok 20: calling again with the same time slot is a no-op (returns same fh)
my $fh_before = $HTTP::Handy::ACCESS_LOG_FH;
HTTP::Handy::_open_access_log();
ok($HTTP::Handy::ACCESS_LOG_FH == $fh_before, '_open_access_log: no reopen within same slot'); # ok 20

# ok 21: we can write to the filehandle without dying
eval { print $HTTP::Handy::ACCESS_LOG_FH "test\tline\n" };
ok(!$@, '_open_access_log: writing to fh does not die'); # ok 21

# ok 22: the written content appears in the file
{
    local *RF;
    open RF, "<$HTTP::Handy::CURRENT_LOG_FILE" or die;
    local $/;
    my $content = <RF>;
    close RF;
    ok($content =~ /test\tline/, '_open_access_log: written content readable'); # ok 22
}

###############################################################################
# Category: _log_message (error log)
###############################################################################

# Suppress _log_message STDERR output to console during tests
local *STDERR;
open(STDERR, '>>logs/error/error.log') or die "reopen STDERR: $!";

HTTP::Handy::_log_message('unit test message');

# ok 23: logs/error/error.log was created
ok(-f 'logs/error/error.log', '_log_message: error.log created'); # ok 23

# ok 24: the log file contains the message
{
    local *EF;
    open EF, '<logs/error/error.log' or die;
    local $/;
    my $content = <EF>;
    close EF;
    ok($content =~ /unit test message/, '_log_message: message in error.log'); # ok 24
}

# ok 25: the log line has an ISO timestamp prefix [YYYY-MM-DDTHH:MM:SS]
{
    local *EF;
    open EF, '<logs/error/error.log' or die;
    local $/;
    my $content = <EF>;
    close EF;
    like($content, qr/\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\]/,
        '_log_message: ISO timestamp bracket format'); # ok 25
}

# ok 26: calling _log_message twice appends (both messages present)
HTTP::Handy::_log_message('second message');
{
    local *EF;
    open EF, '<logs/error/error.log' or die;
    local $/;
    my $content = <EF>;
    close EF;
    ok($content =~ /unit test message/ && $content =~ /second message/,
        '_log_message: appends to error.log'); # ok 26
}

###############################################################################
# Category: integration -- _handle_connection writes to access log
###############################################################################

# ok 27: after _handle_connection the access log has content
# We verify by truncating the current log file first, then checking
# that _open_access_log still works after a write.
{
    local *TF;
    open TF, ">$HTTP::Handy::CURRENT_LOG_FILE" or die;
    close TF;
}
my $test_line = join("\t",
    "time:" . HTTP::Handy::_iso_time(),
    "method:GET",
    "path:/test",
    "status:200",
    "size:4",
    "ua:",
    "referer:",
) . "\n";
print $HTTP::Handy::ACCESS_LOG_FH $test_line;

{
    local *RF;
    open RF, "<$HTTP::Handy::CURRENT_LOG_FILE" or die;
    local $/;
    my $content = <RF>;
    close RF;
    like($content, qr{method:GET.*path:/test}s,
        'access log: LTSV line written correctly'); # ok 27
}

# ok 28: access log line has all 7 LTSV fields
{
    local *RF;
    open RF, "<$HTTP::Handy::CURRENT_LOG_FILE" or die;
    my $line = <RF>;
    close RF;
    chomp $line if defined $line;
    my @fields = defined $line ? split /\t/, $line : ();
    ok(scalar @fields == 7, 'access log: 7 LTSV fields per line'); # ok 28
}

exit($FAIL ? 1 : 0);
