package Math::Permutation;
 
use strict;
use warnings;
use Carp;
use List::Util qw/tail reduce any uniq none all sum first max min pairs mesh/;

# supportive math function
sub _lcm {
    return reduce { $a*$b/_gcd($a,$b) } @_;
}
 
sub _gcd {    # _gcd of two positive integers
    my $x = min($_[0], $_[1]);
    my $y = max($_[0], $_[1]);
    while ($x != 0) {
        ($x, $y) = ($y % $x, $x)
    }
    return $y;
}
 
sub _factorial {
    my $ans = 1;
    for (1..$_[0]) {
       $ans *= $_; 
    }
    return $ans;
}
 
sub eqv {
    my $wrepr  = $_[0]->{_wrepr};
    my $wrepr2 = $_[1]->{_wrepr};
    my $n      = $_[0]->{_n};
    my $n2     = $_[1]->{_n};
    return 0 if $n != $n2;
    my $check = 0;
    for (0..$n-1) {
        $check++ if $wrepr->[$_] == $wrepr2->[$_];
    }
    return $check == $n ? 1 : 0;
}
 
sub clone {
    my ($class) = @_;
    my $wrepr = $_[1]->{_wrepr};
    my $n = $_[1]->{_n};
    $_[0]->{_wrepr} = $wrepr;
    $_[0]->{_n} = $n;
}
 
sub init {
    my ($class) = @_;
    my $n = $_[1];
    bless {
        _wrepr => [1..$n],
        _n => $n,
    }, $class;
}
 
sub wrepr {
    my ($class) = @_;
    my $wrepr = $_[1] || [1];
    # begin: checking
    my $n = scalar $wrepr->@*;
    my %check;
    $check{$_} = 1 foreach $wrepr->@*;
    unless (all {defined($check{$_})} (1..$n)) {
        carp "Error in input representation. "
              ."The permutation will initialize to identity permutation "
              ."of $n elements.\n";
        $wrepr = [1..$n];
    }
    # end: checking
    bless {
        _wrepr => $wrepr,
        _n => $n,
    }, $class;
}
 
sub tabular {
    my ($class) = @_;
    my @domain = $_[1]->@*;
    my @codomain = $_[2]->@*;
    my $wrepr;
    my $n = scalar @domain;
    # begin: checking
    my %check1, my %check2;
    $check1{$_} = 1 foreach @domain;
    $check2{$_} = 1 foreach @codomain;
    my $check = 1;
    unless ( (all {defined($check1{$_})} (1..$n))
        && $n == scalar @codomain
        && (all {defined($check2{$_})} (1..$n)) ) {
        carp "Error in input representation. "
              ."The permutation will initialize to identity permutation "
              ."of $n elements.\n";
        $wrepr = [1..$n];
        $check = 0;
    }
    # end: checking
    if ($check) {
        my %w;
        $w{$domain[$_]} = $codomain[$_] foreach 0..$n-1;
        $wrepr = [ map {$w{$_}} 1..$n ];
    }
    bless {
        _wrepr => $wrepr,
        _n => $n,
    }, $class;
}
 
 
sub cycles {
    my ($class) = @_;
    my @cycles = $_[1]->@*;
    my $wrepr;
    my @elements;
    push @elements, @{$_} foreach @cycles;
    my $n = int max @elements;
    # begin: checking
    my $check = 1;
    for (@elements) {
        if ($_ != int $_ || $_ <= 0) {
            $check = 0;
            last;
        }
    }
    for (@cycles) {
        if ((scalar uniq @{$_}) != (scalar @{$_})) {
            $check = 0;
            last;
        }
    }
    if (!$check) {
        carp "Error in input representation. "
              ."The permutation will initialize to identity permutation "
              ."of $n elements.\n";
        $wrepr = [1..$n]; 
    }
    # end: checking
    if ($check) {
        if ((scalar uniq @elements) == (scalar @elements)) {
            $wrepr = _cycles_to_wrepr($n, [@cycles]);
        }
        else {
            # composition operation
            my @ws;
            @ws = map {_cycles_to_wrepr($n, [ $_ ] ) } @cycles;
            my @qp;
            my @p = $ws[-1]->@*;
            for my $j (2..scalar @cycles) {
                @qp = ();
                my @q = $ws[-$j]->@*;
                push @qp, $q[$p[$_-1]-1] for 1..$n;
                @p = @qp;
            }
            @qp = map { $qp[$_] == 0 ? $_+1 : $qp[$_] } (0..$n-1);
            $wrepr = [@qp];
        }
    }
    bless {
        _wrepr => $wrepr,
        _n => $n,
    }, $class;
}
 
sub _cycles_to_wrepr {
    my $n = $_[0];
    my @cycles = $_[1]->@*;
    my %hash;
    $hash{$_} = 0 for (1..$n);
    for my $c (@cycles) {
        if (scalar @{$c} > 1) {
            $hash{$c->[$_]} = $c->[$_+1] for (0..scalar @{$c} - 2);
            $hash{$c->[-1]} = $c->[0];
        }
        elsif (scalar @{$c} == 1) {
            $hash{$c->[0]} = $c->[0];
        }
    }
    return [ map {$hash{$_} == 0 ? $_ : $hash{$_}} (1..$n) ];
}
 
sub cycles_with_len {
    my ($class) = @_;
    my $n = $_[1];
    my @cycles = $_[2]->@*;
    my @elements;
    push @elements, @{$_} foreach @cycles;
    return (any {$n == $_} @elements) ? $_[0]->cycles([@cycles]) 
                                      : $_[0]->cycles([@cycles, [$n]]);
}
 
sub sprint_wrepr {
    return "\"" . (join ",", $_[0]->{_wrepr}->@*) . "\"";
}
 
sub sprint_tabular {
    my $n = $_[0]->{_n};
    my $digit_len = length $n;
    return 
          "|" . (join " ", map {sprintf("%*s", $digit_len, $_)} 1..$n )
        . "|" . "\n"
        ."|"
        . (join " ", map {sprintf("%*s", $digit_len, $_)} $_[0]->{_wrepr}->@* )
        . "|";
}
 
sub sprint_cycles {
    my @cycles = $_[0]->cyc->@*;
    @cycles = grep { scalar @{$_} > 1 } @cycles;
    return "()" if scalar @cycles == 0;
    my @p_cycles = map {"(".(join " ", @{$_}). ")"} @cycles;
    return join " ", @p_cycles;
}
 
sub sprint_cycles_full {
    my @cycles = $_[0]->cyc->@*;
    my @p_cycles = map {"(".(join " ", @{$_}). ")"} @cycles;
    return join " ", @p_cycles;
}

sub array {
    return $_[0]->{_wrepr}->@*;
}
 
sub swap {
    my $i = $_[1];
    my $j = $_[2];
    my $wrepr = $_[0]->{_wrepr};
    ($wrepr->[$i-1], $wrepr->[$j-1]) = ($wrepr->[$j-1], $wrepr->[$i-1]);
    $_[0]->{_wrepr} = $wrepr;
    return $_[0];
}
 
sub comp {
    my $n = $_[0]->{_n};
    my @p = $_[0]->{_wrepr}->@*;
    my @q = $_[1]->{_wrepr}->@*;
    return [] if scalar @q != $n;
    my @qp;
    push @qp, $q[$p[$_-1]-1] for 1..$n;
    $_[0]->{_wrepr} = [@qp];
    return $_[0];
}
 
sub inverse {
    my $n = $_[0]->{_n};
    my @cycles = $_[0]->cyc->@*;
    my @new_cycles;
    foreach (@cycles) {
        push @new_cycles, [reverse @{$_}];
    }
    $_[0]->{_wrepr} = _cycles_to_wrepr($n, [@new_cycles]);
    return $_[0];
}
 
sub nxt {
    my $n = $_[0]->{_n};
    my @w = $_[0]->{_wrepr}->@*;
    my @rw = reverse @w;
    my $ind = 1;
    while ($ind <= $#rw && $rw[$ind-1] < $rw[$ind]) {
        $ind++;
    }
    return [] if $ind == scalar @w;
    my @suffix = tail $ind, @w;
    my $i = 1;
    $i++ until $w[-$ind-1] < $suffix[-$i];
    ($w[-$ind-1], $suffix[-$i]) = ($suffix[-$i], $w[-$ind-1]);
    $_[0]->{_wrepr} = [ @w[0..$n-$ind-1], reverse @suffix ];
    return $_[0];
}
 
sub prev {
    my $n = $_[0]->{_n};
    my @w = $_[0]->{_wrepr}->@*;
    my @rw = reverse @w;
    my $ind = 1;
    while ($ind <= $#rw && $rw[$ind-1] > $rw[$ind]) {
        $ind++;
    }
    return [] if $ind == scalar @w;
    my @suffix = tail $ind, @w;
    my $i = 1;
    $i++ until $w[-$ind-1] > $suffix[-$i];
    ($w[-$ind-1], $suffix[-$i]) = ($suffix[-$i], $w[-$ind-1]);
    $_[0]->{_wrepr} = [ @w[0..$n-$ind-1], reverse @suffix ];
    return $_[0];
}
 
sub unrank {
    my ($class) = @_;
    my $n = $_[1];
    my @list = (1..$n);
    my $r = $_[2]-1;
    my $fact = _factorial($n-1);
    my @unused_list = sort {$a<=>$b} @list;
    my @p = ();
    for my $i (0..$n-1) {
        my $q = int $r / $fact;
        $r %= $fact;
        push @p, $unused_list[$q];
        splice @unused_list, $q, 1;
        $fact = int $fact / ($n-1-$i) if $i != $n-1;
    }
    my $wrepr = [@p];
    bless {
        _wrepr => $wrepr,
        _n => $n,
    }, $class;
}
 
# Fisher-Yates shuffle
sub random {
    my ($class) = @_;
    my $n = $_[1];
    my @ori = (1..$n);
    my @w;
    for (1..$n) {
        my $roll = int (rand() * scalar @ori);
        push @w, $ori[$roll];
        ($ori[$roll], $ori[-1]) = ($ori[-1], $ori[$roll]);
        pop @ori;
    }
    bless {
        _wrepr => [@w],
        _n => $n,
    }, $class;
}
 
sub cyc {
    my $w = $_[0]->{_wrepr};
    my $n = $_[0]->{_n};
    my %hash;
    $hash{$_} = $w->[$_-1] foreach 1..$n;
    my @cycles;
    while (scalar %hash != 0) {
        my $c1 = first {1} %hash;
        my @cycle;
        my $c = $c1;
        do {
            push @cycle, $c;
            my $pre_c = $c;
            $c = $hash{$c};
            delete $hash{$pre_c};
        } while ($c != $c1);
        push @cycles, [@cycle];
    }
    return [@cycles];
}
 
 
 
sub sigma {
    return $_[0]->{_wrepr}->[$_[1]-1];
}
 
sub rule {
    return $_[0]->{_wrepr};
}
 
sub elems {
    return $_[0]->{_n};
}
 
sub rank {
    my @list = $_[0]->{_wrepr}->@*;
    my $n = scalar @list;
    my $fact = _factorial($n-1);
    my $r = 1;
    my @unused_list = sort {$a<=>$b} @list;
    for my $i (0..$n-2) {
        my $q = first { $unused_list[$_] == $list[$i] } 0..$#unused_list;
        $r += $q*$fact;
        splice @unused_list, $q, 1;
        $fact = int $fact / ($n-$i-1);
    }
    return $r;
}
 
# rank() and unrank($n, $i) using
# O(n^2) solution, translation of Python code on
# https://tryalgo.org/en/permutations/2016/09/05/permutation-rank/

sub index {
    my $n = $_[0]->{_n};
    my @w = $_[0]->{_wrepr}->@*;
    my $ans = 0;
    for my $j (0..$n-2) {
        $ans += ($j+1) if $w[$j] > $w[$j+1];
    }
    return $ans;
}
 
sub order {
    my @cycles = $_[0]->cyc->@*;
    return _lcm(map {scalar @{$_}} @cycles);
}
 
sub is_even {
    my @cycles = $_[0]->cyc->@*;
    my $num_of_two_swaps = sum(map { scalar @{$_} - 1 } @cycles);
    return $num_of_two_swaps % 2 == 0 ? 1 : 0;
}
 
sub is_odd {
    return $_[0]->is_even ? 0 : 1;
}
 
sub sgn {
    return $_[0]->is_even ? 1 : -1;
}
 
sub inversion {
    my $n = $_[0]->{_n};
    my @w = $_[0]->{_wrepr}->@*;
    my @inv;
    for my $k (1..$n) {
        my $i = 0;
        my $j = 0;
        while ($w[$j] != $k) {
            $i++ if $w[$j] > $k;
            $j++;
        }
        push @inv, $i;
    }
    return [@inv];
}
 
sub matrix {
    my $mat;
    my $n = $_[0]->{_n};
    my @w = $_[0]->{_wrepr}->@*;
    for my $i (0..$n-1) {
        for my $j (0..$n-1) {
            $mat->[$i]->[$j] = 0;
        }
    }
    $mat->[$w[$_]-1]->[$_] = 1 for (0..$n-1);
    return $mat;
}
 
sub fixed_points {
    my @fp;
    for (1..$_[0]->{_n}) {
        push @fp, $_ if $_[0]->{_wrepr}->[$_-1] == $_;
    }
    return [@fp];
}

sub _reorder_odd_cycle {
    my @arr = @_;
    my @ans;
    my $m = $#arr / 2;
    for (0..$m-1) {
        push @ans, $arr[$_], $arr[$m+$_+1];
    }
    push @ans, $arr[$m];
    return @ans;
}

sub sqrt {
    my ($class) = @_;
    my @new_cycles;
    my @cycles = $_[0]->cyc->@*;
    my %odd_cycle;
    my %even_cycle;
    for my $i (0..$#cycles) {
        if (scalar $cycles[$i]->@* % 2 == 1) {
            $odd_cycle{$i} = 1;
        } else {
            $even_cycle{$i} = scalar $cycles[$i]->@*;
        }
    }
    if ((scalar (values %even_cycle) % 2) == 0) {
        my @epairs = pairs sort {$a<=>$b} values %even_cycle;
        for (@epairs) {
            if ($_->[0] != $_->[1]) {
                return undef;
            }
        }
        for my $i (keys %odd_cycle) {
            push @new_cycles, [_reorder_odd_cycle($cycles[$i]->@*)];
        }
        my @tol = keys %even_cycle;
        for my $i (@tol) {
            next if !defined($even_cycle{$i});
            my $j = first {$even_cycle{$_} == $even_cycle{$i} && $_ != $i} keys %even_cycle;
            delete $even_cycle{$j};
            push @new_cycles, [ mesh($cycles[$i], $cycles[$j]) ];
            delete $even_cycle{$i};
        }
    }
    else {
        return undef;
    }
    return Math::Permutation->cycles([@new_cycles]);
}

 
=head1 NAME
 
Math::Permutation - pure Perl implementation of functions related to the permutations 
 
=head1 VERSION
 
Version 0.0212
 
=cut
 
our $VERSION = '0.0212';

=head1 SYNOPSIS

    use Math::Permutation;

    my $foo = Math::Permutation->cycles([[1,2,6,7], [3,4,5]]);
    say $foo->sprint_wrepr;
    # "2,6,4,5,3,7,1"
    say join ",", $foo->array;
    # 2,6,4,5,3,7,1

    my $bar = Math::Permutation->unrank(5, 19);
    say $bar->sprint_cycles;
    # (2 5 4 3)
    # Note that there is no canonical cycle representation in this module,
    # so each time the output may be slightly different.

    my $goo = Math::Permutation->clone($foo);
    say $goo->sprint_cycles;
    # (1 2 6 7) (4 5 3)

    $foo->inverse;
    say $foo->sprint_cycles;
    # (4 3 5) (1 7 6 2)

    $foo->comp($goo);
    say $foo->sprint_cycles;
    # ()

    say $bar->rank; # 19
    $bar->prev;
    say $bar->rank; # 18
    say $goo->rank; # 1264
    $goo->nxt;
    say $goo->rank; # 1265

    say $goo->is_even; # 0
    say $goo->sgn;     # -1

    use Data::Dump qw/dump/;
    say $bar->sprint_wrepr;
    dump $bar->matrix;

    # "1,4,5,3,2"
    # [
    #   [1, 0, 0, 0, 0],
    #   [0, 0, 0, 0, 1],
    #   [0, 0, 0, 1, 0],
    #   [0, 1, 0, 0, 0],
    #   [0, 0, 1, 0, 0],
    # ]

        
        

=head1 METHODS

=head2 INITALIZE/GENERATE NEW PERMUTATION

=over 4

=item $p->init($n)

Initialize $p with the identity permutation of $n elements.

=item $p->wrepr([$a, $b, $c, ..., $m])

Initialize $p with word representation of a permutation, a.k.a. one-line form.

=item $p->tabular([$a, $b, ... , $m], [$pa, $pb, $pc, ..., $pm])

Initialize $p with the rules of a permutation, with input of permutation on the first list,
the output of permutation. If the first list is [1..$n], it is often called two-line form,
and the second list would be the word representation.

=item $p->cycles([[$a, $b, $c], [$d, $e], [$f, $g]])

=item $p->cycles_with_len($n, [[$a, $b, $c], [$d, $e], [$f, $g]])

Initialize $p by the cycle notation. If the length is not specific, the length would be the largest element in the cycles.

=item $p->unrank($n, $i)

Initialize $p referring to the lexicological rank of all $n-permutations. $i must be between 1 and $n!.

Note: The current version is not optimal. It is using an O(n^2) implementation, instead of the best O(n log n) implementation.

=item $p->random($n)

Initialize $p by a randomly selected $n-permutation.

=back

=head2 DISPLAY THE PERMUTATION

=over 4

=item $p->array()

Return an array showing the permutation.

=item $p->sprint_wrepr()

Return a string displaying the word representation of $p.

=item $p->sprint_tabular()

Return a two-line string displaying the tabular form of $p.

=item $p->sprint_cycles()

Return a string with cycles of $p. One-cycles are omitted.

=item $p->sprint_cycles_full()

Return a string with cycles of $p. One-cycles are included.

=back

=head2 CHECK EQUIVALENCE BETWEEN PERMUTATIONS

=over 4

=item $p->eqv($q)

Check if the permutation $q is equivalent to $p. Return 1 if yes, 0 otherwise.

=back

=head2 CLONE THE PERMUTATION

=over 4

=item $p->clone($q)

Clone the permutation $q into $p.

=back

=head2 MODIFY THE PERMUTATION

=over 4

=item $p->swap($i, $j)

Swap the values of $i-th position and $j-th position.

=item $p->comp($q)

Composition of $p and $q, sometimes called multiplication of the permutations. 
The resultant is $q $p (first do $p, then do $q).

$p and $q must be permutations of same number of elements.

=item $p->inverse()

Inverse of $p.

=item $p->nxt()

The next permutation under the lexicological order of all $n-permutations.

Caveat: may return [].

=item $p->prev()

The previous permutation under the lexicological order of all $n-permutations.

Caveat: may return [].

=back

=head2 PRORERTIES OF THE CURRENT PERMUTATION

=over 4

=item $p->sigma($i)

Return what $i is mapped to under $p.

=item $p->rule()

Return the word representation of $p as a list.

=item $p->cyc()

Return the cycle representation of $p as a list of list(s).

=item $p->elems()

Return the length of $p.

=item $p->rank()

Return the lexicological rank of $p. See $p->unrank($n, $i).

Note: The current version is not optimal. It is using an O(n^2) implementation, instead of the best O(n log n) implementation.

=item $p->index()

Return the permutation index of $p.

=item $p->order()

Return the order of $p, i.e. how many times the permutation acts on itself
and return the identity permutation.

=item $p->is_even()

Return whether $p is an even permutation. Return 1 or 0.

=item $p->is_odd()

Return whether $p is an odd permutation. Return 1 or 0.

=item $p->sgn()

Return the signature of $p. Return +1 if $p is even, -1 if $p is odd.

Another view is the determinant of the permutation matrix of $p.

=item $p->inversion()

Return the inversion sequence of $p as a list.

=item $p->matrix()

Return the permutation matrix of $p.

=item $p->fixed_points()

Return the list of fixed points of $p.

=item $p->sqrt()

Caveat: may return undef.

=back

=head1 METHODS TO BE INPLEMENTED

=over 4

=item longest_increasing()

=item longest_decreasing()

=item coxeter_decomposition()

=item comp( more than one permutations )

=item reverse()

ref: Chapter 1, Patterns in Permutations and Words

=item complement()  

ref: Chapter 1, Patterns in Permutations and Words

=item is_irreducible()

ref: Chapter 1, Patterns in Permutations and Words

=item num_of_occurrences_of_pattern()

ref: Chapter 1, Patterns in Permutations and Words

=item contains_pattern()

ref: Chapter 1, Patterns in Permutations and Words

=item avoids_pattern()

ref: Chapter 1, Patterns in Permutations and Words

including barred patterns

ref: Section 1.2, Patterns in Permutations and Words

Example: [ -3, -1, 5, -2, 4 ]

=back

=head1 AUTHOR

Cheok-Yin Fung, C<< <fungcheokyin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/E7-87-83/Math-Permutation/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Permutation


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Permutation>

=item * Search CPAN

L<https://metacpan.org/release/Math-Permutation>

=back


=head1 REFERENCES

The module has gained ideas from various sources:

Opensource resources:

=over 4

=item * L<Julia Package Permutations.jl|https://github.com/scheinerman/Permutations.jl/blob/master/docs/src/index.md>

=item * L<CPAN Module Math::GSL::Permutation|https://metacpan.org/pod/Math::GSL::Permutation>

=item * L<Combinatorics features of Maxima|https://maxima.sourceforge.io/docs/manual/maxima_singlepage.html#combinatorics_002dpkg>

=back

General resources:

=over 4

=item * L<Wolfram Alpha|https://www.wolframalpha.com/>

=item * I<Algebra>, Michael Artin

=item * I<Patterns in Permutations and Words>, Sergey Kitaev

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022-2025 by Cheok-Yin Fung.

This is free software, licensed under:

  MIT License

=cut

1; # End of Math::Permutation
