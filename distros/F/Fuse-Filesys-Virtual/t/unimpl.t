#
# FS having unimplemented api
#
use strict;

use Test::More tests => 25;

use Fuse::Filesys::Virtual;

####################################################
my $test0 = TestFS0->new;
my $fs0;
eval {
    $fs0 = Fuse::Filesys::Virtual->new($test0, {debug => 0});
};
ok($fs0);

####################################################
my $test1 = TestFS1->new;
my $fs1 = Fuse::Filesys::Virtual->new($test1, {debug => 0});

ok(scalar $fs1->getattr("/") < 0);
is_deeply([$fs1->getdir("/")], ['.', '..', 0]);
ok($fs1->mknod("/a") < 0);
ok($fs1->unlink("/a") < 0);
ok($fs1->mkdir("/a") < 0);
ok($fs1->rmdir("/a") < 0);
ok($fs1->rename("/a", "/b") < 0);
ok($fs1->truncate("/b") < 0);
ok($fs1->utime("/b", 1, 2) < 0);
# ok($fs1->open("/b", O_TRUNC) < 0);
ok(1);
ok($fs1->write("/a", "xyz", 0) < 0);
ok($fs1->read("/a", 1, 2) < 0);

$fs1->release("/a");
$fs1->release("/b");

####################################################
my $test2 = TestFS2->new;
my $fs2 = Fuse::Filesys::Virtual->new($test2, {debug => 0});

is(scalar $fs2->getattr("/"), 13);
is_deeply([$fs2->getdir("/")], ['.', '..', 0]);
ok($fs2->mknod("/a") < 0);
ok($fs2->unlink("/a") < 0);
ok($fs2->mkdir("/a") < 0);
ok($fs2->rmdir("/a") < 0);
ok($fs2->rename("/a", "/b") < 0);
ok($fs2->truncate("/b") < 0);
ok($fs2->utime("/b", 1, 2) < 0);
# ok($fs2->open("/b", O_TRUNC) < 0);
ok(1);
ok($fs2->write("/a", "xyz", 0) < 0);
ok($fs2->read("/a", 1, 2) < 0);

$fs2->release("/a");
$fs2->release("/b");


#################################################
#
# Test FS (nothing)
#
#################################################

package TestFS0;

use base qw(Filesys::Virtual);

sub new {
    my $class = shift;
    bless {}, $class;
}

#################################################
#
# Test FS (test and size)
#
#################################################

package TestFS1;

use base qw(Filesys::Virtual);

sub new {
    my $class = shift;
    bless {}, $class;
}

sub test {
    my $self = shift;
    my ($test, $fname) = @_;

    return 1 if ($test eq 'd' && ($fname eq '' || $fname eq '/'));
    return 0;
}

sub size {
    return 0;
}

sub list {
    return qw(. ..);
}

#################################################
#
# Test FS (stat)
#
#################################################

package TestFS2;

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
