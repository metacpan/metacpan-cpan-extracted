#! perl -T

use Test::More tests => 74;

BEGIN {
    use_ok( 'File::Find::Node' );
}

diag( "Testing File::Find::Node $File::Find::Node::VERSION, Perl $], $^X" );

# Build the test directory

%ENV = ( "PATH" => "/bin:/usr/bin" );
ok(system(<<'E-O-F') == 0, "build test directory");
    set -e
    umask 022
    PATH=/bin:/usr/bin:/sbin:/usr/sbin
    test -d testdir && rm -rf testdir
    mkdir testdir testdir/subdir testdir/empty
    echo testjunk1     > testdir/regfile
    echo moreteststuff > testdir/subdir/regfile2
    mkfifo testdir/fifo
    ln -s regfile testdir/link
    ln -s nothing testdir/badlink
    ln -s .. testdir/subdir/cycle1
    ln -s .  testdir/subdir/cycle2
E-O-F

# Test new() return value

my $f = File::Find::Node->new("testdir");
isa_ok($f, "File::Find::Node", 'test new() return value');

# Test callbacks are called where expected

my $count = 0;
my $postcount = 0;

$f->process(sub {
    my $path = shift->path;
    $count++;
    ok(1, "test process() callback visits $path");
});
$f->post_process(sub {
    my $path = shift->path;
    $postcount++;
    ok($f->type eq "d",
        "test post_process() callback visits $path");
});
$f->find;

ok($count == 10, "test process() callback called 10 times (got $count)");
ok($postcount == 3,
    "test post_process() callback called 3 times (got $postcount)");

# Test prune() and empty() methods

$count = 0;
$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    $count++;
    if ($f->path eq "testdir/subdir") {
        $f->prune;
        ok(! $f->empty, "test empty() method for testdir/subdir");
    }
    if ($f->path eq "testdir/empty") {
        ok($f->empty, "test empty() method for testdir/empty");
    }
});
$f->find;
ok($count == 7, "test prune() method");

# Test follow() method

$count = 0;
$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    my $path = $f->path;
    ok($path ne "testdir/subdir/cycle1" &&
        $path ne "testdir/subdir/cycle2",
        "test $path not a cycle");
    $count++;
    if ($path eq "testdir/link") {
        ok($f->type eq "f", "test follow() method follows link");
    }
    if ($path eq "testdir/badlink") {
        ok($f->type eq "l", "test follow() method handles broken link");
    }
    $f->stop if $count > 20  # avoid infinite cycling
});
$f->follow->find;

ok($count == 8, "test follow() method avoids cycles");

# Test type() method

$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    my $path = $f->path;
    if ($path eq "testdir/subdir") {
        ok($f->type eq "d", 'test type() method returns "d" for directory');
    }
    if ($path eq "testdir/regfile") {
        ok($f->type eq "f", 'test type() method returns "f" for file');
    }
    if ($path eq "testdir/link") {
        ok($f->type eq "l", 'test type() method returns "l" for link');
    }
    if ($path eq "testdir/fifo") {
        ok($f->type eq "p", 'test type() method returns "p" for fifo');
    }
});
$f->find;

$f = File::Find::Node->new("/dev/null");
$f->process(sub {
    my $ftype = shift->type;
    ok($ftype eq "c", 'test type() method returns "c" for char device');
});
$f->follow->find;

# Test level() method

$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    my $path = $f->path;
    if ($path eq "testdir") {
        ok($f->level == 0, "test level() method returns 0 for $path");
    }
    if ($path eq "testdir/regfile") {
        ok($f->level == 1, "test level() method returns 1 for $path");
    }
    if ($f->path eq "testdir/subdir/regfile2") {
        ok($f->level == 2, "test level() method returns 2 for $path");
    }
});
$f->find;

# Test parent(), name() and path() methods

$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    if ($f->level > 0) {
        ok($f->parent->path . "/" . $f->name eq $f->path,
            "test parent(), name(), and path() methods for " . $f->path);
    }
});
$f->find;

# Test methods that return saved stat information

my @stat1 = lstat("testdir/regfile");
my (@stat2, @stat3);

$f = File::Find::Node->new("testdir/regfile");
$f->process(sub {
    my $f = shift;
    @stat2 = $f->stat;
    @stat3 = ($f->dev, $f->inum, $f->mode, $f->links, $f->uid,
        $f->gid, $f->rdev, $f->size, $f->atime, $f->mtime,
        $f->ctime, $f->blksize, $f->blocks);

    ok($f->perm == ($f->mode & 07777), "test perm() method");
    ok($f->ino == $f->inum,
        "test ino() and inum() methods are the same");
    ok($f->links == $f->nlink,
        "test links() and nlink() methods are the same");
    my $user = getpwuid($f->uid);
    ok($f->user eq $user || $f->user == $f->uid,
        "test user() method");
    my $group = getgrgid($f->gid);
    ok($f->group eq $group || $f->group == $f->gid,
        "test group() method");
});
$f->find;

is_deeply(\@stat1, \@stat2, "test stat() method");
is_deeply(\@stat1, \@stat3,
    "test dev(), inum(), mode(), etc., methods");

# Test refresh method

chmod(0644, "testdir/regfile");
$f = File::Find::Node->new("testdir/regfile");
$f->process(sub {
    my $f = shift;
    chmod(0755, $f->path);
    ok($f->perm == 0644 && $f->refresh->perm == 0755,
        "test refresh() method");
});
$f->find;

# Test filter() method

my (@list1, @list2);
$count = 0;

$f = File::Find::Node->new("testdir");
$f->process(sub {
    push(@list1, shift->path);
    $count++;
});
$f->filter(sub { sort(grep($_ ne "empty", @_)) })->find;

ok($count == 9, "test filter() method removes empty");
@list2 = sort(@list1);
is_deeply(\@list1, \@list2, "test filter() method sorts");

# Test stop() method

$count = 0;
$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    $f->stop if ++$count == 5;
});
$f->find;
ok($count == 5, "test stop() method");

# Test arg() method

$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    if ($f->type eq "d") {
        $f->arg->{count} = 1;
    }
    elsif ($f->parent) {
        $f->parent->arg->{count}++;
    }
});
$f->post_process(sub {
    my $f = shift;
    if ($f->path eq "testdir") {
        ok($f->arg->{count} == 10, "test arg() method with testdir");
    }
    if ($f->path eq "testdir/subdir") {
        ok($f->arg->{count} == 4, "test arg() method with testdir/subdir");
    }
    if ($f->path eq "testdir/empty") {
        ok($f->arg->{count} == 1, "test arg() method with testdir/empty");
    }
    if ($f->parent) {
        $f->parent->arg->{count} += $f->arg->{count};
    }
});
$f->find;

# Test fork() method

$count = 0;
my $pid = $$;
$f = File::Find::Node->new("testdir");
$f->process(sub {
    my $f = shift;
    my $path = $f->path;
    $count++;
    $f->fork(2) if $path eq "testdir/subdir";
    if ($path !~ m{^testdir/subdir/.+$}) {
        ok($$ == $pid, "test fork() main process visits $path");
    }
});
$f->post_process(sub {
    my $f = shift;
    return if $f->path ne "testdir";
    ok(wait > 0, "test fork() reaped a sub process");
});
$f->find;
ok($count == 7, "test fork() main process visited 7 nodes (got $count)");

# Test error_process() method

$f = File::Find::Node->new("testdir/subdir");
$f->error_process(sub {
    my ($f, $what) = @_;
    ok($f->path eq "testdir/subdir" && $what eq "opendir",
        "test error_process() readdir callback");
});
chmod(0111, "testdir/subdir");
$f->find;
chmod(0755, "testdir/subdir");

$f = File::Find::Node->new("testdir/bogus");
$f->error_process(sub {
    my ($f, $what) = @_;
    ok($f->path eq "testdir/bogus" && $what eq "stat",
        "test error_process() stat callback");
});
$f->find;

# Clean up

system("rm", "-rf", "testdir");
