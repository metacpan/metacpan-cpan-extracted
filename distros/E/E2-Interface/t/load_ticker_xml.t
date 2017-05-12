use Test::Simple tests => 75;
use E2::Ticker;

my $t = new E2::Ticker;

open( F, "<t/new_writeups.xml" )
	or die "Unable to open file: $!";

my $s = "";
foreach( <F> ) { $s .= $_ }	# slurp
close F;
$t->use_string( $s );

ok( my @n = $t->new_writeups );
ok( $n[0]->{title} eq "idea1 (idea)" );
ok( $n[0]->{id} == 11111 );
ok( $n[0]->{type} eq "idea" );
ok( $n[0]->{author} eq "user" );
ok( $n[0]->{author_id} == 22222 );
ok( $n[0]->{parent} eq "idea1" );
ok( $n[0]->{parent_id} == 33333 );

ok( $n[1]->{title} eq "thing1 (thing)" );
ok( $n[1]->{id} == 44444 );
ok( $n[1]->{type} eq "thing" );
ok( $n[1]->{author} eq "user2" );
ok( $n[1]->{author_id} == 55555 );
ok( $n[1]->{parent} eq "thing1" );
ok( $n[1]->{parent_id} == 66666 );

open( F, "<t/other_users.xml" )
	or die "Unable to open file: $!";

$s = "";
foreach( <F> ) { $s .= $_ } # slurp
close F;
$t->use_string( $s );

ok( my @u = $t->other_users );
ok( $u[0]->{name} eq "Gritchka" );
ok( $u[0]->{id} == 898906 );
ok( $u[0]->{god} );
ok( ! $u[0]->{editor} );
ok( ! $u[0]->{edev} );
ok( $u[0]->{xp} == 36251 );

ok( $u[1]->{name} eq "Professor Pi" );
ok( $u[1]->{id} == 768243 );
ok( ! $u[1]->{god} );
ok( $u[1]->{editor} );
ok( $u[1]->{edev} );
ok( $u[1]->{xp} == 23896 );

ok( $u[2]->{name} eq "xunker" );
ok( $u[2]->{id} == 7515 );
ok( ! $u[2]->{god} );
ok( ! $u[2]->{editor} );
ok( $u[2]->{edev} );
ok( $u[2]->{xp} == 8136 );
ok( $u[2]->{room} eq "Noders Nursery" );
ok( $u[2]->{room_id} == 553146 );

open( F, "<t/cool_nodes.xml" )
	or die "Unable to open file: $!";

$s = "";
foreach( <F> ) { $s .= $_ }	# slurp
close F;
$t->use_string( $s );

ok( my @c = $t->cool_nodes );
ok( $c[0]->{title} eq 'Lupe Velez (person)' );
ok( $c[0]->{id} == 1355024 );
ok( $c[0]->{author} eq 'vixen' );
ok( $c[0]->{author_id} == 1177778 );
ok( $c[0]->{cooledby} eq 'Gritchka' );
ok( $c[0]->{cooledby_id} == 898906 );

ok( $c[1]->{title} eq 'Lupe Velez (person)' );
ok( $c[1]->{id} == 1355024 );
ok( $c[1]->{author} eq 'vixen' );
ok( $c[1]->{author_id} == 1177778 );
ok( $c[1]->{cooledby} eq 'Lord Brawl' );
ok( $c[1]->{cooledby_id} == 8933 );

open( F, "<t/editor_cools.xml" )
	or die "Unable to open file: $!";

$s = "";
foreach( <F> ) { $s .= $_ }	# slurp
close F;
$t->use_string( $s );

ok( my @e = $t->editor_cools );
ok( $e[0]->{title} eq 'I am three, she said' );
ok( $e[0]->{id} == 1028921 );
ok( $e[0]->{editor} eq 'fuzzy and blue' );
ok( $e[0]->{editor_id} == 949709 );

ok( $e[1]->{title} eq 'How to cook rice' );
ok( $e[1]->{id} == 576555 );
ok( $e[1]->{editor} eq 'WonkoDSane' );
ok( $e[1]->{editor_id} == 780564 );

open( F, "<t/random_nodes.xml" )
	or die "Unable to open file: $!";
	
$s = "";
foreach( <F> ) { $s .= $_ }	# slurp
close F;
$t->use_string( $s );

ok( my @r = $t->random_nodes );
ok( $r[0]->{title} eq 'Oulu' );
ok( $r[0]->{id} == 408940 );
ok( $r[1]->{title} eq 'Doughfaceism' );
ok( $r[1]->{id} == 226765 );
ok( $t->random_nodes_wit eq 'Just another sprinking of indeterminacy' );

open( F, "<t/time_since.xml" )
	or die "Unable to open file: $!";

$s = "";
foreach( <F> ) { $s .= $_ }	# slurp
close F;
$t->use_string( $s );

ok( my @i = $t->time_since );
ok( $i[0]->{name} eq 'JayBonci' );
ok( $i[0]->{id} == 459692 );
ok( $i[0]->{time} eq '2002-10-17 12:20:07' );

ok( $i[1]->{name} eq 'TheBooBooKitty' );
ok( $i[1]->{id} == 1019201 );
ok( $i[1]->{time} eq '2002-10-17 12:55:36' );

ok( $i[2]->{name} eq 'nate' );
ok( $i[2]->{id} == 220 );
ok( $i[2]->{time} eq '2002-10-16 22:01:33' );

ok( $t->time_since_now eq '2002-10-18 12:59:42' );
