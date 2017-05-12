package Games::LogicPuzzle;
# Perl module to help solve some logic riddles
# (C) 2004 Andy Adler
# $Id: LogicPuzzle.pm,v 1.6 2006/01/30 20:47:09 adler Exp $

use strict;
use warnings;
use Carp;

our $VERSION= 0.20;

sub new {
    my $class = shift;
    my %args = @_;
    my $self = {
                 type => 'SimplePuzzle',
                 sameok => 0,
                 verbose => 0,
                 all_solutions => 0,
                 initialized => 0,
               };
    bless $self, $class;
    for ( keys %args ) {
        $self->ProcessArg( $_, $args{$_} );
    }
    return $self;
}

# the "Computer Science" solution is to do recursion,
# but that involves so many method calls, it's sick.
# Instead, we autogenerate code to iterate though 
#  problem space
sub make_solve_code {
    my $self= shift();
    my $code= "";

    # autogenerate subroutines from properties
    # such that smoke(beverage=>'beer') = get('smoke',beverage=>'beer')
    my %proplist= ( %{$self->{properties}},
                    %{$self->{assignlist}} );
    for my $poss (keys %proplist) {
       $code.= qq(
           sub $poss { return \$_[0]->get('$poss',\$_[1],\$_[2]) };
           );
    }
 
    my @thing     = @{$self->{things}};
    my @solve_order;
    if ( $self->{solve_order} ) {
        @solve_order = @{$self->{solve_order}};
    } else {
        @solve_order = keys %{$self->{properties}};
    }

    # setup code, disable warnings for verify
    $code.= q(
    my @thing     = @{$self->{things}};
    my %possesion = %{$self->{properties}};
    local $^W;
    LOOP:);

    # loop through all the possibilities
    #    thus we loop through each property of each thing
    #       ie $thing[ num_things ]->{ property_list }
    #    unless that $thing already has a property
    my $brace_count = 0;
    for my $p ( @solve_order ) {
        for my $t ( 0 .. $#thing ) {
            if( not defined $self->{things}->[ $t ] ->{ $p } ){
               $code .= sprintf q(
    for (@{$possesion{ "%s" }}) {
        local $thing[ %d ]->{"%s"} = $_;
        next unless $self->verify(); ),
               $p , $t, $p, $t, $p;

               $brace_count++;
            }
        }
    }
    
    # now we have a solution, return it if required;
    $code.= q(
    push @solutions, clone( \@thing );
    last LOOP unless $self->{all_solutions};);

    # add all the close braces for the code
    $code.= " }" x $brace_count;

    return $code;
}

sub solve {
    my $self = shift;
    $self->initialize() unless $self->{initialized};
    my $code = $self->make_solve_code();

    my @solutions;
    eval $code; croak $@ if $@;

    return undef unless @solutions;
    return $solutions[0] unless $self->{all_solutions};
    return \@solutions;
}

sub verify {
    my $self= shift;
    if (! $self->{sameok}) {
        return 0 unless $self->verify_not_same();
    }
    my $verify_proc= $self->{verify_proc};
    return 0 unless $verify_proc->( $self, $self->{things} );

    return 1;
}

# check that no two things have same members
sub verify_not_same {
    my $self= shift;
    my @things= @{$self->{things}};
    my @posses= keys %{$self->{properties}};
    for my $cat (@posses) {
        my %verif;
        for my $thing (@things) {
            my $thing_cat = $thing->{$cat};
            next unless $thing_cat;
            return 0 if $verif{$thing_cat};
            $verif{$thing_cat}=1;
        }
    }
    return 1;
}


sub initialize {
    my $self = shift;
    my @things= ();
    my @posses= keys %{$self->{properties}};
    my @assign= keys %{$self->{assignlist}};
    for my $n (1 .. $self->{num_things}) {
        my %thing;
        for (@posses) {
            $thing{$_}= undef 
        }
        for (@assign) {
            $thing{$_}= $self->{assignlist}->{$_}->[$n-1]; 
        }
        push @things, \%thing;
    }
    $self->{things} = \@things;
    $self->{initialized}= 1;
}

# get all things (pers) who have $cat eq $val
sub getpers {
    my ($things, $cat, $val) = @_;

    return undef unless defined $val;
    my @getpers= grep { $_->{$cat} and 
                        $_->{$cat} eq $val } @$things;

    return @getpers;
}

# get the $want possession of the thing who's $cat is $val
sub get {
    my ($self, $want, $cat, $val, $soln) = @_;

    my $things= $self->{things};
       $things= $soln if $soln;
    my @getpers= getpers($things, $cat, $val );

    return undef unless @getpers;
    my @getwant= map {$_->{$want}} @getpers;
    return $getwant[0];
}


my %cmds = (
    num_things => \&num_things,
    properties => \&properties,
    sameok => \&sameok,
    verify_proc => \&verify_proc,
);

sub ProcessArg {
    my $self = shift;
    my ($cmd, $detail) = @_;
    if ($cmds{$cmd}) {
        $cmds{$cmd}->($self, $detail );
    } else {
        die "Can't $cmd $detail";
    }
}

sub num_things {
    my $self = shift;
    $self->{num_things}= shift();
}

# properties are properties to be distributed to things
sub properties {
    my $self = shift;
    $self->{properties}= shift();
}

# assign are properties that are preassigned to things
sub assign {
    my $self = shift;
    $self->{assignlist}= shift();
}

sub sameok {
    my $self = shift;
    $self->{sameok}= shift();
}

sub verify_proc {
    my $self = shift;
    $self->{verify_proc}= shift();
}

# cheap clone routine
sub clone {
    my @data= @{shift()};
    my @copy;
    for (@data) {
        my %data= ( %{$_} );
        push @copy, \%data;
    }
    return \@copy;
}

sub solve_order {
    my $self = shift;
    $self->{solve_order}= shift();
}

1;

__END__
=head1 NAME

LogicPuzzle - Perl extension for helping to solve brain teaser puzzles

=head1 SYNOPSIS

    use Games::LogicPuzzle;
    my $p= new Games::LogicPuzzle (
        num_things => 5
    );
    $p->assign( { ... } );
    $p->properties( { ... } );
    $p->verify_proc( \&my_verify );

    $solution = $p->solve();

=head1 DESCRIPTION

Games::LogicPuzzle may help you solve brain teaser puzzles where
there are lots of solution possibilities. You setup a
local subroutine which rejects wrong solutions, give
the module the working parameters, and it will do the
rest.

=head1 EXAMPLES

I initially used this to help me solve the famous problem
attributed to Einstein. Details and a manual solution can
be found here:

http://mathforum.org/library/drmath/view/60971.html

=head2 SAMPLE PUZZLE

    There are 5 houses sitting next to each other, each with a different 
    color, occupied by 5 guys, each from a different country, 
    and with a favorite drink, cigarette, and pet.  Here are the facts:

    The British occupies the red house.
    The Swedish owns a dog.
    The Danish drinks tea.
    The green house is on the left of the white house.
    The person who smokes "Pall Mall" owns a bird.
    The owner of the yellow house smokes "Dunhill".
    The owner of the middle house drinks milk.
    The Norwegian occupies the 1st house.
    The person who smokes "Blend" lives next door
        to the person who owns a cat.
    The person who owns a horse live next door to
        the person who smokes "Dunhill".
    The person who smokes "Blue Master" drinks beer.
    The German smokes "Prince".
    The Norwegian lives next door to the blue house.
    The person who smokes "Blend" lives next door to
        the person who drinks water.

    The question is: Who owns the fish?

=head2 SOLUTION CODE

This module solves this puzzle as follows:

    use Games::LogicPuzzle;
    my $p= new Games::LogicPuzzle (
        num_things => 5
    );

    $p->assign( {
        houseposition=> [ 1 .. 5 ],
    } );

    $p->properties( {
        housecolour => [qw(blue green red white yellow)],
        nationality => [qw(Brit Dane German Norwegian Swede)],
        beverage    => [qw(beer coffee milk tea water)],
        smokebrand  => [qw(BlueMaster Dunhill PaulMaul Prince Blend)],
        pet         => [qw(cat bird fish horse dog)],
    } );

    # some solve orders are _really_ slow
    $p->solve_order( [
      "housecolour", "nationality", "beverage", "smokebrand", "pet" ]);

    $p->verify_proc( \&my_verify );

    my $soln= $p->solve();

    my $who = $p->get("nationality", "pet" => "fish", $soln);
    print "$who keeps fish";

    sub my_verify
    {
        my $c=      shift();
 
    #   1. The Brit lives in a red house. 
      { my $p = $c->housecolour(nationality => "Brit");
        return 0 if $p && $p ne "red"; }
    #   2. The Swede keeps dogs as pets. 
      { my $p = $c->pet(nationality => "Swede");
        return 0 if $p && $p ne "dog"; }
    #   3. The Dane drinks tea. 
      { my $p = $c->beverage(nationality => "Dane");
        return 0 if $p && $p ne "tea"; }
    #   4. The green house is on the left of the white house (next to it). 
      { my $p1 = $c->houseposition(housecolour => "green");
        my $p2 = $c->houseposition(housecolour => "white");
        return 0 if $p1 && $p2 && ( $p1 - $p2 != 1); #arbirary choice of left
     }
    #   5. The green house owner drinks coffee. 
      { my $p = $c->beverage(housecolour => "green");
        return 0 if $p && $p ne "coffee"; }
    #   6. The person who smokes Pall Mall rears birds. 
      { my $p = $c->pet(smokebrand => "PaulMaul");
        return 0 if $p && $p ne "bird"; }
    #   7. The owner of the yellow house smokes Dunhill. 
      { my $p = $c->smokebrand(housecolour => "yellow");
        return 0 if $p && $p ne "Dunhill"; }
    #   8. The man living in the house right in the center drinks milk. 
      { my $p = $c->beverage(houseposition => "3");
        return 0 if $p && $p ne "milk"; }
    #   9. The Norwegian lives in the first house. 
      { my $p = $c->houseposition(nationality => "Norwegian");
        return 0 if $p && $p ne "1"; }
    #  10. The man who smokes blend lives next to the one who keeps cats. 
      { my $p1 = $c->houseposition(smokebrand => "Blend");
        my $p2 = $c->houseposition(pet =>  "cats");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  11. The man who keeps horses lives next to the man who smokes Dunhill. 
      { my $p1 = $c->houseposition(pet => "horse");
        my $p2 = $c->houseposition(smokebrand => "Dunhill");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  12. The owner who smokes Blue Master drinks beer. 
      { my $p = $c->beverage(smokebrand => "BlueMaster");
        return 0 if $p && $p ne "beer"; }
    #  13. The German smokes Prince. 
      { my $p = $c->smokebrand(nationality => "German");
        return 0 if $p && $p ne "Prince"; }
    #  14. The Norwegian lives next to the blue house. 
      { my $p1 = $c->houseposition(nationality => "Norwegian");
        my $p2 = $c->houseposition(housecolour => "blue");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
    #  15. The man who smokes blend has a neighbor who drinks water. 
      { my $p1 = $c->houseposition(smokebrand => "Blend");
        my $p2 = $c->houseposition(beverage => "water");
        return 0 if $p1 && $p2 && (abs($p2 - $p1) != 1); }
 
        return 1;
    }

The heart of the solution is the &verify subroutine. Here
is where the puzzle details are translated into a definition
of a valid solution.

Within the verify subroutine, we call 'get' with various
parameters to extract the current solution scenario. This
is then tested to see if it is correct. If the current
scenario is 'undef' then that should be verified as 'ok'

A number of 'convenience' subroutines are autodefined, so
that you can do 1) instead of 2).

   1)  my $p = $c->housecolour(nationality => "Brit");

   2)  my $p = $c->get("housecolour", 
                      "nationality" => "Brit");

When $p->solve() is called, Games::LogicPuzzle will
(somewhat intelligently) iterate through the solution space
to find a solution that satisfies &verify.

There are additional methods to get all valid solutions, and
set a variety of other parameters.

=head2 SAMPLE PUZZLE: SUDOKU

This module can also be used to solve Sudoku puzzles. The
following solution code will work for a smaller, 4x4 
Sudoku puzzle.

=head2 SOLUTION CODE

   use Games::LogicPuzzle;
   my $p= new Games::LogicPuzzle (
       num_things => 16,
       sameok     => 1,
   );

   $p->properties( {
       VAL => [1 .. 4],
   } );

   $p->assign( {
       POS=> [ 11,    12,    13,    14,
               21,    22,    23,    24,
               31,    32,    33,    34,
               41,    42,    43,    44, ],
       VAL=>[  1,     2, undef, undef,
               3,     4,     1,     2,
               4,     3,     2, undef,
               2,     1,     4,     3, ],
   } );

This sets up the problem. There are
num_things = 16 grids on the board, of which
$p->properties says each can have 1 .. 4 as values.
The code in $p->assign will set the initial values

   $p->verify_proc( \&my_verify );

   my $soln= $p->solve();

   # print soln
   for my $y ( 1 .. 4 ) {
      for my $x ( 1 .. 4 ) {
         my $v = $p->get("VAL", "POS" => "$x$y", $soln);
         print " $v ";
         print "|" if $x % 2 ==0;
      }
         print "\n";
         print "-----------------------\n" if $y % 2 ==0;
   }

   print $who;

   # test whether all the elements in a group are unique
   # call as sudoku_test ($c,11,12,21,22)
   sub sudoku_test {
      my $c= shift();
      my %vals;

      for (@_) {
        my $val= $c->VAL(POS=>$_);
        next unless $val;
        return 0 if ++$vals{$val} > 1;
      }

      return 1;
   }

   sub my_verify
   {
       my $c=      shift();

       return 0 unless sudoku_test($c, 11, 12, 21, 22);
       return 0 unless sudoku_test($c, 31, 32, 41, 42);
       return 0 unless sudoku_test($c, 13, 14, 23, 24);
       return 0 unless sudoku_test($c, 33, 34, 43, 44);
       return 0 unless sudoku_test($c, 11, 12, 13, 14);
       return 0 unless sudoku_test($c, 21, 22, 23, 24);
       return 0 unless sudoku_test($c, 31, 32, 33, 34);
       return 0 unless sudoku_test($c, 41, 42, 43, 44);
       return 0 unless sudoku_test($c, 11, 21, 31, 41);
       return 0 unless sudoku_test($c, 12, 22, 32, 42);
       return 0 unless sudoku_test($c, 13, 23, 33, 43);
       return 0 unless sudoku_test($c, 14, 24, 34, 44);
       return 1;
   }

=head2 SOLUTION CODE for full size Sudoku

For the full 9x9 Sudoku, the test matrix needs to be 
expanded, and we see a solution slowing - down to about
5.5 minutes on my Old P3 Laptop.

Here is the test matrix, other changes are num_things= 81,
and $p->properties has VAL= 1..9 

   # test rows
       return 0 unless sudoku_test($c, 11, 12, 13, 14, 15, 16, 17, 18, 19);
       return 0 unless sudoku_test($c, 21, 22, 23, 24, 25, 26, 27, 28, 29);
       return 0 unless sudoku_test($c, 31, 32, 33, 34, 35, 36, 37, 38, 39);
       return 0 unless sudoku_test($c, 41, 42, 43, 44, 45, 46, 47, 48, 49);
       return 0 unless sudoku_test($c, 51, 52, 53, 54, 55, 56, 57, 58, 59);
       return 0 unless sudoku_test($c, 61, 62, 63, 64, 65, 66, 67, 68, 69);
       return 0 unless sudoku_test($c, 71, 72, 73, 74, 75, 76, 77, 78, 79);
       return 0 unless sudoku_test($c, 81, 82, 83, 84, 85, 86, 87, 88, 89);
       return 0 unless sudoku_test($c, 91, 92, 93, 94, 95, 96, 97, 98, 99);
   # test cols
       return 0 unless sudoku_test($c, 11, 21, 31, 41, 51, 61, 71, 81, 91);
       return 0 unless sudoku_test($c, 12, 22, 32, 42, 52, 62, 72, 82, 92);
       return 0 unless sudoku_test($c, 13, 23, 33, 43, 53, 63, 73, 83, 93);
       return 0 unless sudoku_test($c, 14, 24, 34, 44, 54, 64, 74, 84, 94);
       return 0 unless sudoku_test($c, 15, 25, 35, 45, 55, 65, 75, 85, 95);
       return 0 unless sudoku_test($c, 16, 26, 36, 46, 56, 66, 76, 86, 96);
       return 0 unless sudoku_test($c, 17, 27, 37, 47, 57, 67, 77, 87, 97);
       return 0 unless sudoku_test($c, 18, 28, 38, 48, 58, 68, 78, 88, 98);
       return 0 unless sudoku_test($c, 19, 29, 39, 49, 59, 69, 79, 89, 99);
   # test blocks
       return 0 unless sudoku_test($c, 11, 12, 13, 21, 22, 23, 31, 32, 33);
       return 0 unless sudoku_test($c, 41, 42, 43, 51, 52, 53, 61, 62, 63);
       return 0 unless sudoku_test($c, 71, 72, 73, 81, 82, 83, 91, 92, 93);
       return 0 unless sudoku_test($c, 14, 15, 16, 24, 25, 26, 34, 35, 36);
       return 0 unless sudoku_test($c, 44, 45, 46, 54, 55, 56, 64, 65, 66);
       return 0 unless sudoku_test($c, 74, 75, 76, 84, 85, 86, 94, 95, 96);
       return 0 unless sudoku_test($c, 17, 18, 19, 27, 28, 29, 37, 38, 39);
       return 0 unless sudoku_test($c, 47, 48, 49, 57, 58, 59, 67, 68, 69);
       return 0 unless sudoku_test($c, 77, 78, 79, 87, 88, 89, 97, 98, 99);


=head1 AUTHOR

Andy Adler < andy at analyti dot ca >

All Rights Reserved. This module is free software. It may be used,
redistributed and/or modified under the same terms as Perl itself.

=cut

