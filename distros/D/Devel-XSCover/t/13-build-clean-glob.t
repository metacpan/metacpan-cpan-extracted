use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Build ();

sub dist {
    my ($clean, @files) = @_;
    my $dir = File::Temp->newdir;
    open my $fh, '>', File::Spec->catfile($dir, 'Makefile.PL') or die;
    print $fh "use ExtUtils::MakeMaker;\nWriteMakefile(\n    NAME => 'Foo::Bar',\n"
            . "    clean => { FILES => '$clean' },\n);\n";
    close $fh;
    for my $f (@files) {
        open my $t, '>', File::Spec->catfile($dir, $f) or die;
        close $t;
    }
    return $dir;
}

my $d = dist('Foo-Bar-* Foo.c', 'Foo-Bar-0.01.tar.gz', 'Foo-Bar-0.02.tar.gz');
my $b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([$b->clean_globs], ['Foo-Bar-*', 'Foo.c'], 'the globs');
is_deeply([sort map { (File::Spec->splitpath($_))[2] } $b->tarballs_at_risk],
    ['Foo-Bar-0.01.tar.gz', 'Foo-Bar-0.02.tar.gz'], 'both tarballs at risk');

$d = dist('$(DISTNAME)-* Foo.c', 'Foo-Bar-0.01.tar.gz');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([$b->clean_globs], ['Foo-Bar-*', 'Foo.c'], 'DISTNAME filled in');
is(scalar $b->tarballs_at_risk, 1, 'the tarball through DISTNAME');

$d = dist('$(DISTVNAME) Foo.c', 'Foo-Bar-0.01.tar.gz');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([$b->clean_globs], ['Foo.c'], 'an unknown macro is dropped');
is(scalar $b->tarballs_at_risk, 0, 'nothing at risk');

$d = dist('Foo-Bar-* Foo.c');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is(scalar $b->tarballs_at_risk, 0, 'no tarball, nothing at risk');

ok($b->needs_configure, 'no Makefile, configure needed');
my @warn;
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is($b->configure, 0, 'a dry configure');
}
is(scalar @warn, 0, 'no warning without a Makefile');

$d = dist('Foo-Bar-*', 'Foo-Bar-0.01.tar.gz', 'Makefile');
utime 1000000000, 1000000000, File::Spec->catfile($d, 'Makefile');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
ok($b->needs_configure, 'a stale Makefile, configure needed');
@warn = ();
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    $b->configure;
}
is(scalar @warn, 1, 'one warning');
like($warn[0], qr/stale Makefile reruns clean by itself.*Foo-Bar-0\.01\.tar\.gz/, 'it names the tarball');

utime time + 10, time + 10, File::Spec->catfile($d, 'Makefile');
ok(!$b->needs_configure, 'a fresh Makefile needs nothing');
is($b->configure, 0, 'and configure returns without running');

$d = dist('Foo-Bar-*', 'Makefile');
utime 1000000000, 1000000000, File::Spec->catfile($d, 'Makefile');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
@warn = ();
{
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is($b->configure, 0, 'a stale Makefile whose glob matches no archive configures');
}
is(scalar @warn, 0, 'without a warning');

$d = dist('Foo-Bar-* *.tar.gz', 'Foo-Bar-0.01.tar.gz');
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([map { (File::Spec->splitpath($_))[2] } $b->tarballs_at_risk],
    ['Foo-Bar-0.01.tar.gz'], 'an archive two globs match is named once');

$d = dist('Foo-Bar-*');
mkdir File::Spec->catfile($d, 'Foo-Bar-0.01.tar.gz') or die;
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([$b->tarballs_at_risk], [], 'a directory named like an archive is not one');

$d = File::Temp->newdir;
open my $fh, '>', File::Spec->catfile($d, 'Makefile.PL') or die;
print $fh "use ExtUtils::MakeMaker;\nWriteMakefile(\n    clean => { FILES => 'Foo-Bar-* \$(DISTNAME)-*' },\n);\n";
close $fh;
open $fh, '>', File::Spec->catfile($d, 'Foo-Bar-0.01.tar.gz') or die;
close $fh;
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is_deeply([$b->clean_globs], ['Foo-Bar-*', '-*'], 'without a NAME the distribution name is empty');
is_deeply([map { (File::Spec->splitpath($_))[2] } $b->tarballs_at_risk],
    ['Foo-Bar-0.01.tar.gz'], 'and the plain glob still finds the archive');

$d = File::Temp->newdir;
open $fh, '>', File::Spec->catfile($d, 'Makefile') or die;
close $fh;
$b = Devel::XSCover::Build->new(dir => "$d", dry => 1, silent => 1);
is($b->needs_configure, 1, 'a Makefile without a Makefile.PL still needs configure');
is_deeply([$b->clean_globs], [], 'no Makefile.PL gives no globs');
is_deeply([$b->tarballs_at_risk], [], 'and nothing at risk');

done_testing;
