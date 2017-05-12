#
# Tests using Filesys::Virtual::Plain
#
# rename
#

use strict;

use Test::More tests => 11;

use Cwd;
use File::Path;
use POSIX qw(:errno_h :fcntl_h);

use Fuse::Filesys::Virtual;

sub content {
    my $file = shift;
    open(my $fh, $file) or die "$file: $!";
    local $/;
    my $ret = <$fh>;
    close($fh);

    return $ret;
}

sub prepare_content {
    my $file = shift;
    my $content = shift;

    open(my $fh, ">$file") or die "$file: $!";
    print $fh $content;
    close($fh);
}

SKIP: {
    eval "use Filesys::Virtual::Plain";
    my $fvp_installed = $@ ? 0 : 1;
    skip "Filesys::Virtual::Plain is not unstalled", 1 unless ($fvp_installed);

    my $dir = getcwd;
    my $testroot = "$dir/t/testdir";

    rmtree([$testroot]);
    mkpath([$testroot], 0, 0755);

    my $plain = TestNotSeekableFS->new({root_path => $testroot });
    # ugly...
    $plain->{uid} = $<;
    $plain->{gid} = $(;

    my $fs = Fuse::Filesys::Virtual->new($plain, {debug => 1});

    # create a file
    is($fs->mknod("/test.txt", 0644, 0), 0);
    ok(-f "$testroot/test.txt");
    is($fs->write("/test.txt", "xyz", 0), 3);
    is($fs->write("/test.txt", "abc", 4), 3);
    is($fs->flush("/test.txt"), 0);
    is($fs->fsync("/test.txt", 1), 0);
    is($fs->release("/test.txt"), 0);
    is(content("$testroot/test.txt"), "xyzabc");

    # read it.
    is($fs->open("/test.txt", O_RDONLY), 0);
    my $data = $fs->read("/test.txt", 3, 3);
    is($data, "abc");
    is($fs->release("/test.txt"), 0);
};

#################################################
#
# Test FS
#
#################################################

package TestNotSeekableFS;

use Carp;

my $initialized;
use vars qw(@ISA);

sub new {
    my $class = shift;
    unless ($initialized) {
	$initialized = 1;

	eval "use Filesys::Virtual::Plain";
	push(@ISA, "Filesys::Virtual::Plain");
    }

    my $self = Filesys::Virtual::Plain->new(@_);
    bless $self, $class;
}

sub seek {
    my $self = shift;
    $self->Filesys::Virtual::seek(@_);
}
