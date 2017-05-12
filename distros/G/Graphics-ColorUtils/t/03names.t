
use Test::More tests => 103;
use Graphics::ColorUtils qw( :names );

my $names = available_names();
ok( scalar keys %$names, "Names found" );

my $j = 0;
foreach( values %$names ) {
  my ( $r, $g, $b ) = @$_;
  ok( 0 <= $r && $r < 256, "ForName element - Red legal value" );
  ok( 0 <= $g && $g < 256, "ForName element - Green legal value" );
  ok( 0 <= $b && $b < 256, "ForName element - Blue legal value" );

  if( $j++ > 10 ) { last; }
}

# ---

is( get_default_namespace(), 'x11', "Default namespace" );

# Basic lookup
is( name2rgb( 'red' ), '#ff0000', "Default red" );
is( name2rgb( 'x11:red' ), '#ff0000', "X11 red" );
is( name2rgb( 'svg:red' ), '#ff0000', "SVG red" );
is( name2rgb( 'www:red' ), '#ff0000', "WWW red" );

# Name normalization
is( name2rgb( 'RED' ), '#ff0000', "Default red - caps1" );
is( name2rgb( 'rEd' ), '#ff0000', "Default red - caps2" );
is( name2rgb( ' red ' ), '#ff0000', "Default red - whitespace1" );
is( name2rgb( ' rEd   ' ), '#ff0000', "Default red - whitespace2" );
is( name2rgb( " r\tEd   " ), '#ff0000', "Default red - whitespace3" );
is( name2rgb( " r   E\nd   " ), '#ff0000', "Default red - whitespace4" );
is( name2rgb( ' x11:red' ), '#ff0000', "X11 red - whitespace1" );
is( name2rgb( ' x11: red' ), '#ff0000', "X11 red - whitespace2" );

ok( name2rgb( 'grey' ), 'grey' );
ok( name2rgb( 'gray' ), 'gray' );
is( name2rgb( 'grey' ), name2rgb( 'gray' ), "grey == gray" );
is( name2rgb( 'grey' ), "#bebebe" );

# More lookup
ok( !defined name2rgb( 'redd' ), "redd not found" );
ok( !defined name2rgb( 'www:redd' ), "www:redd not found" );

ok( name2rgb( 'lightgoldenrod' ), "lightgoldenrod" );
ok( name2rgb( 'svg:beige' ), 'svg:beige' );

ok( !defined name2rgb( 'www:beige' ), "www:beige not found" );
ok( defined name2rgb( 'lemonchiffon2' ), "lemonchiffon2 - only in X11" );

ok( !defined name2rgb( ':red' ), ":red not found - force global namespace" );

# Evaluate in list context
my @f = name2rgb( 'blue' );
is( scalar @f, 3, "Return triple" );
ok( 0 <= $f[0] && $f[0] < 256, "Name=Blue - Red ok" );
ok( 0 <= $f[1] && $f[1] < 256, "Name=Blue - Green ok" );
ok( 0 <= $f[2] && $f[2] < 256, "Name=Blue - Blue ok" );

# ---

# Register a color
my $redd = register_name( 'svg:redd', 255, 1, 1 );
ok( !defined $redd, "Old name did not exist" );

ok( !defined name2rgb( 'redd' ), "redd not found in default namespace" );
is( name2rgb( 'svg:redd' ), '#ff0101', "redd found in proper namespace" );

$redd = register_name( 'svg:redd', 255, 2, 2 );
is( $redd, '#ff0101', "Old name is found" );
is( name2rgb( 'svg:redd' ), '#ff0202', "Renewed redd found" );

my @redd = register_name( 'svg:redd', 255, 2, 2 ); # Eval in list context
is( scalar @redd, 3, "Return triple" );
ok( 0 <= $redd[0] && $redd[0] < 256, "Name=Redd - Red ok" );
ok( 0 <= $redd[1] && $redd[1] < 256, "Name=Redd - Green ok" );
ok( 0 <= $redd[2] && $redd[2] < 256, "Name=Redd - Blue ok" );

$redd = register_name( 'x11:redd', 255, 3, 3 );
ok( !defined $redd, "redd not found in default namespace" );
is( name2rgb( 'x11:redd' ), '#ff0303', "redd found in X11 namespace" );
is( name2rgb( 'redd' ), '#ff0303', "redd found in default namespace" );
ok( !defined name2rgb( ':redd' ), "redd not found in global namespace" );

$redd = register_name( 'redd', 255, 4, 4 );
ok( !defined $redd, "Global namespace empty" );
is( name2rgb( 'redd' ), '#ff0404', "redd value ok 1" );
is( name2rgb( ':redd' ), '#ff0404', ":redd value ok 1" );
is( name2rgb( ':redd' ), name2rgb( 'redd' ), ":redd = redd 1" );

$redd = register_name( ':redd', 255, 4, 4 );
ok( defined $redd, ":redd clobbers redd" );
is( $redd, '#ff0404', "redd proper value" );
is( name2rgb( 'redd' ), '#ff0404', "redd value ok 2" );
is( name2rgb( ':redd' ), '#ff0404', ":redd value ok 2" );
is( name2rgb( ':redd' ), name2rgb( 'redd' ), ":redd = redd 2" );

# Note: now :redd=ff0404, x11:redd=ff0303, svg:redd=ff0202

register_name( 'x11:ggrn', 1, 255, 1 );

is( name2rgb( 'svg:redd' ), '#ff0202', "Explicit ns lookup" );
is( name2rgb( 'redd' ), '#ff0404', "Implicit ns lookup - global first" );
isnt( name2rgb( 'redd' ), name2rgb( 'x11:redd' ),"Implicit - default ns last");

is( name2rgb( 'x11:ggrn' ), '#01ff01', "Explicit X11 lookup" );
is( name2rgb( 'ggrn' ), '#01ff01', "Implicit lookup - default ns" );
ok( !defined name2rgb( ':ggrn' ), "Force global - not found" );

# ---

# Change default namespace
my $ns = set_default_namespace( 'svg' );
is( $ns, 'x11', "Old namespace: X11" );
is( get_default_namespace(), 'svg', "New namespace: svg" );

my $ggrn = register_name( 'svg:ggrn', 2, 255, 2 );
ok( !defined $ggrn, "svg:ggrn did not exist" );
is( name2rgb( 'ggrn' ), '#02ff02', "Found ggrn in new default ns" );
is( name2rgb( 'ggrn' ), name2rgb( 'svg:ggrn' ), "Is equal to SVG ns" );
isnt( name2rgb( 'ggrn' ), name2rgb( 'x11:ggrn' ), "Is not equal to X11 ns" );
is( name2rgb( 'x11:ggrn' ), '#01ff01', "X11 ggrn found" );
is( name2rgb( 'svg:ggrn' ), '#02ff02', "svg ggrn found" );

isnt( name2rgb( 'ggrn' ), name2rgb( ':ggrn' ), "Is not equal to global ns" );
ok( !defined name2rgb( ':ggrn' ), "Global ggrn not defined" );
