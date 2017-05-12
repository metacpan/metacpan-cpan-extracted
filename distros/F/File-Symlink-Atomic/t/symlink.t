use strict;
use warnings;
use Test::More tests => 2;
use File::Symlink::Atomic;

my $symlink_name = File::Spec->catfile(qw/ t test.symlink /);
ok symlink __FILE__, $symlink_name;
ok -l $symlink_name;
END { unlink $symlink_name }
