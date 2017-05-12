# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-
#
# Mike Schilli, 2001 (m@perlmeister.com)
#

package Lingua::JPN::Number;
# ABSTRACT: Number 2 word conversion in JPN.

# {{{ use block

use 5.10.1;

use warnings;
use strict;

use Perl6::Export::Attrs;

# }}}
# {{{ variables declaration

our $VERSION     = 0.0682;

my %N2J = qw(
  1 ichi 2 ni 3 san 4 yon 5 go 6 roku 7 nana 
  8 hachi 9 kyu 10 ju 100 hyaku 1000 sen);

my %N2J_EXCP = qw(
  300 san-byaku 600 ro-p-pyaku 800 ha-p-pyaku
  3000 san-zen 8000 ha-s-sen);

my @N2J_BLOCK = ("", "man", "oku", "cho");

my %N2J_BLOCK_EXCP = qw( 1 i-t-cho 8 ha-t-cho 
  0 ju-t-cho);

# }}}

# {{{ to_string
sub to_string :Export {
    my $n = shift;

    if($n < 1 || $n >= 1E16) { 
        warn "$n needs to be >=1 and <1E16.\n";
        return;
    }

    my @result = ();
    $n         = reverse $n;
    my $bix    = 0;

    while($n =~ /(\d{1,4})/g) {
        my $b = scalar reverse($1);
        my @r = blockof4_to_string($b);

        if($bix && @r) {
            if($bix == 3 && 
                $b =~ /[1-9]0$|[18]$/) {
                $r[-1] =  $N2J_BLOCK_EXCP{$b%10};
            } else {
                push @r, $N2J_BLOCK[$bix];
            }
        }
        unshift @result, @r;
        $bix++; 
    }

    return @result;
}

# }}}
# {{{ blockof4_to_string

sub blockof4_to_string {
    my $n = shift;

    return if $n > 9999 or $n < 0;
    return "" unless $n;

    my @result  = ();
    my @digits  = split //, sprintf("%04d", $n);
    my @weights = (1000, 100, 10, 1);

    for my $i (0..3) {
        next unless $digits[$i];
        my $v = $digits[$i] * $weights[$i];
        push @result, $N2J_EXCP{$v} || 
                      $N2J{$v} ||
                      ($N2J{$digits[$i]},
                       $N2J{$weights[$i]});
    }

    return @result;
}

# }}}

1;

__END__

# {{{ module documentation

=head1 NAME

Lingua::JPN::Number - Translate Numbers into Japanese

=head1 VERSION

version 0.0682

=head1 SYNOPSIS

  use Lingua::JPN::Number;

  my @words = Lingua::JPN::Number::to_string(1234);

  print join('-', @words), "\n";
                        # "sen-ni-hyaku-san-ju-yon"

=head1 DESCRIPTION

Number 2 word conversion in JPN.

C<Lingua::JPN::Number> translates numbers into Japanese.
Its C<to_string> function takes a integer number
and transforms it to the equivalent cardinal 
number I<romaji> string. This'll show exactly how
the number is pronounced in Japanese.

Here's how the Japanese cardinal numbering scheme 
works: The numbers 1..10 translate
to I<ichi>, I<ni>, I<san>, I<yon>, I<go>, I<roku>,
I<nana>, I<hachi>, I<kyu>. 10 is I<yu>, 100 is
I<hyaku>, 1000 is I<sen> and 10000 is I<man>.

Similar to English, multi-digit numbers are 
put together using decimal weights: 15 is 
10 + 5, 723 is 7*100 + 2*10 + 3 and
6973 is 6*1000 + 9*100 + 7*10 + 3.
Therefore, 15 is pronounced I<yu-go>, 
123 is I<hyaku-ni-yu-san>
and 6973 is I<roku-san-kyu-hyaku-nana-san>.

Like in all natural languages, there's a
couple of exceptions: 300 isn't
I<san-hyaku> but I<san-byaku>,
600 isn't I<roku-hyaku> but I<ro-p-pyaku>
and 800 isn't I<hachi-hyaku> but I<ha-p-pyaku>.
Also, in the thousands, 3000 is I<san-zen>
and 8000 is I<ha-s-sen>. Also, there's more
exceptions for numbers of 1,000,000,000,000
and greater.

And, numbers aren't split into groups of 3
(like in 1,000,000) but in groups of 4, like
in 100,0000, which is pronounced I<hyaku-man>
(100 times 10000).

=head1 EXAMPLE

Here's a quick script I<jn> which will quiz
you with random numbers (or I<romaji> strings
if invoked as I<jn -r>) and reveal the solution
after you hit the I<Enter> key. It requires
C<Term::ReadKey>, which is available from CPAN:

    #!/usr/bin/perl
    use warnings;
    use strict;

    use Term::ReadKey;
    use Getopt::Std;
    use Lingua::JPN::Number qw(to_string);

    getopts('r', \ my %opts);

    my @length = (2, 3, 4);  # Prompt for 2-,3-
                             # and 4-digit numbers
    $| = 1;

    while(1) {
        my $digits = $length[rand(@length)];
        my $ques = int rand(10**$digits);
        next unless $ques;
        my $ans = join '-', to_string($ques);
        if($opts{r}) {
            ($ans, $ques) = ($ques, $ans);
        }
        print "$ques ... "; 
        ReadMode("noecho");
        ReadLine(0);
        ReadMode("normal");
        print $ans, "\n";
    }

=head1 BUGS

I've just taken a beginner's Japanese class,
so bear with me. Bug reports are most welcome.

Also, I'm planning on providing additional modules
C<Lingua::JPN::Number::Tall>,
C<Lingua::JPN::Number::Flat>,
C<Lingua::JPN::Number::Person>,
C<Lingua::JPN::Number::Misc> to cover the
idiosyncrasies of japanese counting of tall and
flat things, persons and miscellaneous items.

=head1 AUTHOR

 coding, maintenance, refactoring, extensions:
   Richard C. Jelinek <info@petamem.com>
 initial coding:
   Mike Schilli <m@perlmeister.com>

=head1 COPYRIGHT

Copyright (c) 2001 Mike Schilli. All rights
reserved. This program is free software; you can
redistribute it and/or modify it under the same
terms as Perl itself.

=cut

# }}}
