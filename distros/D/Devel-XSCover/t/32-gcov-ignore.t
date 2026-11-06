use 5.020;
use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();

my $dir = File::Temp->newdir;
my $abs = Cwd::abs_path("$dir");
File::Path::make_path(File::Spec->catdir($dir, 'src'));
{
    open my $fh, '>', File::Spec->catfile($dir, 'src', 'helper.c') or die "$dir/src/helper.c: $!";
    close $fh;
}
my %entry = (lines => { 1 => 1 }, functions => [], blocks => []);
my $files = {
    'Spike.xs'                      => { %entry },
    './xs/more.xs'                  => { %entry },
    'Spike.c'                       => { %entry },
    'ppport.h'                      => { %entry },
    'include/ppport.h'              => { %entry },
    'vendor/zlib.c'                 => { %entry },
    "$abs/src/helper.c"             => { %entry },
    '/opt/perl/lib/CORE/inline.h'   => { %entry },
    '/usr/include/stdio.h'          => { %entry },
};

my $reader = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1, generated => ['Spike.c'], ignore => ['^vendor/']);
my ($kept, $aside) = $reader->filter($files);
is_deeply([sort keys %$kept], ['Spike.xs', 'src/helper.c', 'xs/more.xs'],
    'kept: the xs, the included xs without its ./, and the absolute path under the dir made relative');
is_deeply([sort keys %$aside], ['Spike.c'], 'the generated c kept aside');

($kept, $aside) = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1)->filter($files);
is_deeply([sort keys %$kept], ['Spike.c', 'Spike.xs', 'src/helper.c', 'vendor/zlib.c', 'xs/more.xs'],
    'without generated and ignore: the c is a file, vendor stays, ppport.h and the outside never');
is_deeply($aside, {}, 'nothing aside');

my $gone = File::Spec->catdir($dir, 'gone', 'deeper');
($kept, $aside) = Devel::XSCover::Gcov->new(dir => $gone, silent => 1)->filter({
    'Spike.xs'               => { %entry },
    "$gone/src/helper.c"     => { %entry },
    "$dir/src/other.c"       => { %entry },
});
is_deeply([sort keys %$kept], ['Spike.xs', 'src/helper.c'],
    'a directory that is not there yet is still the root: relative paths kept, absolute ones measured against it as written');

($kept, $aside) = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1)->filter({
    'helper.c'   => { %entry },
    'Spike.xs'   => { %entry },
    'missing.c'  => { %entry },
}, 'src/helper.gcda');
is_deeply([sort keys %$kept], ['Spike.xs', 'missing.c', 'src/helper.c'],
    'a name an object in a subdirectory wrote relative to itself is placed beside its counter file, the rest as written');

{
    local $^O = 'MSWin32';
    ($kept, $aside) = Devel::XSCover::Gcov->new(dir => "$dir", silent => 1)->filter({
        'Spike.xs'           => { %entry },
        'src\\helper.c'      => { %entry },
        "$abs\\xs\\more.xs"  => { %entry },
    });
    is_deeply([sort keys %$kept], ['Spike.xs', 'src/helper.c', 'xs/more.xs'],
        'on Windows a name the compiler wrote with backslashes is kept with slashes, as Devel::Cover spells its own');
}

done_testing;
