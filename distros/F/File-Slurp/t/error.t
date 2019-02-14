use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTestOverride qw(trap_function_override_core);
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw( :all prepend_file edit_file );
use Test::More;

plan tests => 30;

my $is_win32 = $^O =~ /cygwin|win32/i ;
# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

# write_file open error - no sysopen
{
    my $file = temp_file_path('gimme a bad one');
    my ($res, $warn, $err) = trap_function_override_core('sysopen', \&write_file, $file);
    ok(!$warn, 'write_file: open error, no sysopen - no warning!');
    like($err, qr/open/, 'write_file: open error, no sysopen - got exception!');
    ok(!$res, 'write_file: open error, no sysopen - no content!');

}
# write_file write error - no syswrite
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 3;
    my $file = temp_file_path();
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&write_file, $file, '');
    ok(!$warn, 'write_file: write error, no syswrite - no warning!');
    like($err, qr/write/, 'write_file: write error, no syswrite - got exception!');
    ok(!$res, 'write_file: write error, no syswrite - no content!');
    unlink $file;
};
# atomic rename error
SKIP: {
    skip "Atomic rename on Win32 is useless", 3 if $is_win32;
    my $file = temp_file_path();
    my ($res, $warn, $err) = trap_function_override_core('rename', \&write_file, $file, {atomic => 1}, '');
    ok(!$warn, 'write_file: atomic rename error, no rename - no warning!');
    like($err, qr/rename/, 'write_file: atomic renamed error, no rename - got exception!');
    ok(!$res, 'write_file: atomic rename error, no rename - no content!');
    unlink $file;
    unlink "$file.$$";
}
# read_dir opendir error
{
    my $file = temp_file_path('gimme a bad one');
    my ($res, $warn, $err) = trap_function(\&read_dir, $file);
    ok(!$warn, 'read_dir: opendir error - no warning!');
    like($err, qr/open/, 'read_dir: opendir error - got exception!');
    ok(!$res, 'read_dir: opendir error - no content!');
}
# prepend_file read error
{
    my $file = temp_file_path('gimme a bad one');
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file);
    ok(!$warn, 'prepend_file: read error - no warning!');
    like($err, qr/read_file/, 'prepend_file: read error - got exception!');
    ok(!$res, 'prepend_file: read error - no content!');
}
# prepend_file write error
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 3;
    my $file = temp_file_path();
    write_file($file, '');
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&prepend_file, $file, '');
    ok(!$warn, 'prepend_file: opendir error - no warning!');
    like($err, qr/write_file/, 'prepend_file: opendir error - got exception!');
    ok(!$res, 'prepend_file: opendir error - no content!');
    unlink $file;
    unlink "$file.$$";
};
# edit_file read error
{
    my $file = temp_file_path();
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {}, $file);
    ok(!$warn, 'edit_file: read error - no warning!');
    like($err, qr/read_file/, 'edit_file: read error - got exception!');
    ok(!$res, 'edit_file: read error - no content!');
    unlink $file;
}
# edit_file write error
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 3;
    my $file = temp_file_path();
    write_file($file, '');
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&edit_file, sub {}, $file);
    ok(!$warn, 'edit_file: write error - no warning!');
    like($err, qr/write_file/, 'edit_file: write error - got exception!');
    ok(!$res, 'edit_file: write error - no content!');
    unlink $file;
    unlink "$file.$$";
};
# edit_file_lines read error
{
    my $file = temp_file_path();
    my ($res, $warn, $err) = trap_function(\&edit_file_lines, sub {}, $file);
    ok(!$warn, 'edit_file_lines: read error - no warning!');
    like($err, qr/read_file/, 'edit_file_lines: read error - got exception!');
    ok(!$res, 'edit_file_lines: read error - no content!');
    unlink $file;
}
# edit_file write error
SKIP: {
    skip "Skip these tests because mocking write failures can't happen", 3;
    my $file = temp_file_path();
    write_file($file, '');
    my ($res, $warn, $err) = trap_function_override_core('syswrite', \&edit_file_lines, sub {}, $file);
    ok(!$warn, 'edit_file_lines: write error - no warning!');
    like($err, qr/write_file/, 'edit_file_lines: write error - got exception!');
    ok(!$res, 'edit_file_lines: write error - no content!');
    unlink $file;
    unlink "$file.$$";
};
