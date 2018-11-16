use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp;
use Test::More;

plan(tests => 6);

my $file = temp_file_path();

my $data = <<TEXT ;
line 1
more text
TEXT

{
    my ($res, $warn, $err) = trap_function(\&write_file, $file, {no_clobber=>1}, $data);
    ok($res, 'write_file: no_clobber opt - new file');
    ok(!$warn, 'write_file: no_clobber opt - new file - no warnings!');
    ok(!$err, 'write_file: no_clobber opt - new file - no exceptions!');
}

{
    my ($res, $warn, $err) = trap_function(\&write_file, $file, {no_clobber=>1, err_mode=>'quiet'}, $data);
    ok(!$res, 'write_file: no_clobber, err_mode quiet opts - existing file - no added content');
    ok(!$warn, 'write_file: no_clobber, err_mode quiet opts - existing file - no warnings!');
    ok(!$err, 'write_file: no_clobber, err_mode quiet opts - existing file - no exceptions!');
}

unlink $file ;
