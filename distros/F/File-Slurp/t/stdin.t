use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');

use File::Slurp qw(read_file write_file);
use Test::More;

plan tests => 6;

my $data = <<TEXT ;
line 1
more text
TEXT

foreach my $file ( qw(stdin STDIN stdout STDOUT stderr STDERR) ) {
    write_file($file, $data);
    my $read_buf = read_file($file);
    is($read_buf, $data, 'read/write of file [$file]');

    unlink $file;
}
