use strict;
use warnings;
use Geo::Gpx;
use Test::More;

BEGIN {
  eval "use Test::XML";
  plan skip_all => "Test::XML unavailable" if $@;
}

use Test::More tests => 4;

my %refxml = ();
my $k      = undef;

while ( <DATA> ) {
  if ( /^==\s+(\S+)\s+==$/ ) {
    $k = $1;
  }
  elsif ( defined( $k ) ) {
    $refxml{$k} .= $_;
  }
}

my $gpx = Geo::Gpx->new();

my @wpt = (
  {

    # All standard GPX fields
    lat         => 54.786989,
    lon         => -2.344214,
    ele         => 512,
    time        => time(),
    magvar      => 0,
    geoidheight => 0,
    name        => 'My house & home',
    cmt         => 'Where I live',
    desc        => '<<Chez moi>>',
    src         => 'Testing',
    link        => {
      href => 'http://hexten.net/',
      text => 'Hexten',
      type => 'Blah'
    },
    sym           => 'pin',
    type          => 'unknown',
    fix           => 'dgps',
    sat           => 3,
    hdop          => 10,
    vdop          => 10,
    pdop          => 10,
    ageofdgpsdata => 45,
    dgpsid        => 247
  },
  {

    # Fewer fields
    lat  => -38.870059,
    lon  => -151.210030,
    name => 'Sydney, AU'
  }
);

$gpx->waypoints( \@wpt );

# Quick fix for dumbass dependency on RNG being the same everywhere
my $rp = 0;
my @rn = (
  0.03984, 0.08913, 0.12012, 0.84698, 0.35285, 0.00580,
  0.37354, 0.33931, 0.88578, 0.78503, 0.69597, 0.19332,
  0.76844, 0.08150, 0.47062, 0.64957, 0.00072, 0.57271,
  0.73318, 0.80986, 0.96169, 0.96567, 0.52550, 0.57476,
  0.21792, 0.07187, 0.95170, 0.19820, 0.07930, 0.86521,
  0.37511, 0.52225, 0.48271, 0.23808, 0.70230, 0.23426,
  0.05024, 0.44965, 0.96768, 0.17396, 0.11877, 0.65996,
  0.89178, 0.67894, 0.30362, 0.11972, 0.87709, 0.70132,
  0.69666, 0.46293, 0.11827, 0.35612, 0.14679, 0.56480,
  0.43109, 0.21226, 0.59054, 0.78612, 0.79592, 0.94235,
  0.03657, 0.34607, 0.91482, 0.47672, 0.32947, 0.53454,
  0.70178, 0.02437, 0.07496, 0.49284, 0.16772, 0.82976,
  0.27625, 0.12485, 0.68737, 0.32405, 0.06580, 0.13189,
  0.90450, 0.03470, 0.00016, 0.24118, 0.26281, 0.76458,
  0.37970, 0.98307, 0.25990, 0.80449, 0.94870, 0.19664,
  0.38404, 0.35733, 0.69219, 0.14925, 0.38206, 0.62497,
  0.66942, 0.35608, 0.05149, 0.72594,
);

sub not_rand {
  $rp = 0 if $rp == @rn;
  return $rn[ $rp++ ];
}

my $lat  = 54.786989;
my $lon  = -2.344214;
my $next = 1;

sub get_point {
  my $fmt  = shift;
  my $dlat = not_rand( 1 ) - 0.5;
  my $dlon = not_rand( 1 ) - 0.5;

  $lat += $dlat;
  $lon += $dlon;

  if ( $fmt ) {
    return {
      lat  => $lat,
      lon  => $lon,
      name => sprintf( $fmt, $next++ )
    };
  }
  else {
    return {
      lat => $lat,
      lon => $lon
    };
  }
}

my @rte = (
  {
    name   => 'Route 1',
    points => [ map { get_point( 'WPT%d' ) } ( 1 .. 3 ) ]
  },
  {
    name   => 'Route 2',
    points => [ map { get_point( 'WPT%d' ) } ( 1 .. 2 ) ]
  }
);

$gpx->routes( \@rte );

my @trk = (
  {
    name     => 'Track 1',
    segments => [
      { points => [ map { get_point() } ( 1 .. 3 ) ] },
      { points => [ map { get_point() } ( 1 .. 1 ) ] }
    ]
  },
  {
    name     => 'Track 2',
    segments => [ { points => [ map { get_point() } ( 1 .. 5 ) ] } ]
  }
);

$gpx->tracks( \@trk );

$gpx->name( 'Test' );
$gpx->desc( 'Test data' );
$gpx->author(
  {
    name  => 'Andy Armstrong',
    email => {
      id     => 'andy',
      domain => 'hexten.net'
    },
    link => {
      href => 'http://hexten.net/',
      text => 'Hexten'
    }
  }
);
$gpx->copyright( '(c) Anyone' );
$gpx->link(
  {
    href => 'http://www.topografix.com/GPX',
    text => 'GPX Spec',
    type => 'unknown'
  }
);
$gpx->time( time() );
$gpx->keywords( [ 'this', 'that', 'the other' ] );

for my $version ( keys %refxml ) {
  my $xml = normalise( $refxml{$version} );
  my $gen = normalise( $gpx->xml( $version ) );
  is_xml( $gen, $xml, 'generated version ' . $version );

  # Parse reference XMLs
  my $ngpx = Geo::Gpx->new( xml => $refxml{$version} );
  my $ngen = normalise( $ngpx->xml() );
  is_xml( $ngen, $xml, 'reparsed version ' . $version );
}

sub save_if_diff {
  my ( $base, $gen, $orig ) = @_;
  if ( $gen ne $orig ) {
    save( "$base-orig.gpx", $orig );
    save( "$base-gen.gpx",  $gen );
  }
}

sub save {
  my ( $name, $xml ) = @_;
  open( my $fh, '>', $name ) or die "Can't write $name ($!)\n";
  print $fh $xml;
  close( $fh );
}

sub normalise {
  my $xml = shift;

  # Remove leading spaces in case we decide to indent the output
  $xml =~ s{^\s+}{}msg;
  my $fix_time = sub {
    my $tm = shift;
    $tm =~ s{\d}{9}g;
    $tm =~ s{[+-]}{-}g;
    return $tm;
  };
  $xml =~ s{(<time>)(.*?)(</time>)}{$1 . $fix_time->($2) . $3}eg;
  my $fix_coord = sub {
    my $co = shift;
    return sprintf( "%.6f", $co );
  };
  $xml =~ s{((?:lat|lon)=\")([^\"]+)(\")}{$1 . $fix_coord->($2) . $3}eg;
  return $xml;
}

__END__

== 1.0 ==
<?xml version="1.0" encoding="utf-8"?>
<gpx xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.0" creator="Geo::Gpx" xsi:schemaLocation="http://www.topografix.com/GPX/1/0 http://www.topografix.com/GPX/1/0/gpx.xsd" xmlns="http://www.topografix.com/GPX/1/0">
  <name>Test</name>
  <desc>Test data</desc>
  <author>Andy Armstrong</author>
  <email>andy@hexten.net</email>
  <time>2007-02-11T00:54:27+00:00</time>
  <keywords>this, that, the other</keywords>
  <copyright>(c) Anyone</copyright>
  <url>http://www.topografix.com/GPX</url>
  <urlname>GPX Spec</urlname>
  <bounds maxlat="54.884859" maxlon="-2.344214" minlat="-38.870059" minlon="-151.21003" />
  <rte>
    <name>Route 1</name>
    <rtept lat="54.326829" lon="-2.755084">
      <name>WPT1</name>
    </rtept>
    <rtept lat="53.946949" lon="-2.408104">
      <name>WPT2</name>
    </rtept>
    <rtept lat="53.799799" lon="-2.902304">
      <name>WPT3</name>
    </rtept>
  </rte>
  <rte>
    <name>Route 2</name>
    <rtept lat="53.673339" lon="-3.062994">
      <name>WPT4</name>
    </rtept>
    <rtept lat="54.059119" lon="-2.777964">
      <name>WPT5</name>
    </rtept>
  </rte>
  <trk>
    <name>Track 1</name>
    <trkseg>
      <trkpt lat="54.255089" lon="-3.084644">
      </trkpt>
      <trkpt lat="54.523529" lon="-3.503144">
      </trkpt>
      <trkpt lat="54.494149" lon="-3.353574">
      </trkpt>
    </trkseg>
    <trkseg>
      <trkpt lat="53.994869" lon="-3.280864">
      </trkpt>
    </trkseg>
  </trk>
  <trk>
    <name>Track 2</name>
    <trkseg>
      <trkpt lat="54.228049" lon="-2.971004">
      </trkpt>
      <trkpt lat="54.689739" lon="-2.505334">
      </trkpt>
      <trkpt lat="54.715239" lon="-2.430574">
      </trkpt>
      <trkpt lat="54.433159" lon="-2.858704">
      </trkpt>
      <trkpt lat="54.884859" lon="-3.160504">
      </trkpt>
    </trkseg>
  </trk>
  <wpt lat="54.786989" lon="-2.344214">
    <ageofdgpsdata>45</ageofdgpsdata>
    <cmt>Where I live</cmt>
    <desc>&#x3C;&#x3C;Chez moi&#x3E;&#x3E;</desc>
    <dgpsid>247</dgpsid>
    <ele>512</ele>
    <fix>dgps</fix>
    <geoidheight>0</geoidheight>
    <hdop>10</hdop>
    <url>http://hexten.net/</url>
    <urlname>Hexten</urlname>
    <magvar>0</magvar>
    <name>My house &#x26; home</name>
    <pdop>10</pdop>
    <sat>3</sat>
    <src>Testing</src>
    <sym>pin</sym>
    <time>2007-02-11T00:54:27+00:00</time>
    <type>unknown</type>
    <vdop>10</vdop>
  </wpt>
  <wpt lat="-38.870059" lon="-151.21003">
    <name>Sydney, AU</name>
  </wpt>
</gpx>
== 1.1 ==
<?xml version="1.0" encoding="utf-8"?>
<gpx xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" version="1.1" creator="Geo::Gpx" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd" xmlns="http://www.topografix.com/GPX/1/1">
  <metadata>
    <name>Test</name>
    <desc>Test data</desc>
    <author>
      <email domain="hexten.net" id="andy">
      </email>
      <link href="http://hexten.net/">
        <text>Hexten</text>
      </link>
      <name>Andy Armstrong</name>
    </author>
    <time>2007-02-11T00:54:27+00:00</time>
    <keywords>this, that, the other</keywords>
    <copyright>(c) Anyone</copyright>
    <link href="http://www.topografix.com/GPX">
      <text>GPX Spec</text>
      <type>unknown</type>
    </link>
    <bounds maxlat="54.884859" maxlon="-2.344214" minlat="-38.870059" minlon="-151.21003" />
  </metadata>
  <rte>
    <name>Route 1</name>
    <rtept lat="54.326829" lon="-2.755084">
      <name>WPT1</name>
    </rtept>
    <rtept lat="53.946949" lon="-2.408104">
      <name>WPT2</name>
    </rtept>
    <rtept lat="53.799799" lon="-2.902304">
      <name>WPT3</name>
    </rtept>
  </rte>
  <rte>
    <name>Route 2</name>
    <rtept lat="53.673339" lon="-3.062994">
      <name>WPT4</name>
    </rtept>
    <rtept lat="54.059119" lon="-2.777964">
      <name>WPT5</name>
    </rtept>
  </rte>
  <trk>
    <name>Track 1</name>
    <trkseg>
      <trkpt lat="54.255089" lon="-3.084644">
      </trkpt>
      <trkpt lat="54.523529" lon="-3.503144">
      </trkpt>
      <trkpt lat="54.494149" lon="-3.353574">
      </trkpt>
    </trkseg>
    <trkseg>
      <trkpt lat="53.994869" lon="-3.280864">
      </trkpt>
    </trkseg>
  </trk>
  <trk>
    <name>Track 2</name>
    <trkseg>
      <trkpt lat="54.228049" lon="-2.971004">
      </trkpt>
      <trkpt lat="54.689739" lon="-2.505334">
      </trkpt>
      <trkpt lat="54.715239" lon="-2.430574">
      </trkpt>
      <trkpt lat="54.433159" lon="-2.858704">
      </trkpt>
      <trkpt lat="54.884859" lon="-3.160504">
      </trkpt>
    </trkseg>
  </trk>
  <wpt lat="54.786989" lon="-2.344214">
    <ageofdgpsdata>45</ageofdgpsdata>
    <cmt>Where I live</cmt>
    <desc>&#x3C;&#x3C;Chez moi&#x3E;&#x3E;</desc>
    <dgpsid>247</dgpsid>
    <ele>512</ele>
    <fix>dgps</fix>
    <geoidheight>0</geoidheight>
    <hdop>10</hdop>
    <link href="http://hexten.net/">
      <text>Hexten</text>
      <type>Blah</type>
    </link>
    <magvar>0</magvar>
    <name>My house &#x26; home</name>
    <pdop>10</pdop>
    <sat>3</sat>
    <src>Testing</src>
    <sym>pin</sym>
    <time>2007-02-11T00:54:27+00:00</time>
    <type>unknown</type>
    <vdop>10</vdop>
  </wpt>
  <wpt lat="-38.870059" lon="-151.21003">
    <name>Sydney, AU</name>
  </wpt>
</gpx>
