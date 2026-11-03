use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();

my $f = File::Spec->catfile(qw(t fixtures gcov gcc manual.gcov.txt));
open my $fh, '<', $f or die "$f: $!";
my $text = do { local $/; <$fh> };
close $fh;

my $files = Devel::XSCover::Gcov->new(silent => 1)->parse($text);
is_deeply([sort keys %$files], ['/usr/include/stdio.h', 'tmp.c'], 'two sources');
my $c = $files->{'tmp.c'};
is_deeply($c->{lines}, { 3 => 1, 5 => 1, 6 => 1, 8 => 11, 9 => 10, 10 => 1, 11 => 1, 12 => 0, 14 => 1, 15 => 1, 18 => 0, 19 => 0, 20 => 0 },
    'the lines, with ##### and ===== as zero');
is_deeply($c->{functions}, [ { name => 'main', line => 3, count => 1 }, { name => 'cleanup', line => 18, count => 0 } ],
    'two functions, the second never called');
is_deeply($c->{blocks}, [
    { line => 8,  arms => [10, 1] },
    { line => 10, arms => [0, 1] },
    { line => 11, arms => [0, 1] },
    { line => 19, arms => [0, 0] },
], 'the blocks with arms, fallthrough notes and never executed arms read, blocks without arms dropped');
is_deeply($files->{'/usr/include/stdio.h'}{lines}, { 100 => 1 }, 'a trailing * on a count is dropped');

done_testing;
