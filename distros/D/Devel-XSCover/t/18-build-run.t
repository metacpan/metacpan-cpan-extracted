use 5.020;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use XSCoverTest ();
use Devel::XSCover::Build ();

plan skip_all => 'shell scripts stand in for make and perl here' if $^O eq 'MSWin32';

my $bin = File::Temp->newdir;
my $log = File::Spec->catfile($bin, 'log');
my $make     = XSCoverTest::fake_script($bin, 'make', "echo \"make \$* in \$(pwd)\" >> '$log'");
my $make_bad = XSCoverTest::fake_script($bin, 'make-bad', 'exit 2');
my $perl_ok  = XSCoverTest::fake_script($bin, 'perl-ok', "echo \"perl \$*\" >> '$log'\ntouch Makefile");
my $perl_bad = XSCoverTest::fake_script($bin, 'perl-bad', "echo \"perl \$*\" >> '$log'\nexit 3");
my @flags = (
    'OPTIMIZE=-O0 -g -fprofile-arcs -ftest-coverage -fprofile-update=atomic',
    'OTHERLDFLAGS=-fprofile-arcs -ftest-coverage',
);

sub dist {
    my $dir = File::Temp->newdir;
    for my $name (qw(Makefile.PL Foo.xs)) {
        my $path = File::Spec->catfile($dir, $name);
        open my $fh, '>', $path or die "$path: $!";
        print $fh $name eq 'Makefile.PL' ? "use ExtUtils::MakeMaker;\nWriteMakefile(NAME => 'Foo');\n" : "x\n";
        close $fh;
        utime 1000000000, 1000000000, $path;
    }
    return $dir;
}

sub logged {
    open my $fh, '<', $log or return ();
    chomp(my @lines = <$fh>);
    close $fh;
    return @lines;
}

sub build {
    return Devel::XSCover::Build->new(make => $make, perl => $perl_ok, conditions => 0, silent => 1, @_);
}

my $dir  = dist();
my $real = Cwd::abs_path("$dir");
my $b    = build(dir => "$dir");
is($b->dir, "$dir", 'dir is the directory given');
is($b->run, 0, 'configure, touch and build all succeed');
is_deeply([logged()], ['perl Makefile.PL', "make @flags in $real"], 'perl Makefile.PL ran, then make with the flags, in the directory');
cmp_ok((stat File::Spec->catfile($dir, 'Foo.xs'))[9], '>', 1000000000, 'the source was touched between them');
is($b->needs_configure, 0, 'the Makefile the configure wrote is fresh');

unlink $log;
$dir = dist();
$b   = build(dir => "$dir", perl => $perl_bad);
is($b->run, 3, 'a failing configure stops the run with its status');
is_deeply([logged()], ['perl Makefile.PL'], 'make never ran');
is((stat File::Spec->catfile($dir, 'Foo.xs'))[9], 1000000000, 'and nothing was touched');

is(build(dir => "$dir", make => $make_bad)->build, 2, "make's own status comes through");
{
    open my $saved, '>&', \*STDERR or die "dup STDERR: $!";
    open STDERR, '>', File::Spec->devnull or die "devnull: $!";
    my $status = build(dir => "$dir", make => File::Spec->catfile($bin, 'no-such-make'))->build;
    open STDERR, '>&', $saved or die "restore STDERR: $!";
    is($status, 127, 'a make that cannot be started is 127');
}

my $gone = File::Spec->catdir($dir, 'gone');
eval { build(dir => $gone)->configure };
like($@, qr/^xs_cover: cannot chdir to \Q$gone\E: /, 'a directory that is not there dies naming it');

unlink $log;
$real = Cwd::abs_path("$dir");
my $here = Cwd::getcwd();
chdir $dir or die "$dir: $!";
my $status = build()->build;
chdir $here or die "$here: $!";
is($status, 0, 'the default directory is the current one');
is_deeply([logged()], ["make @flags in $real"], 'and make runs there without a chdir');

done_testing;
