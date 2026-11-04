use 5.020;
use strict;
use warnings;
use Test::More;
use File::Spec ();
use Devel::XSCover::Gcov ();

sub slurp { my $f = File::Spec->catfile(@_); open my $fh, '<', $f or die "$f: $!"; local $/; <$fh> }

my $text = <<'GCOV';
File 'tmp.c'
Lines executed:100.00% of 2
        -:    0:Source:tmp.c
        -:    0:Graph:tmp.gcno
branch  0 taken 1
branch  1 taken 0
condition outcomes covered 1/2
condition  0 not covered (true)

        1:    3:int main(void)
    %%%%%:    4:    return 0;
    #####:    5:}
GCOV

my $reader = Devel::XSCover::Gcov->new(silent => 1);
my $files  = $reader->parse($text);
is_deeply([ keys %$files ], ['tmp.c'], 'the summary lines before the first source header name no file');
my $c = $files->{'tmp.c'};
is_deeply($c->{lines}, { 3 => 1, 5 => 0 }, 'a count marker that is not a number and not a known zero is not an executable line, and a blank line is nothing');
is_deeply($c->{blocks}, [ { line => 0, arms => [1, 0] } ], 'a branch before any source line lands on line 0 and the parse goes on');
is_deeply($c->{conditions}, [ { line => 0, covered => 1, total => 2, terms => [ { true => 0, false => 1 } ] } ], 'so does a decision before any source line');
is_deeply($c->{functions}, [], 'no function summary, no functions');

is_deeply($reader->parse("File 'tmp.c'\nLines executed:0.00% of 0\n"), {}, 'a text with no source header has no files');

my $twice = $reader->parse(slurp(qw(t fixtures gcov llvm helper.gcov.txt)) . slurp(qw(t fixtures gcov llvm Spike.gcov.txt)));
my $h = $twice->{'include/spike.h'};
is_deeply($h->{lines}, { 4 => 1, 6 => 1, 7 => 1, 8 => 1, 11 => 1, 13 => 1 },
    'a source named by two headers in one text keeps the lines of both, the later count on a line both have');
is_deeply([ map { $_->{name} } @{ $h->{functions} } ], [qw(spike_square spike_only_helper spike_square)], 'and the functions of both in order');

done_testing;
