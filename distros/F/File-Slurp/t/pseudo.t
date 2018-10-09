use strict;
use warnings;

use File::Basename ();
use File::Spec ();
use lib File::Spec->catdir(File::Spec->rel2abs(File::Basename::dirname(__FILE__)), 'lib');
use FileSlurpTest qw(temp_file_path);

use File::Slurp qw(read_file);
use Test::More;

plan tests => 1;

my $proc_file = "/proc/$$/auxv";

SKIP: {
    skip "Can't find pseudo file: $proc_file", 1 unless -r $proc_file;
    my $data_do = do{ local( @ARGV, $/ ) = $proc_file; <> };
    my $data_slurp = read_file($proc_file);
    is($data_do, $data_slurp, 'pseudo');
}
