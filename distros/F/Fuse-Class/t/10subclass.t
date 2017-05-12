
use strict;

use Test::More tests => 14;

#################################################
package TestClass;

use base qw(Fuse::Class);

sub getdir {
    my $self = shift;
    my ($dir) = @_;

    return (".", "..", "x$dir", 0);
}

sub mknod {
    my $self = shift;
    my ($fname) = @_;

    $! = Errno::EINTR;
    die "error";
}

sub mkdir {
    my $self = shift;
    my ($fname) = @_;

    $! = 0;
    die "error";
}

#################################################

package main;

my %Fuse_main;

#
# override Fuse::main for test
#
{
    no warnings "redefine";
    no strict "refs";

    *Fuse::main = sub {
	%Fuse_main = @_;
	for my $k (keys %Fuse_main) {
	    my $subname = $Fuse_main{$k};
	    $Fuse_main{$k} = sub { &$subname(@_); };
	}
    };
}

use Errno;

my $fs = TestClass->new();
is(ref($fs), "TestClass", "constructor");

$fs->main(mountpoint => "/never-found");
$Fuse::Class::_Module = $fs; # set in Fuse::Class

# overrided method
my $getdir = $Fuse_main{getdir};
is_deeply([&$getdir("abc")], [".", "..", "xabc", 0]);

# error (in $!)
my $mknod = $Fuse_main{mknod};
is(&$mknod("/never-found"), -Errno::EINTR());

# error (not in $!)
my $mkdir = $Fuse_main{mkdir};
is(&$mkdir("/never-found"), -Errno::EPERM());

# not implemented
my $getattr = $Fuse_main{getattr};
is($fs->can('getattr') ? &$getattr("/") : -Errno::EPERM(), -Errno::EPERM());

# default implement
is($fs->readlink("/not/found"), -Errno::ENOENT());
is($fs->statfs(), -Errno::ENOANO());
is($fs->flush("/some/file"), 0);
is($fs->release("/some/file"), 0);
is($fs->fsync("/some/file"), 0);
is($fs->getxattr("/some/file"), 0);
is($fs->listxattr("/some/file"), 0);
is($fs->removexattr("/some/file"), 0);
is($fs->setxattr("/some/file", "name", "value", 0), -Errno::EOPNOTSUPP());
