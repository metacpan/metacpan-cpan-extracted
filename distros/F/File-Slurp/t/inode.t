use strict;
use warnings;
use IO::Handle ();

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path);

use File::Slurp qw(read_file write_file);

use Test::More;
BEGIN {
    if ($^O eq 'MSWin32') {
        plan skip_all => 'skip inode test on windows';
        exit;
    }
}
plan tests => 2;

my $data = <<TEXT;
line 1
more text
TEXT

my $file = temp_file_path();

write_file($file, $data);
my $inode_num = (stat $file)[1];

write_file($file, $data);
my $inode_num2 = (stat $file)[1];

#print "I1 $inode_num I2 $inode_num2\n" ;

is($inode_num, $inode_num2, 'same inode');

write_file($file, {atomic => 1}, $data);
$inode_num2 = (stat $file)[1];

#print "I1 $inode_num I2 $inode_num2\n" ;

isnt($inode_num, $inode_num2, 'different inode');

unlink $file;
unlink "$file.$$";
