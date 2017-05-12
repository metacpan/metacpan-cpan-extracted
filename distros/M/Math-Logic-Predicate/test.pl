#!/usr/bin/perl

use Test::Simple tests => 11;

use Math::Logic::Predicate;

my $db = new Math::Logic::Predicate;

ok(defined $db,     'new');
ok($db->isa('Math::Logic::Predicate'));

# Add some predicates to the database
$db->add(<<EOA);
    human(lister).
    human(kochanski).
    plays(lister, guitar).
    smart(holly).
    smart(rimmer).
    name(lister, 'Dave Lister').
    name(kochanski, 'Kristine Kochanski').
    name(rimmer, 'Arnold Rimmer').
EOA

my $query = $db->parse( 'human(lister)?' );
ok($query, 'parse');
$iter = $db->match($query, $iter);
ok($iter,  'simple');
$iter = $db->match($query, $iter);
ok(!$iter, 'unique');

$db->retract( 'plays(lister, guitar).' );
$query = $db->parse( 'plays(lister, guitar)?' );
$iter = $db->match($query, $iter);
ok(!$iter, 'retract');

$db->retract( 'smart(_).' );
$query = $db->parse( 'smart(holly)?' );
$iter = $db->match($query, $iter);
ok(!$iter, 'retract pattern');

$query = $db->parse( 'name(lister, X)?' );
$iter = $db->match($query, $iter);
ok($db->get($iter, 'X') eq 'Dave Lister', 'binding');
$iter = $db->match($query, $iter);
ok(!$iter, 'binding unique');

$db->add( 'human_name(H, N) := human(H) & name(H, N).' );
$iter = $db->match( 'human_name(Z, "Dave Lister")? ' );
ok($db->get($iter, 'Z') eq 'lister', 'rule');

$db->add( 'whole(X) := {
               if (defined $X) {
                   $track ? $X =~ /^[1-9]\d*$/ : undef
               }
               else {
                   $X = ++$local->{num}
               }
           }.');
undef $iter;
my @a;
$query = $db->parse( 'whole(X)?' );
$iter = $db->match($query, $iter);
push @a, $db->get($iter, 'X');
$iter = $db->match($query, $iter);
push @a, $db->get($iter, 'X');
ok($a[0] == 1 && $a[1] == 2, 'embed');

