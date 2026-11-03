use 5.020;
use strict;
use warnings;
use Test::More;
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Build ();

my $dir = File::Temp->newdir;
my @sources = qw(Foo.xs xs/a.xs src/b.c include/c.h lib/Foo/Bar.xs src/d.cpp include/e.hpp);
my @others  = qw(lib/Foo.pm README blib/arch/x.c cover_db/y.c .git/z.h Foo.o Foo.c.gcov);
for my $rel (@sources, @others) {
    my $path = File::Spec->catfile($dir, $rel);
    my ($vol, $d) = File::Spec->splitpath($path);
    File::Path::make_path(File::Spec->catpath($vol, $d, ''));
    open my $fh, '>', $path or die "$path: $!";
    print $fh "x\n";
    close $fh;
    utime 1000000000, 1000000000, $path;
}

my $out = '';
my @touched;
{
    open my $fh, '>', \$out or die;
    my $old = select $fh;
    @touched = Devel::XSCover::Build->new(dir => "$dir")->touch;
    select $old;
}
is(scalar @touched, scalar @sources, 'every source touched, nothing else');
like($out, qr/touched 7 source files/, 'the count is said');
for my $rel (@sources) {
    cmp_ok((stat File::Spec->catfile($dir, $rel))[9], '>', 1000000000, "$rel is newer");
}
for my $rel (@others) {
    is((stat File::Spec->catfile($dir, $rel))[9], 1000000000, "$rel untouched");
}

utime 1000000000, 1000000000, File::Spec->catfile($dir, 'Foo.xs');
Devel::XSCover::Build->new(dir => "$dir", dry => 1, silent => 1)->touch;
is((stat File::Spec->catfile($dir, 'Foo.xs'))[9], 1000000000, 'a dry touch changes nothing');

done_testing;
