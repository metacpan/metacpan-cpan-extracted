use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp qw(read_file write_file edit_file);
use Test::More;

plan tests => 20;

my $file = 'edit_file';
my $existing_data = <<PRE;
line 1
line 2
more
PRE

{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {s/([0-9])/${1}000/g}, $file);
    ok($res, 'edit_file: edit line: got response!');
    ok(!$warn, 'edit_file: edit line: no warnings!');
    ok(!$err, 'edit_file: edit line: no exceptions!');
    my $expected = join("\n", ('line 1000', 'line 2000', 'more', ''));
    is(read_file($file), $expected, 'edit_file: edit line: contents are right');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {s/([0-9])/${1}000/g}, $file, {});
    ok($res, 'edit_file: edit line, empty options hashref: got response!');
    ok(!$warn, 'edit_file: edit line, empty options hashref: no warnings!');
    ok(!$err, 'edit_file: edit line, empty options hashref: no exceptions!');
    my $expected = join("\n", ('line 1000', 'line 2000', 'more', ''));
    is(read_file($file), $expected, 'edit_file: edit line, empty options hashref: contents are right');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {s/([0-9])/${1}000/g}, $file, {foo=>1,bar=>2});
    ok($res, 'edit_file: edit line, invalid options: got response!');
    ok(!$warn, 'edit_file: edit line, invalid options: no warnings!');
    ok(!$err, 'edit_file: edit line, invalid options: no exceptions!');
    my $expected = join("\n", ('line 1000', 'line 2000', 'more', ''));
    is(read_file($file), $expected, 'edit_file: edit line, invalid options: contents are right');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {s/([0-9])/${1}000/g}, $file, {foo=>1,bar=>2, binmode=>':raw'});
    ok($res, 'edit_file: edit line, invalid options, binmode: got response!');
    # this should get fixed
    SKIP: {
        skip "Binmode is bad news bears with sysread on Perl 5.30+", 1;
        ok(!$warn, 'edit_file: edit line, invalid options, binmode: no warnings!');
    }
    ok(!$err, 'edit_file: edit line, invalid options, binmode: no exceptions!');
    my $expected = join("\n", ('line 1000', 'line 2000', 'more', ''));
    is(read_file($file), $expected, 'edit_file: edit line, invalid options, binmode: contents are right');
    unlink $file;
}
{
    my $file = temp_file_path();
    write_file($file, $existing_data);
    my ($res, $warn, $err) = trap_function(\&edit_file, sub {s/([0-9])/${1}000/g}, $file, {foo=>1,bar=>2, err_mode=>'quiet'});
    ok($res, 'edit_file: edit line, invalid options, err_mode: got response!');
    ok(!$warn, 'edit_file: edit line, invalid options, err_mode: no warnings!');
    ok(!$err, 'edit_file: edit line, invalid options, err_mode: no exceptions!');
    my $expected = join("\n", ('line 1000', 'line 2000', 'more', ''));
    is(read_file($file), $expected, 'edit_file: edit line, invalid options, err_mode: contents are right');
    unlink $file;
}
