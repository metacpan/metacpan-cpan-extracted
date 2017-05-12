package Games::WordFind;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';

# declare some package-wide globals
my $lim;
my @letters=("A".."Z");
my @direction=qw(n ne nw e w se s sw);
my $trials=50;

# given a direction, where can a word start and still fit
# in the desired direction:
my %range_hash=(
   'n'  => sub {return ([0..$lim],[(length($_[0])-1)..$lim])},
   's'  => sub {return ([0..$lim],[0..($lim-length($_[0]))])},
   'e'  => sub {return ([0..($lim-length($_[0]))],[0..$lim])},
   'w'  => sub {return ([(length($_[0])-1)..$lim],[0..$lim])},
   'ne' => sub {return ([0..($lim-length($_[0]))],[(length($_[0])-1)..$lim])},
   'nw' => sub {return ([(length($_[0])-1)..$lim],[(length($_[0])-1)..$lim])},
   'se' => sub {return ([0..($lim-length($_[0]))],[0..($lim-length($_[0]))])},
   'sw' => sub {return ([(length($_[0])-1)..$lim],[0..($lim-length($_[0]))])},
   );

# given a direction, how do we adjust the indices for
# subsequent letters when inserting a word:
my %dir_hash=(
   'n'  => [-1,0],
   's'  => [1,0],
   'e'  => [0,1],
   'w'  => [0,-1],
   'ne' => [-1,1],
   'nw' => [-1,-1],
   'se' => [1,1],
   'sw' => [1,-1]
   );


sub new {
    my $that=shift;
    my $class=ref($that)||$that;
    my $self=shift||{};
    $self->{cols}||=10; # default size
    bless $self,$class;
    return $self;
}

# build the intitial lattice with elements of '*'
sub init {
    my $self=shift;
    $self->{lattice}=undef;
    for (0..$self->{cols}-1) {
        push @{$self->{lattice}[$_]},("*")x$self->{cols};
    }
}

sub create_puzzle {
    my $self=shift;
    $self->init();
    @{$self->{words}}=@_;
    my %dropped; #for storing words that don't fit
    $self->{'dropped'}=\%dropped;
    foreach my $word (@{$self->{words}}) {
       if ($self->check_length($word)) {
            warn "Warning: dropping $word, too long!\n";
            $dropped{$word}++;
            next;
       }
       $self->{success}=0;
       my $tries=0;
       until ($self->{success}) {
          $tries++;
          $self->get_direction();
          $self->insert_word($word);
          if ($tries>$trials) {
            warn "too many tries on $word: Dropping $word!\n";
            $dropped{$word}++;
            $self->{success}=1; #its dropped, get out of until loop!
          }
       }
    }
# lattice has words inserted now, and will function as
# a solution matrix --- now copy lattice words into puzzle
# and fill remainder with random letters:
    foreach my $i (0..$#{$self->{lattice}}) {
       foreach my $j (0..$#{$self->{lattice}[$i]}) {
          if ($self->{lattice}[$i][$j] ne '*') {
             $self->{puzzle}[$i][$j]=$self->{lattice}[$i][$j];
          } else {
             $self->{puzzle}[$i][$j]=$letters[rand(@letters)];
          }
       }
    }
# for output, remove 'dropped' words from wordlist and 
# sort and up-case the words actually used in the puzzle:
    @{$self->{words}}=map{"      \U$_"}
            sort grep !$dropped{$_},@{$self->{words}};
# hmm, let's actually return ref's to the lattice and such
# so user's can format them however they want if desired:
    my @solution=@{$self->{lattice}};
    my @puzzle=@{$self->{puzzle}};   
    my @words=@{$self->{words}};     
    return \(@puzzle,@words,@solution);
}

sub check_length {
   my $self=shift;
   return 0 if length($_[0]) <= $self->{cols};
   return 1;
}
sub get_direction {
    my $self=shift;
    $self->{dir}=$direction[rand(@direction)];
}

sub insert_word {
    my $self=shift;
    my $word = shift;
    $word=uc($word);
    $lim=$self->{cols}-1;
    my @ranges = $range_hash{$self->{dir}}->($word);
    unless (@{$ranges[0]} && @{$ranges[1]}) {
        $self->{success}= 0;
        return 0;
    }
    my @x=@{$ranges[0]};
    my @y=@{$ranges[1]};
    my ($j,$i)=($x[rand(@x)],$y[rand(@y)]);
    my @word=split //,$word;
    my @lat_refs=();
    foreach my $letter (@word) {
        if ($self->{intersect}) { #share letters in puzzle
            if ($self->{lattice}[$i][$j] eq '*' ||
                        $self->{lattice}[$i][$j] eq $letter) {
                push @lat_refs,\$self->{lattice}[$i][$j];
                $i+=$dir_hash{$self->{dir}}->[0];
                $j+=$dir_hash{$self->{dir}}->[1];
            } else {
                $self->{success}= 0;
                return 0;
            }        
        } else { # don't share letters
            if ($self->{lattice}[$i][$j] eq '*') {
                push @lat_refs,\$self->{lattice}[$i][$j];
                $i+=$dir_hash{$self->{dir}}->[0];
                $j+=$dir_hash{$self->{dir}}->[1];
            } else {
                $self->{success}= 0;
                return 0;
            }
        } #end if intersect
    }# end foreach 

    # ok, we have a word and it fits...just assign the letters
    # to the references of the lattice:
    foreach my $l_ref (@lat_refs) {
        $$l_ref=shift @word;
    }
    $self->{success}= 1; # we made it
}

# return a puzzle formatted in plain text, with solution
# matrix appended if $opts_ref->{solution} non-zero
sub get_plain {
    my $self=shift;
    my $opts_ref=shift;
    my @words=@{$self->{words}};
    my $puzzle='';
    $puzzle.= "\t\tWords to Find:\n";
    $puzzle.= "\t\t--------------\n\n";
    while (@words) {
        my @line=@words>2?splice(@words,0,3):splice(@words,0);
        $puzzle.= join("\t",@line)."\n";
    }
    $puzzle.= "\n";
    foreach my $ref (@{$self->{puzzle}}) {
        $puzzle.= "\t\t@$ref\n";
    }
    if ($opts_ref->{solution}) {
        $puzzle.= "\nSolution:\n";
        foreach my $ref (@{$self->{lattice}}) {
            $puzzle.= "\t\t@$ref\n";
        }
    }
    return $puzzle;
}

# return a puzzle formatted in latex tabular form
#   -solution on second page if $opts_ref->{solution} non-zero
#   -complete latex wrapper if $opts_ref->{wrapper} non-zero
sub get_latex {
    my $self=shift;
    my $opts_ref=shift;
    my @words=@{$self->{words}};
    my $title="{\\Large \\textbf{Find The Following Words:}}";
    my $puzzle='';

$puzzle.=<<EOF;
%% the arraystretch and tabcolsep values used here were found
%% by visual experimentation, not appropriate for other text sizes
\\renewcommand{\\arraystretch}{2.25}
\\renewcommand{\\tabcolsep}{5pt}
\\begin{center}
\\begin{tabular}{lllll}
\\multicolumn{5}{c}{$title}\\\\ \\hline 
EOF

    @words=map{"{\\Large $_}"}@words;
    while (@words) {
        my @line=@words>2?splice(@words,0,3):splice(@words,0);
        if (@line<3) {
            @line=@line==2?(@line,''):(@line,'','');
        }
        $puzzle.= join('& &',@line)."\\\\ \n";
    }

$puzzle.=<<EOF;
\\end{tabular}
\\end{center}
EOF

    my $c=$self->{cols};
    $c='c'x$c;

$puzzle.=<<EOF;
\\begin{center}
\\begin{tabular}{$c}
EOF

    foreach my $ref (@{$self->{puzzle}}) {
        @$ref=map{"{\\huge $_}"}@$ref;
        $puzzle.= join('&',@$ref)."\\\\ \n";
    }

$puzzle.=<<EOF;
\\end{tabular}
\\end{center}
EOF
    
    if ($opts_ref->{solution}) {

$puzzle.=<<EOF;
\\newpage
\\begin{center}
\\begin{tabular}{$c}
EOF

        foreach my $ref (@{$self->{lattice}}) {
            @$ref=map{"{\\huge $_}"}@$ref;
            $puzzle.= join('&',@$ref)."\\\\ \n";
        }

$puzzle.=<<EOF;
\\end{tabular}
\\end{center}
EOF
    } # end if solution

    if ($opts_ref->{wrapper}) {

$puzzle=<<EOF;
\\documentclass[10pt,letterpaper,]{article}
\\oddsidemargin -1in
\\textwidth 8.5in
\\begin{document}
\\pagestyle{empty}
$puzzle
\\end{document}
EOF
    } # end if wrapper
    return $puzzle;
}

#############################
#############################
sub get_html {
    my $self=shift;
    my $opts_ref=shift;
    my @words=@{$self->{words}};
    my $title="<H1 align=center>Find The Following Words:</H1>";
    my $puzzle='';

$puzzle.=<<EOF;
$title
<hr width="50%">
<center>
<table>
EOF

    while (@words) {
        my @line=@words>2?splice(@words,0,3):splice(@words,0);
        if (@line<3) {
            @line=@line==2?(@line,''):(@line,'','');
        }
        $puzzle.= '<tr align=center><td><strong>'.
              join('</td><td><strong>',@line)."</td></tr>\n";
    }

$puzzle.="</table>\n";

    my $c=$self->{cols};
    $c='c'x$c;

$puzzle.="<table border=1>\n";

    foreach my $ref (@{$self->{puzzle}}) {
        @$ref=map{"<strong><font size=+5> $_"}@$ref;
        $puzzle.='<tr align=center><td width=30>'. 
              join('</td><td width=30>',@$ref)."</td></tr>\n";
    }

$puzzle.="</table>\n";
    
    if ($opts_ref->{solution}) {

$puzzle.="<hr><hr><code>Solution:<br><table border=1>\n";

        foreach my $ref (@{$self->{lattice}}) {
            @$ref=map{"<code> $_"}@$ref;
            $puzzle.='<tr align=center><td>'. 
                  join('</td><td>',@$ref)."</td></tr>\n";
        }

$puzzle.="</table>\n";
    } # end if solution

    if ($opts_ref->{wrapper}) {

$puzzle=<<EOF;
<html>
<head><title> WordFind </title></head>
<body>
$puzzle
</body>
<html>
EOF
    } # end if wrapper
    return $puzzle;
}

#############################

1;
__END__

=head1 NAME

WordFind - Class for generating Word Find type puzzles

=head1 SYNOPSIS

    use Games::WordFind;
    $puz=Games::WordFind->new({cols=>10});
    @words=qw(perl camel llama linux great);
    $puz->create_puzzle(@words);
    print $puz->get_plain();
    
    or,
    print $puz->get_latex();

=head1 DESCRIPTION

This module simply provides a class which can be
used to generate WordFind type puzzles. It is simple
to use, the relevant methods are:

=over 4

=item $puzzle = Games::WordFind->new({cols => 10,intersect=>1});

Obviously, this returns a WordFind object. By default the puzzle
created by this object is a 10x10 lattice---you may give an
optional hash reference with a 'cols' as the key and some number
as the value for the size of the lattice. You may also provide an
'intersect' key, which allows words to intersect in the puzzle
(share letters) when set to a non-zero value.

=item $puzzle->create_puzzle(LIST)

This method takes the LIST of words and creates the puzzle. Any
words which are longer than the number of columns in the puzzle
are dropped from the wordlist and a warning is issued. This
method will return references to three arrays; a two dimensional
array of the puzzle, an array of the words used, and a two
dimensional array of the puzzle solution. These are so you can
format your puzzle output yourself rather than using the latex or
html formatting functions described next.

=item $puzzle->get_plain({solution => 1})

This method gets the puzzle and its solution matrix
in a plain text format. If you supply the optional
hash reference with a non-zero value for 'solution',
a solution matrix is included immediately following
the puzzle. 

=item $puzzle->get_latex({solution => 1, wrapper => 1})

This method a latex formatted version of the puzzle containing
tabular environments to set the puzzle and solution (a newpage
separates the two). The optional hash argument can contain the
key 'wrapper' which tells the method to return the puzzle wrapped
with a latex preamble, and the key 'solution' which will return
the solution matrix after a C<\newpage> command in the latex source.

=item $puzzle->get_html({solution =>1, wrapper =>1})

Similar to the latex method, though, of course, there is no
newpage separation of the solution.

=back

=head1 AUTHOR

Andrew L Johnson <ajohnson@gpu.srv.ualberta.ca>

=head1 Copyright

WordFind.pm and wordfind.pl are copyright (c) 1997,1998 Andrew L
Johnson. This is free software and you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1).

=cut
