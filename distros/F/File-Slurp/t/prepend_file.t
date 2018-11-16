use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw(write_file prepend_file read_file);
use Test::More ;

plan tests => 32;

my $existing_data = <<PRE ;
line 1
line 2
more
PRE

{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, $prepend_data);
    ok($res, 'prepend_file: empty string: got response!');
    ok(!$warn, 'prepend_file: empty string: no warnings!');
    ok(!$err, 'prepend_file: empty string: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: empty string: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, $prepend_data);
    ok($res, 'prepend_file: add line: got response!');
    ok(!$warn, 'prepend_file: add line: no warnings!');
    ok(!$err, 'prepend_file: add line: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "partial line";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, $prepend_data);
    ok($res, 'prepend_file: partial line: got response!');
    ok(!$warn, 'prepend_file: partial line: no warnings!');
    ok(!$err, 'prepend_file: partial line: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: partial line: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, {}, $prepend_data);
    ok($res, 'prepend_file: add line, empty opts: got response!');
    ok(!$warn, 'prepend_file: add line, empty opts: no warnings!');
    ok(!$err, 'prepend_file: add line, empty opts: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line, empty opts: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, {foo=>1,bar=>2}, $prepend_data);
    ok($res, 'prepend_file: add line, invalid opts: got response!');
    ok(!$warn, 'prepend_file: add line, invalid opts: no warnings!');
    ok(!$err, 'prepend_file: add line, invalid opts: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line, invalid opts: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, {foo=>1,bar=>2,binmode=>':raw'}, $prepend_data);
    ok($res, 'prepend_file: add line, invalid opts, binmode: got response!');
    # this should get fixed
    SKIP: {
        skip "Binmode is bad news bears with sysread on Perl 5.30+", 1;
        ok(!$warn, 'prepend_file: add line, invalid opts, binmode: no warnings!');
    }
    ok(!$err, 'prepend_file: add line, invalid opts, binmode: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line, invalid opts, binmode: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, {foo=>1,bar=>2,err_mode=>'quiet'}, $prepend_data);
    ok($res, 'prepend_file: add line, invalid opts, err_mode quiet: got response!');
    ok(!$warn, 'prepend_file: add line, invalid opts, err_mode quiet: no warnings!');
    ok(!$err, 'prepend_file: add line, invalid opts, err_mode quiet: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line, invalid opts, err_mode quiet: contents match');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my $prepend_data = "line 0\n";
    my ($res, $warn, $err) = trap_function(\&prepend_file, $file, \$prepend_data);
    ok($res, 'prepend_file: add line, scalar ref: got response!');
    ok(!$warn, 'prepend_file: add line, scalar ref: no warnings!');
    ok(!$err, 'prepend_file: add line, scalar ref: no exceptions!');
    my $data = read_file($file);
    is($data, $prepend_data.$existing_data, 'prepend_file: add line, scalar ref: contents match');
    unlink $file;
}
