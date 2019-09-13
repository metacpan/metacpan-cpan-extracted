use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path trap_function);

use File::Slurp;
use Test::More;

plan(tests => 3);

my $file = temp_file_path();
my $data = <<TEXT;
line 1
more text
TEXT

my $res = write_file($file, $data);
ok($res, 'write_file: text data');
$res = append_file($file, '');
ok($res, 'append_file: no data');

my $text = read_file($file);
is($text, $data, 'read_file: scalar context');

unlink $file;
