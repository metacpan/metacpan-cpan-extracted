# $Id: 01-word-puzzle.t,v 1.3 2006/01/30 20:04:15 adler Exp $

use Test;
BEGIN { plan tests => 1 };

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

# This is not necessary, but the solution is slower for this problem
$p->solve_order( [
    "housecolour", "nationality", "beverage", "smokebrand", "pet", ] );

$p->verify_proc( \&my_verify );


my $soln= $p->solve();
my $who = $p->get("nationality", "pet" => "fish", $soln);

ok ($who, "German" );

sub check {
    my $var = shift;
    return 1 if ( not defined $var ) or $var;
    return 0;
}
 
sub my_verify
{
    my $c=      shift();

#   1. The Brit lives in a red house. 
  { my $p = $c->housecolour(nationality => "Brit");
    return 0 if $p && $p ne "red"; }
#   return 0 unless check( $c->housecolour(nationality => "Brit") eq "red" );
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
