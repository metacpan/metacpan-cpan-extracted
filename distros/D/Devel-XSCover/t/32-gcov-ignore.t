use 5.020;
use strict;
use warnings;
use Test::More;
use Cwd ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Gcov ();

my $dir = File::Temp->newdir;
my $abs = Cwd::abs_path("$dir");
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

done_testing;
