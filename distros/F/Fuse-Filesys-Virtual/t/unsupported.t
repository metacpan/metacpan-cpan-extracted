#
# unsupported api
#
use strict;

use Test::More tests => 3;

use Fuse::Filesys::Virtual;


#################################################
#
# unsupported things
#
#################################################

my $test = TestFS->new;
my $fs = Fuse::Filesys::Virtual->new($test, {debug => 1});

ok($fs->symlink("/a", "/b") < 0);
ok($fs->link("/a", "/b") < 0);
ok($fs->readlink("/a") < 0);


#################################################
#
# Test FS
#
#################################################

package TestFS;

use base qw(Filesys::Virtual);

sub new {
    my $class = shift;
    bless {}, $class;
}

sub stat {
    return CORE::stat(".");
}

sub list {
    return qw(. ..);
}
