
use Test::More qw( no_plan ); # tests => 118;
use Graphics::ColorUtils qw( :gradients );

my %grads = available_gradients();
is( scalar keys %grads, 4, "Available gradients" );
foreach ( values %grads ) { is( $_, 240, "Colors per gradient" ); }

ok( exists $grads{ 'heat' }, "Heat gradient found" );
ok( !exists $grads{ 'foobar' }, "Foobar grad not found" );

# ---

my $grad = gradient( 'heat' );
ok( defined $grad, "Heat gradient assigned" );

my $i = 0;
foreach( @$grad ) {
  is( scalar @{ $_ }, 3, "Heat element is triple" );

  ok( 0 <= $_->[0] && $_->[0] < 256, "Heat - Red legal value" );
  ok( 0 <= $_->[1] && $_->[1] < 256, "Heat - Green legal value" );
  ok( 0 <= $_->[2] && $_->[2] < 256, "Heat - Blue legal value" );

  if( $i++ > 10 ) { last; }
}

ok( !defined gradient( 'foobar' ), "Foobar gradient not defined" );

# ---

for( my $x=0; $x<1; $x+=0.1 ) {
  like( grad2rgb( 'heat', $x ), qr/#[0-9a-fA-F]{6}/, "Heat is hex-string" );

  my ( $r, $g, $b ) = grad2rgb( 'heat', $x );
  ok( 0 <= $r && $r < 256, "Heat element - Red legal value" );
  ok( 0 <= $g && $g < 256, "Heat element - Green legal value" );
  ok( 0 <= $b && $b < 256, "Heat element - Blue legal value" );
}

ok( !defined grad2rgb( 'heat', -0.1 ), "Heat element : -.1 not found" );
ok(  defined grad2rgb( 'heat',  0.0 ), "Heat element : 0.0 found" );
ok( !defined grad2rgb( 'heat',  1.0 ), "Heat element : 1.0 not found" );
ok( !defined grad2rgb( 'heat',  1.1 ), "Heat element : 1.1 not found" );

ok( !defined grad2rgb( 'foobar', 0.5 ), "Foobar element not found" );

# ---

my @foo = ( [ 0, 0, 0 ], [ 16, 32, 64 ], [ 255, 255, 255 ] );
my $old = register_gradient( 'foo', \@foo );
ok( !defined $old, "Registered new gradient name" );
ok( defined gradient( 'foo' ), "New gradient name found" );
is( grad2rgb( 'foo', 0 ), '#000000', "First new element found" );
is( grad2rgb( 'foo', 0.99 ), '#ffffff', "Last new element found" );

push @foo, [ 8, 8, 8 ];
my $renew = register_gradient( 'foo', \@foo );
ok( defined $renew, "Renewed gradient - old value found" );
is( scalar @$renew, 4, "Modified gradient is reference to old one" );
is( grad2rgb( 'foo', 0.99 ), '#080808', "New last element correct" );

my @bar = ( [0,0,0],[3,3,3],[1,2.3],[10,0,20],[1,1,1] );
$renew = register_gradient( 'foo', \@bar );
ok( defined $renew, "Renewed gradient - old value found" );
is( scalar @$renew, 4, "Modified gradient unrelated to old gradient" );
$grad = gradient( 'foo' );
is( scalar @$grad, 5, "New gradient correct element count" );
is( grad2rgb( 'foo', 0.99 ), '#010101', "New-new last element correct" );
ok( 1, "All done" );

# --- blank comment



