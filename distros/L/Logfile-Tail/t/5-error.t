
use Test::More tests => 32;

use Logfile::Tail ();
use Digest::SHA ();
use Cwd ();

my $logfile1;
is(($logfile1 = new Logfile::Tail('t/nonexistent')), undef,
	'when opening nonexistent file, open should fail');

my $status_filename = Digest::SHA::sha256_hex(Cwd::getcwd() . '/t/file');

my $warning;
local $SIG{__WARN__} = sub { $warning = join '', @_; };

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/file', '<:unknown')), undef,
	'open unknown IO layer should fail');
like($warning,
	qr/^Unknown PerlIO layer "unknown"/,
	'check that warning was issued');

{
no warnings;
my $orig_new = \&IO::File::new;
*IO::File::new = sub { if ((caller 1)[3] eq 'Logfile::Tail::_open') { return; } goto $orig_new; };
}
is(($logfile1 = new Logfile::Tail('t/file')), undef, 'try to read logfile when IO::File is broken');

local *TMP;
ok(open(TMP, '>', ".logfile-tail-status/$status_filename"),
	'clear the status file');
ok((print TMP "File [strange] offset [145] checksum [xxx]\n"),
	'  put bad logfile name to the status file');
ok(close(TMP), '    and close it');

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/file')), undef,
	'try to open the log file when the status file points to different file');
is($warning,
	"Status file [.logfile-tail-status/$status_filename] is for file [strange] while expected [@{[ Cwd::getcwd() ]}/t/file]\n",
	'check that warning was issued');

ok(open(TMP, '>', ".logfile-tail-status/$status_filename"),
	'clear the status file');
ok((print TMP "Unexpected content\n"),
	'  put content in bad format to the status file');
ok(close(TMP), '    and close it');

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/file')), undef,
	'try to open the log file when the status file had garbage it in');
is($warning,
	"Status file [.logfile-tail-status/$status_filename] has bad format\n",
	'check that warning was issued');


ok(open(TMP, '>', ".logfile-tail-status/$status_filename"),
	'clear the status file');
ok((print TMP "File [@{[ Cwd::getcwd() ]}/t/file] archive [.3] offset [145] checksum [xxx]\n"),
	'  put nonexistent archive to the status file');
ok(close(TMP), '    and close it');

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/file')), undef,
	'try to open the log file when the status file point to archive which does not exists');
is($warning, undef, 'check that no warning was issued, the file simply does not exist');


is(system('rm', '-rf', '.logfile-tail-status'), 0,
	'remove status directory');

ok(open(TMP, '>', '.logfile-tail-status'), '  and create (empty) file instead');
ok(close(TMP), '    and close it');

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/file')), undef,
	'disabling the status directory should cause opening of the log to fail');
is($warning,
	"Error reading/creating status file [.logfile-tail-status/$status_filename]\n",
	'check that warning was issued');

is($warning = undef, undef, 'clear any warnings');
is(($logfile1 = new Logfile::Tail('t/no-permissions/file')), undef,
        'attempt to read from directory which does not exist or without permissions should fail');
is($warning,
	"Cannot access file [t/no-permissions/file]\n",
	'check that warning was issued');

