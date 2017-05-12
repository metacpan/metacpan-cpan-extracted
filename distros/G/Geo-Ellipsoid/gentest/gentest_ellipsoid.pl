#!/usr/local/bin/perl
#
#	gentest_ellipsoid.pl
#
#	Test Ellipsoid.pm module coordinate transformations and
#	generate test programs.

use strict;
use warnings;
$|=1;

use Getopt::Long;
use Math::Trig;

# get the uninstalled version of Geo::Ellipsoid
BEGIN{
  require '../lib/Geo/Ellipsoid.pm';
}

my $debug = 0;
my $xdebug = 0;
my $testing = 0;
my $print;
my $write;

# global constants
my $twopi = 2 * pi;
my $halfpi = pi/2;
my $degrees_per_radian = 180.0/pi;
my $degree = pi/180.0;
my $miles = 1609.344;
my $foot  = 0.3048;
my $nm    = 1852.0;
my $kilo  = 1000.0;

# global variables
my $e = Geo::Ellipsoid->new( units => 'degrees' );
my $e_pos = Geo::Ellipsoid->new( units => 'degrees' );
my $e_sym = Geo::Ellipsoid->new( 
  units => 'degrees', 
  bearing => 1, 
  longitude => 1 
);

my $outdir = '.';
#my $outdir = 'Ellipsoid';

# make copy of original set of pre-defined ellipsoids
my @ellipsoids = keys %Geo::Ellipsoid::ellipsoids;

print "Enter test_ellipsoid\n\n";

my $counter = 0;

die("Invalid options: @ARGV") unless GetOptions(
  'd' => \$debug,
  'x' => \$xdebug,
  'p' => \$print,
  'o' => \$write,
);

srand(0);	# set random seed for repeatability

# create directory to hold generated files
unless( -d $outdir ) {
  mkdir $outdir or die("Can't create directory $outdir: $!");
}

my @files = qw( 
  load create defaults set scale to at location range bearing displacement
);
my %tests;
for my $i ( 0..$#files ) {
  my $t = $files[$i];
  $tests{$t}{count} = 0;
  $tests{$t}{code} = [];
  $tests{$t}{file} = sprintf("%s/%.2d-%s",$outdir,$i,$t);
}

test_loading_module();
test_object_creation();
test_defaults();
test_scale_factors();
test_set();
test_inverse();
test_forward();
write_code();

exit(0);

sub test_loading_module
{
  print "Generate loading module tests\n" if $debug;
  my $code = <<EOS;
BEGIN { use_ok( 'Geo::Ellipsoid' ); }
my \$e = Geo::Ellipsoid->new();
isa_ok( \$e, 'Geo::Ellipsoid');
my \$e1 = Geo::Ellipsoid->new( units => 'degrees' );
isa_ok( \$e1, 'Geo::Ellipsoid');
my \$e2 = Geo::Ellipsoid->new( distance_units => 'foot' );
isa_ok( \$e2, 'Geo::Ellipsoid');
my \$e3 = Geo::Ellipsoid->new( bearing => 1 );
isa_ok( \$e3, 'Geo::Ellipsoid');
my \$e4 = Geo::Ellipsoid->new( longitude => 1 );
isa_ok( \$e4, 'Geo::Ellipsoid');
EOS
  push(@{$tests{load}{code}},$code);
  $tests{load}{count} = 6;
  
  for my $s ( 
    qw{ 
      new 
      set_units 
      set_distance_unit 
      set_ellipsoid 
      set_custom_ellipsoid 
      set_longitude_symmetric 
      set_bearing_symmetric 
      set_defaults
      scales 
      range 
      bearing 
      at 
      to 
      displacement 
      location
    } 
  
) {
    my $t = "can_ok( 'Geo::Ellipsoid', '$s' );";
    push(@{$tests{load}{code}},$t);
    $tests{load}{count}++;
  }
}

sub test_object_creation
{
  print "Generate object creation tests\n" if $debug;
  $counter = 1;
  #	create
  #
  #	Generate tests for object creation
  #
  # retrieve list of ellipsoids
  print "Ellipsoids:\n" if $print;
  my $i = 1;
  foreach my $ell ( sort keys %Geo::Ellipsoid::ellipsoids ) {
    my( $a, $rf ) = @{$Geo::Ellipsoid::ellipsoids{$ell}};
    printf "  %20s  %12.3f  %s\n", $ell, $a, $rf if $print;
    write_create_test($ell) if $write;
  }
  
  # test custom ellipsoid
  my $custom = Geo::Ellipsoid->new();
  my $name = 'CUSTOM';
  my $major = 6378000;
  my $recip = 300;
  my $var = '$e'.$counter++;
  $custom->set_custom_ellipsoid($name,$major,$recip);
  
  my $code = "my $var = Geo::Ellipsoid->new();\n" .
  "${var}->set_custom_ellipsoid('$name',$major,$recip);";
  push( @{${tests{create}}{code}}, $code);
  write_create_test_code($name,$var,$custom);

  # warn user about upcoming warning message
  push( @{${tests{create}}{code}}, 
    qq(print STDERR "\\n#\\n#\\tWarning about 'Infinite flattening' OK here\\n#\\n;";)
  );

  my $sphere = Geo::Ellipsoid->new;
  $var = '$e'.$counter++;
  $name = 'sphere';
  $major = 6378137;
  $sphere->set_custom_ellipsoid($name,$major,0);
  $code = "my $var = Geo::Ellipsoid->new();\n" .
  "${var}->set_custom_ellipsoid('sphere',$major,0);";
  push( @{${tests{create}}{code}}, $code);
  write_create_test_code(uc $name,$var,$sphere);
}

sub test_defaults
{
  print "Generate set defaults tests\n" if $debug;

  my $code = <<'EOS';
my $e1 = Geo::Ellipsoid->new();
ok( $e1->{ellipsoid} eq 'WGS84' );
ok( $e1->{units} eq 'radians' );
ok( $e1->{distance_units} eq 'meter' );
ok( $e1->{longitude} == 0 );
ok( $e1->{latitude} == 1 );
ok( $e1->{bearing} == 0 );
$e1->set_defaults( 
  ellipsoid => 'NAD27',
  units => 'degrees', 
  distance_units => 'kilometer',
  longitude => 1,
  bearing => 1
);
my $e2 = Geo::Ellipsoid->new();
ok( $e2->{ellipsoid} eq 'NAD27' );
ok( $e2->{units} eq 'degrees' );
ok( $e2->{distance_units} eq 'kilometer' );
ok( $e2->{longitude} == 1 );
ok( $e2->{latitude} == 1 );
ok( $e2->{bearing} == 1 );
EOS
  push( @{${tests{defaults}}{code}}, $code);
  ${$tests{defaults}}{count} = 12;

  $counter = 3;
  #	defaults
  #
  #	Generate tests for setting default values
  #
  # retrieve list of ellipsoids
  foreach my $ell ( @ellipsoids ) {
    my( $a, $rf ) = @{$Geo::Ellipsoid::ellipsoids{$ell}};
    write_defaults_test($ell) if $write;
  }
}

sub write_defaults_test
{
  my( $ell ) = @_;
  my $var = '$e'.$counter++;
  my $e = Geo::Ellipsoid->new( ellipsoid => $ell, units => 'degrees' );
  my $a = $e->{equatorial};
  my $b = $e->{polar};
  my $f = $e->{flattening};
  print "  e=$ell, var=$var, a=$a, b=$b, f=$f\n" if $debug;

  my $code = <<EOS;
Geo::Ellipsoid->set_defaults(units=>'degrees',ell=>'$ell');
ok( \$Geo::Ellipsoid::defaults{ellipsoid} eq '$ell' );
ok( \$Geo::Ellipsoid::defaults{units} eq 'degrees' );
my $var = Geo::Ellipsoid->new();
ok( defined ${var} );
ok( ${var}->isa( 'Geo::Ellipsoid' ) );
ok( ${var}->{ellipsoid} eq '$ell' );
ok( ${var}->{units} eq 'degrees' );
delta_ok( ${var}->{equatorial}, $a );
delta_ok( ${var}->{polar}, $b );
delta_ok( ${var}->{flattening}, $f );
EOS
  push( @{${tests{defaults}}{code}}, $code );
  ${$tests{defaults}}{count} += 9;
}
 
sub test_inverse
{
  print "Generate inverse tests\n" if $debug;
  my $n = 1;
  my $lat0 = -88;
  my $latinc = 88;
  my $lon0 = 1;
  my $loninc = 89;
  $e->set_units('degrees');
  my $code = q|my $e = Geo::Ellipsoid->new(units=>'degrees');|;
  $tests{to}{code} = [ $code, 'my( $r, $a );' ];
  ${$tests{to}}{count} = 0;

  $code = <<'EOS';
my $e_pos = Geo::Ellipsoid->new(units=>'degrees');
my $e_sym = Geo::Ellipsoid->new(units=>'degrees',bearing=>1);
my($azp,$azs);
EOS
  $tests{bearing}{code} = [ $code ];
  ${$tests{bearing}}{count} = 0;

  $code = <<'EOS';
my $e_meter = Geo::Ellipsoid->new(units=>'degrees');
my $e_kilo = Geo::Ellipsoid->new(units=>'degrees',distance=>'kilo');
my $e_mile = Geo::Ellipsoid->new(units=>'degrees',distance=>'mile');
my $e_foot = Geo::Ellipsoid->new(units=>'degrees',distance=>'foot');
my $e_nm = Geo::Ellipsoid->new(units=>'degrees',distance=>'nm');
my( $r1,$r2,$r3,$r4,$r5);
EOS
  $tests{range}{code} = [ $code ];
  ${$tests{range}}{count} = 0;

  # test endpoints: poles and equator
  for( my $lat1 = $lat0; $lat1 <= 90; $lat1 += $latinc ) {
    for( my $lon1 = $lon0; $lon1 <= 270; $lon1 += $loninc ) {
      next if abs($lat1) == 90 and $lon1 > 0;
      print "  loc1 = ($lat1,$lon1)\n" if $debug;
      for( my $lat2 = $lat0; $lat2 <= 90; $lat2 += $latinc ) {
        for( my $lon2 = $lon0; $lon2 <= 270; $lon2 += $loninc ) {
          print "  loc2 = ($lat2,$lon2)\n" if $debug;

          # skip tests where points are anti-podal
          next if $lat2 == -$lat1 and abs($lon1-$lon2) == 180;
          
          my( $r, $az ) = $e->to($lat1,$lon1,$lat2,$lon2);
          print "$n: ($lat1,$lon1)->($lat2,$lon2): ($r,$az)\n" if $debug;
          $n++;

          test_range($r,$lat1,$lon1,$lat2,$lon2);
          test_bearing($lat1,$lon1,$lat2,$lon2);
          test_to($r,$az,$lat1,$lon1,$lat2,$lon2);
        }
      }
    }
  }
  
  # test random values
  for ( 1..100 ) {
    my $lat1 = -88 + rand 176;
    my $lon1 = 1 + rand 358;
    my $lat2 = -88 + rand 176;
    my $lon2 = rand 360;

    # skip tests where points are anti-podal
    next if (abs($lat2 + $lat1) < 1) and 
    	    (abs($lon1 - $lon2 - 180) < 1);

    my ( $r, $az ) = $e->to($lat1,$lon1,$lat2,$lon2);
    print "$n: ($lat1,$lon1)->($lat2,$lon2)\n" if $debug;
    test_range($r,$lat1,$lon1,$lat2,$lon2);
    test_bearing($lat1,$lon1,$lat2,$lon2);
    test_to($r,$az,$lat1,$lon1,$lat2,$lon2);
    $n++;
  }
}

sub test_to
{
  print "Generate to tests\n" if $debug;
  my( $range, $bearing, $lat1, $lon1, $lat2, $lon2 ) = @_;
  my $n = 1;
  my $l1 = sprintf "%.6f, %.6f", $lat1, $lon1; 
  my $l2 = sprintf "%.6f, %.6f", $lat2, $lon2;
  
  my $t = sprintf "(\$r,\$a) = \$e->to( %.6f, %.6f, %.6f, %.6f );",
    $lat1, $lon1, $lat2, $lon2;
    
  my $code = "( \$r, \$a ) = \$e->to($l1,$l2);\n";
  if( $range < 100.0 ) {
    $code .= "delta_within( \$r, $range, 0.1 );\n";
  }else{
    $code .= "delta_ok( \$r, $range );\n";
  }

  # if two locations are not the same, test the bearing angle
  if( $l1 ne $l2 ) {
    $code .= "delta_within( \$a, $bearing, 0.0001 );\n";
    $n++;
  }
  push( @{$tests{to}{code}}, $code );
  ${$tests{to}}{count} += $n;
}

sub test_range
{
  print "Generate range tests\n" if $debug;
  my( $range, $lat1, $lon1, $lat2, $lon2 ) = @_;
  my $m = sprintf "range(%.6f,%.6f,%.6f,%.6f);", $lat1, $lon1, $lat2, $lon2;
  my $r2 = $range / $kilo;
  my $r3 = $range / $miles;
  my $r4 = $range / $foot;
  my $r5 = $range / $nm;

  my $code = <<EOS;
\$r1 = \$e_meter->$m
\$r2 = \$e_kilo->$m
\$r3 = \$e_mile->$m
\$r4 = \$e_foot->$m
\$r5 = \$e_nm->$m
delta_within( \$r1, $range, 1.0 );
delta_within( \$r2, $r2, 1.0 );
delta_within( \$r3, $r3, 1.0 );
delta_within( \$r4, $r4, 1.0 );
delta_within( \$r5, $r5, 1.0 );
EOS
  push( @{$tests{range}{code}}, $code );
  ${$tests{range}}{count} += 5;
}

sub test_bearing
{
  my( $lat1, $lon1, $lat2, $lon2 ) = @_;
  printf "test_bearing([%.2f,%.2f]->[%.2f,%.2f])\n",
    $lat1, $lon1, $lat2, $lon2 if $debug;

  my $l1 = sprintf "%.6f,%.6f", $lat1, $lon1; 
  my $l2 = sprintf "%.6f,%.6f", $lat2, $lon2;
  return if $l1 eq $l2;

  my $bp = $e_pos->bearing(@_);
  my $bs = $e_sym->bearing(@_);
  printf("p1=(%.2f,%.2f), p2=(%.2f,%.2f), bp=%.2f , bs=%.2f\n",
    $lat1,$lon1,$lat2,$lon2,$bp,$bs) if $debug;

  # skip positive test if result too near zero or 180
  if( abs($bp) > 0.1 && abs($bp-360) > 0.1 ) {
    my $code = <<EOS;
\$azp = \$e_pos->bearing($l1,$l2);
delta_within( \$azp, $bp, 0.1 );
EOS
    push( @{$tests{bearing}{code}}, $code );
    ${$tests{bearing}}{count} += 1;
  }

  # skip symmetric test if result too near -180 or +180
  if( abs($bs-180) > 0.1 && abs($bs+180) > 0.1 ) {
    my $code = <<EOS;
\$azs = \$e_sym->bearing($l1,$l2);
delta_within( \$azs, $bs, 0.1 );
EOS
    push( @{$tests{bearing}{code}}, $code );
    ${$tests{bearing}}{count} += 1;
  }
}

sub test_forward
{
  print "Generate forward tests\n" if $debug;
  my $n = 1;
  $e->set_units('degrees');
  my $code = <<'EOS';
my $e1 = Geo::Ellipsoid->new(units=>'degrees');
my $e2 = Geo::Ellipsoid->new(units=>'degrees',longitude=>1);
my($lat1,$lon1,$lat2,$lon2,$x,$y);
EOS

  $tests{location}{code} = [ $code ];
  ${$tests{location}}{count} = 0;
  $tests{displacement}{code} = [ $code ];
  ${$tests{displacement}}{count} = 0;
  $tests{at}{code} = [ $code ];
  ${$tests{at}}{count} = 0;

  # test random values within 10,000 meters
  for ( 1..100 ) {

    my $lat1 = -80 + rand 160;
    my $lon1 = rand 360;

    my $range = rand 10000;
    my $bearing = rand 360;
    my $az = deg2rad($bearing);
    
    my $x = $range * sin($az);
    my $y = $range * cos($az);
    
    my ( $lat2, $lon2 ) = $e->at($lat1,$lon1,$range,$bearing);
    print "$n: ($lat1,$lon1,\n  $range,$bearing,\n  $x,$y)->\n  ($lat2,$lon2)\n"
      if $debug;
    test_at($lat1,$lon1,$range,$bearing);
    test_displacement($lat1,$lon1,$lat2,$lon2);
    test_location($lat1,$lon1,$x,$y);
    $n++;
  }
}

sub test_at
{
  print "Generate at tests\n" if $debug;
  my( $lat1, $lon1, $range, $bearing ) = @_;
  #my( $lat1, $lon1, $range, $bearing, $lat2, $lon2 ) = @_;
  my( $lat3, $lon3 ) = $e_pos->at( $lat1, $lon1, $range, $bearing );
  my( $lat4, $lon4 ) = $e_sym->at( $lat1, $lon1, $range, $bearing );
  my $f = sprintf "at(%.6f,%.6f,%.6f,%.6f)",
    $lat1, $lon1, $range, $bearing;
  my $code = <<EOS;
(\$lat1,\$lon1) = \$e1->$f;
(\$lat2,\$lon2) = \$e2->$f;
delta_ok( \$lat1, $lat3 );
delta_ok( \$lon1, $lon3 );
delta_ok( \$lat2, $lat4 );
delta_ok( \$lon2, $lon4 );
EOS
  push( @{$tests{at}{code}}, $code );
  ${$tests{at}}{count} += 4;
}

sub test_location
{
  print "Generate location tests\n" if $debug;
  my( $lat1, $lon1, $x, $y ) = @_;
  my( $lat3, $lon3 ) = $e_pos->location( $lat1, $lon1, $x, $y );
  my( $lat4, $lon4 ) = $e_sym->location( $lat1, $lon1, $x, $y );
  my $f = sprintf "location(%.6f,%.6f,%.6f,%.6f)", $lat1, $lon1, $x, $y;
  my $code = <<EOS;
(\$lat1, \$lon1) = \$e1->$f;
(\$lat2, \$lon2) = \$e2->$f;
delta_ok( \$lat1, $lat3 );
delta_ok( \$lon1, $lon3 );
delta_ok( \$lat2, $lat4 );
delta_ok( \$lon2, $lon4 );
EOS
  push( @{$tests{location}{code}}, $code );
  ${$tests{location}}{count} += 4;
}

sub test_displacement
{
  print "Generate displacement tests\n" if $debug;
  my @args = @_;
  my( $lat1, $lon1, $lat2, $lon2 ) = @args;
  my( $x, $y ) = $e->displacement(@args);
  my $t = sprintf "(\$x, \$y) = \$e1->displacement(%.6f,%.6f,%.6f,%.6f);",
    $lat1, $lon1, $lat2, $lon2;
  my $code = <<EOS;
$t
delta_within( \$x, $x, 1.0 );
delta_within( \$y, $y, 1.0 );
EOS
  push( @{$tests{displacement}{code}}, $code );
  ${$tests{displacement}}{count} += 2;

}

sub test_set
{
  print "Generate set tests\n" if $debug;
  print "Test set_units:\n";
  my $code = <<EOS;
my \$e = Geo::Ellipsoid->new();
EOS
  push( @{$tests{set}{code}}, $code );
  my $n = 1;
  test_set_units($n++,'degrees');
  test_set_units($n++,'radians');
  test_set_units($n++,'DEG','degrees');
  test_set_units($n++,'Deg','degrees');
  test_set_units($n++,'deg','degrees');
  test_set_units($n++,'RAD','radians');
  test_set_units($n++,'Rad','radians');
  test_set_units($n++,'rad','radians');
  
  for my $ell ( sort @ellipsoids ) {
    test_set_ellipsoid($n++,$ell) unless $ell =~ /custom/i;
  }
}

sub test_set_ellipsoid
{
  print "Generate set ellipsoid tests\n" if $debug;
  my( $n, $ell ) = @_;
  $e->set_ellipsoid($ell);
  print "test_set_ellipsoid($n,$ell)\n" if $debug;
  my $code = <<EOS;
my \$e$n = Geo::Ellipsoid->new();
\$e->set_ellipsoid('$ell');
\$e${n}->set_ellipsoid('$ell');
ok( \$e->{ellipsoid} eq '$ell' );
ok( \$e${n}->{ellipsoid} eq '$ell' );
delta_ok( \$e${n}->{equatorial}, $e->{equatorial} ); 
delta_ok( \$e${n}->{polar}, $e->{polar} ); 
delta_ok( \$e${n}->{flattening}, $e->{flattening} ); 
delta_ok( \$e->{equatorial}, $e->{equatorial} ); 
delta_ok( \$e->{polar}, $e->{polar} ); 
delta_ok( \$e->{flattening}, $e->{flattening} ); 
EOS
  push(@{$tests{set}{code}}, $code);
  ${$tests{set}}{count} += 8;
}
  
sub test_set_units
{
  print "Generate set units tests\n" if $debug;
  my( $n, $units, $default ) = @_;
  $default = $units unless $default;
  print "test set_units($n,$units,$default)\n" if $debug;
  my $code = <<EOS;
my \$e$n = Geo::Ellipsoid->new();
\$e->set_units('$units');
\$e${n}->set_units('$units');
ok( \$e->{units} eq '$default' );
ok( \$e${n}->{units} eq '$default' );
EOS
  push(@{$tests{set}{code}}, $code);
  ${$tests{set}}{count} += 2;
}
  
sub write_create_test
{
  my( $ell ) = @_;
  my $var = '$e'.$counter++;
  my $e = Geo::Ellipsoid->new( ellipsoid => $ell );
  my $t = "my $var = Geo::Ellipsoid->new(ell=>'$ell');";
  push( @{${tests{create}}{code}}, $t);
  write_create_test_code($ell,$var,$e);
}

sub write_create_test_code
{
  my( $ell, $var, $e ) = @_;
  my $a = $e->{equatorial};
  my $b = $e->{polar};
  my $f = $e->{flattening};
  print "  e=$ell, var=$var, a=$a, b=$b, f=$f\n" if $debug;
  my $code = <<EOS;
ok( defined ${var} );
ok( ${var}->isa( 'Geo::Ellipsoid' ) );
ok( ${var}->{ellipsoid} eq '$ell' );
delta_ok( ${var}->{equatorial}, $a );
delta_ok( ${var}->{polar}, $b );
EOS

  # use delta_within instead of delta_ok if flattening is zero
  if( $f == 0 ) {
    $code .= "delta_within( ${var}->{flattening}, $f, 1e-6 );\n";
  }else{
    $code .= "delta_ok( ${var}->{flattening}, $f );\n";
  }

  $code .= <<EOS;
ok( exists \$Geo::Ellipsoid::ellipsoids{'$ell'} );
EOS
  push( @{${tests{create}}{code}}, $code );
  ${$tests{create}}{count} += 7;
}

sub write_code
{
  # write out test code
  if( $write ) {
    for my $t ( @files ) {
      my $ntest = $tests{$t}{count};
      if( $ntest > 0 ) {
        print "Write test code for '$t' with $ntest tests ...\n";
        write_test_code($t);
      }else{
        print "No tests for '$t' yet\n";
      }
    }
  }
}

sub test_scale_factors
{
  print "Generate scale factor tests\n" if $debug;
  # test scale factors
  if( $print ) {
    print 
    "\nPrint Latitude and Longitude scale factors (meters per degree):\n\n"; 
    print "+----------------------------------------+\n";
    print "| Latitude |    F(Lat)    |    F(Lon)    |\n";
    print "|----------|--------------|--------------|\n";
  }
  $e = Geo::Ellipsoid->new( ellipsoid => 'WGS84', units => 'degrees' );
  my $code = "my \$e = Geo::Ellipsoid->new( units => 'degrees' );\n" .
             "my( \$xs, \$ys );";
  push( @{$tests{scale}{code}}, $code );
  for( my $l = 0; $l <= 89; $l++ ) {
    print_latlon_scale($l);
  }
  print "+----------------------------------------+\n" if $print;
}

sub print_latlon_scale
{
  my $deg = shift;
  my $t = $tests{scale};
  print "print_latlon_scale($deg)\n" if $debug;
  my( $r_lat, $r_lon ) = $e->scales($deg);
  my $code = <<EOS;
( \$ys, \$xs ) = \$e->scales($deg);
delta_ok( \$xs, $r_lon );
delta_ok( \$ys, $r_lat );
EOS
  push( @{$t->{code}}, $code );
  $t->{count} += 2;
  printf "| %8d | %12.0f | %12.0f |\n", $deg, $r_lat, $r_lon if $print;
}

sub write_test_code
{
  my $t = shift;
  print "write test code for test $t with ${$tests{$t}}{count} tests\n"
    if $debug;
  my $n = ${$tests{$t}}{count};
  my $file = ${$tests{$t}}{file};
  print "Writing test program $file with $n tests...\n";
  open( my $fh, '>', "$file.t" ) or die("Can't create $file.t: $!");
  write_prolog($fh,$t,$n);
  print $fh join("\n", @{${$tests{$t}}{code}}), "\n";  
  close($fh);
}

sub write_prolog
{
  my( $fh, $test, $n ) = @_;
  print "write prolog for ($test,$n)\n" if $debug;
  print $fh <<EOS;
#!/usr/local/bin/perl
# Test Geo::Ellipsoid $test
use Test::More tests => $n;
use Test::Number::Delta relative => 1e-6;
use Geo::Ellipsoid;
use blib;
use strict;
use warnings;

EOS
}

my $earth = Geo::Ellipsoid->new(
  units => 'degrees', 
  ellipsoid => 'WGS84', 
  debug => $debug 
);

printf "    Equatorial radius = %.10f\n", $earth->{equatorial};
printf "         Polar radius = %.10f\n", $earth->{polar};

my $ef = $earth->{flattening};
my $rf = 1.0 / $ef;
printf   "           Flattening = %.16f\n", $ef;
printf   "         Eccentricity = %.16f\n", $earth->{eccentricity};
printf   "Reciprocal flattening = %.8f\n", $rf;

# print displacements between various locations
my @dfw_arp = (Angle(32,53,45.42),Angle(-97,2,13.92));
my @ffc_orig = (Angle(32,52,44.02),Angle(-97,1,48.29));
my @ord_orig = (Angle(41,58,43.48),Angle(-87,54,11.31));

my @c1 = (Angle(0,0,0),Angle(0,0,0));
my @c2 = (Angle(90,0,0),Angle(0,0,0));
my @c3 = (Angle(0,0,0),Angle(90,0,0));
my @c4 = (Angle(0,0,0),Angle(89,0,0));
my @c5 = (Angle(-1,0,0),Angle(90,0,0));
my @c6 = (Angle(0,0,0),Angle(-90,0,0));
my @c7 = (Angle(1,0,0),Angle(-90,0,0));
my @c8 = (Angle(0.1,0,0),Angle(0.1,0,0));

exit(0);

############################# subroutines ###############################

sub print_displacement
{
  my( $east, $north ) = @_;
  my $range = sqrt( $east*$east + $north*$north );
  my $bearing = atan2($north,$east);
  my $deg = $bearing * $degrees_per_radian;
  print "displacement = ($east,$north), r=$range, az=$bearing = $deg deg.\n";
}

sub print_vector
{
  my( $lat1deg, $lat1min, $lat1sec,
      $lon1deg, $lon1min, $lon1sec,
      $lat2deg, $lat2min, $lat2sec,
      $lon2deg, $lon2min, $lon2sec) = @_;
  my $lat1 = Angle($lat1deg,$lat1min,$lat1sec);
  my $lon1 = Angle($lon1deg,$lon1min,$lon1sec);
  my $lat2 = Angle($lat2deg,$lat2min,$lat2sec);
  my $lon2 = Angle($lon2deg,$lon2min,$lon2sec);

  my @here = ( $lat1, $lon1 );
  my @there = ( $lat2, $lon2 );

  print "Print range and bearing from:\n";
  print "(${lat1deg}d ${lat1min}m ${lat1sec})-(" .
    "${lon1deg}d ${lon1min}m ${lon1sec}) ";
  printf "[%.8f,%.8f] to\n", $lat1, $lon1;
  print 
  "(${lat2deg}d ${lat2min}m ${lat2sec})-(${lon2deg}d ${lon2min}m ${lon2sec}) ";
  printf "[%.8f,%.8f]\n", $lat2, $lon2;

  print_dist(@here,@there);
}

sub print_dist
{
  my( $lat1, $lon1, $lat2, $lon2 ) = @_;	# in radians
  my $ellipsoid = Geo::Ellipsoid->new(uni=>'radians',ell=>'WGS84',deb=>$debug);
  my $ellipsoid2 = Geo::Ellipsoid->new(uni=>'degrees',ell=>'WGS84',deb=>$debug);
  my( $dlat1, $dlon1, $dlat2, $dlon2 ) = map { $_ * $degrees_per_radian } @_;

  printf "\nHere  = [%.12f,%.12f]\n", $dlat1, $dlon1;
  printf "There = [%.12f,%.12f]\n", $dlat2, $dlon2;
  
  my @d = $ellipsoid->displacement( $lat1, $lon1, $lat2, $lon2 );
  my @e = $ellipsoid2->displacement( $dlat1, $dlon1, $dlat2, $dlon2 );
  my( $range, $bearing ) = $ellipsoid->to( $lat1, $lon1, $lat2, $lon2 );
  my( $range2, $bearing2 ) = $ellipsoid2->to( $dlat1, $dlon1, $dlat2, $dlon2 );
  #$bearing *= $degrees_per_radian;
  print "displacement() returns (@d)\n" if $debug;

  printf "Rad: Range = %.4f m., bearing = %.4f rad.\n", $range, $bearing;
  printf "Rad: East = %.4f m., north = %.4f m.\n", @d;

  printf "Deg: Range = %.4f m., bearing = %.4f deg.\n", $range2, $bearing2;
  printf "Deg: East = %.4f m., north = %.4f m.\n", @e;
}

sub print_target
{
  my( $lat1deg, $lat1min, $lat1sec, 
      $lon1deg, $lon1min, $lon1sec, 
      $range, $degrees ) = @_;

  my $lat1 = Angle($lat1deg,$lat1min,$lat1sec);
  my $lon1 = Angle($lon1deg,$lon1min,$lon1sec);

  my @here = ( $lat1, $lon1 );
  my $ellipsoid = Geo::Ellipsoid->new(
    units=>'radians',
    ellip=>'WGS84',
    debug=>$debug
  );

  my $radians = $degrees / $degrees_per_radian;
  my $x = $range*sin($radians);
  my $y = $range*cos($radians);

  my @d = ($x,$y);

  my @there = $ellipsoid->at(@here,@d);

  printf "Starting at (%.8f,%.8f)\n", @here;
  printf "and going (x=%.4f m.,y=%.4f m.)\n", @d;
  printf "or (%.8f  m.,%.8f deg.)\ngives (%.8f,%.8f)\n", $range, $degrees,
    @there;
}

#	Angle
#
#	Return angle in radians given the list 
#	( degree, minute, second, hundreths-of-second)
#
sub Angle
{
  my $deg = shift || 0;
  my $min = shift || 0;
  my $sec = shift || 0;
  my $csec = shift || 0;	# optional 100th's of a second

  #print "convert (@_) to angle in radians\n" if $debug;
  my $frac = ( $min + (($sec + ($csec/100))/60))/60;
  my $angle = $deg;
  #print "  angle=$angle, frac=$frac\n" if $debug;
  if( $angle < 0 ) {
    $angle += 360 - $frac;
  }else{
    $angle += $frac;
  }
  #print "  angle.frac = $angle\n" if $debug;
  return $angle/$degrees_per_radian;
}

sub polar
{
  my( $x, $y ) = @_;
  my $range = sqrt( $x*$x + $y*$y );
  my $bearing = $halfpi - atan2($y,$x);
  return ($range, $bearing);
}
 
