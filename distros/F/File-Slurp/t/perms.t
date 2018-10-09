use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use FileSlurpTest qw(trap_function);
use File::Slurp;
use Test::More;

plan skip_all => "Win32 doesn't use permissions this way." if $^O eq 'MSWin32';
plan skip_all => "Windows WSL can't set permissions in some cases." if FileSlurpTest::IS_WSL;
plan tests => 8;

my $file = FileSlurpTest::temp_file_path();

my $text = <<END;
This is a bit of contents
to store in a file.
END

umask 027;

my ($res, $warn, $err) = trap_function(\&write_file, $file, $text);
ok($res, 'write_file: plain write - got a response');
ok(!$warn, 'write_file: plain write - no warnings!');
ok(!$err, 'write_file: plain write - no exceptions!');
is(_mode( $file ), 0640, 'write_file: plain write - default perms');
unlink $file;

($res, $warn, $err) = trap_function(\&write_file, $file, {perms => 0777}, $text);
ok($res, 'write_file: perms opt - got a response');
ok(!$warn, 'write_file: perms opt - no warnings!');
ok(!$err, 'write_file: perms opt - no exceptions!');
is(_mode($file), 0750, 'write_file: perms opt - got perms');
unlink $file;

exit;

sub _mode {
	return 07777 & (stat $_[0])[2] ;
}
