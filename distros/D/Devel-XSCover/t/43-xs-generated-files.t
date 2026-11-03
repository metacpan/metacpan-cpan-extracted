use 5.020;
use strict;
use warnings;
use Test::More;
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::XS ();

sub tree {
    my ($makefile, @files) = @_;
    my $dir = File::Temp->newdir;
    for my $rel (@files) {
        my $path = File::Spec->catfile($dir, $rel);
        my ($vol, $d) = File::Spec->splitpath($path);
        File::Path::make_path(File::Spec->catpath($vol, $d, ''));
        open my $fh, '>', $path or die "$path: $!";
        close $fh;
    }
    if (defined $makefile) {
        open my $fh, '>', File::Spec->catfile($dir, 'Makefile.PL') or die;
        print $fh $makefile;
        close $fh;
    }
    return $dir;
}

my $d = tree(undef, qw(Op.xs Op.c lib/Math/Basic/XS.xs lib/Math/Basic/XS.c xs/more.xs blib/arch/Z.xs blib/arch/Z.c));
is_deeply([Devel::XSCover::XS->new(dir => "$d")->generated_files],
    [['Op.xs', 'Op.c'], ['lib/Math/Basic/XS.xs', 'lib/Math/Basic/XS.c']],
    'a top-level pair and an XSMULTI pair, an INCLUDEd xs without a c left out, blib skipped');

$d = tree("WriteMakefile(\n    XS => { 'Spike.xs' => 'generated/Spike.c' },\n);\n", qw(Spike.xs generated/Spike.c));
is_deeply([Devel::XSCover::XS->new(dir => "$d")->generated_files], [['Spike.xs', 'generated/Spike.c']], 'the XS entry of Makefile.PL names another c');

$d = tree("WriteMakefile(XS => { 'Op.xs' => 'Op.c' });\n", qw(Op.xs));
is_deeply([Devel::XSCover::XS->new(dir => "$d")->generated_files], [], 'an unbuilt dist has no generated files yet');

done_testing;
