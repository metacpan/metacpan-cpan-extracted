#!/usr/bin/perl -w
use lib '../blib/lib';
use Games::WordFind;
use strict;
use vars qw(@words $opt_l $opt_c $opt_w $opt_d 
            $opt_s $opt_o $opt_i $opt_html);
use Getopt::Long;

Getopt::Long::config("bundling");
GetOptions ('-l','-c=i','-o=s','-w','-d','-s','-i','-html') or die Usage();
#do any special options processing
$opt_c||=10;
if ($opt_l) {
    if ($opt_o){
        $opt_o.='.tex' unless $opt_o=~m/\.tex$/;
    }
}
if ($opt_d) {
    $opt_l=1;
    $opt_w=1;
    $opt_o||='puzzle.tex';
    $opt_o.='.tex' unless $opt_o=~m/\.tex$/;
}
# get wordlist from command line, or use defaults
@words=@ARGV;
@words||(@words=qw(great perl linux camel llama));

# create new WordFind object
my $new_puz = Games::WordFind->new({cols=>$opt_c,intersect=>$opt_i});

# create the puzzle
$new_puz->create_puzzle(@words);

# get a text or latex version of the puzzle
my $out;
if ($opt_l) {
    $out=$new_puz->get_latex({wrapper=>$opt_w,solution=>$opt_s});
} elsif ($opt_html) {
    $out=$new_puz->get_html({wrapper=>$opt_w,solution=>$opt_s});
} else {
    $out=$new_puz->get_plain({solution=>$opt_s});
}

# assign an output filehandle or stdout
my $fh;
if ($opt_o) {
    open(FILE,">$opt_o")||die "can't open $opt_o $!";
    $fh=\*FILE;
} else {
    $fh=\*STDOUT;
}

# print the puzzle
print $fh $out;
close $fh;

# make a dvi and remove intermediary files
if ($opt_d) {
    my $base = $1 if $opt_o=~m/^(.*)\.tex$/;
    system("latex $base");
    my @exts=qw(.aux .log .tex);
    unlink map{"$base$_"}@exts;
}

sub Usage {
    print<<EOF;
try.pl [-lwdsi] [--html] [-o outputfile] [-c columns] word list 
try.pl [-dsi] [-c columns] word list >outfile
    -l  generate latex source in tabular environment
    -w  put complete latex or html wrapper around puzzle
    -d  make a dvi (implies -l -w) and remove *.tex *.log *.aux
    --html generate html source (table)
    -s  also return the solution matrix
    -i  allow intersecting words in the puzzle (sharing letters)
    -c <columns>  size of puzzle matrix
    -o <outputfile>   print to file rather than stdout: if -l or -d
                      then .tex is added if not already present
EOF
}

=head1 NAME

wordpuzzle.pl - Script using WordFind.pm to generate puzzles

=head1 SYNOPSIS

    wordfind.pl [-lwsi] [-o outfile] [-c columns] wordlist
    wordfind.pl [-dsi] [-c columns] wordlist >outfile

=head1 DESCRIPTION

This script uses the WordFind.pm module to create simple puzzles
by embedding each word (forwards, backwards, up, down, or diagonally)
from the wordlist into a lattice of random letters.

=head1 OPTIONS

=over 4

=item -c <columns>

This option takes an integer for the size of the puzzle. The
default is a 10x10 lattice, using B<-c> 12 would create a
12x12 puzzle. If you enter words longer than <columns>, a
warning is issued from WordFind.pm and the word is dropped
from the list.

=item -o <outfile>

Takes a string as the name of an output file. If in latex mode
and no .tex extension is given, one is silently added.

=item -l

Latex mode: return a puzzle in latex tabular format. The puzzle
generated has C<\huge> letters for easier viewing for kids.

=item -w

This puts a complete latex wrapper around the latex puzzle so that
the result is directly compilable by latex.

=item -d

DVI mode: implies B<-l> and B<-w>. Automatically runs latex on
the output file to produce a .dvi file, and removes the output
file and other intermediary files. If no output file is specified,
a default F<puzzle.tex> is used and the resulting dvi file will
be F<puzzle.dvi>.

=item -s

By default, the solution matrix is not returned. Using this
option, the returned puzzle will include the solution matrix.
In latex mode, the solution will come after a latex C<\newpage> command
and be set in its own tabular environment.

=item -i

By default, no two words can intersect (share letters) in the
puzzle. If B<-i> is used, intersecting words will be allowed
in the puzzle (but not guaranteed of course).

=head1 AUTHOR

Andrew L Johnson <ajohnson@gpu.srv.ualberta.ca>

=head1 SEE ALSO

Please also refer to the embedded documentation in
the F<WordFind.pm> module.

=cut

