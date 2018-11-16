use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path);

use File::Slurp qw(slurp write_file);
use Test::More;

plan tests => 1;

my $data = <<TEXT;
line 1
more text
TEXT

my $file = temp_file_path();

write_file($file, $data);
my $read_buf = slurp($file);
is($read_buf, $data, 'slurp alias');

unlink $file ;
