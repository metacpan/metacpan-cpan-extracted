#!perl
# vim:ts=2:sw=2:et:ft=perl

use strict;
use warnings;

use Data::Dumper;
use DateTime;
use Geo::Gpx;
use Test::More tests => 5;

my $tm1 = DateTime->new(
  year      => 2009,
  month     => 5,
  day       => 5,
  hour      => 16,
  minute    => 12,
  second    => 47,
  time_zone => 'UTC'
);

my $tm2 = DateTime->new(
  year      => 2008,
  month     => 3,
  day       => 1,
  hour      => 9,
  minute    => 11,
  second    => 13,
  time_zone => 'EST'
);

my $source = do { local $/; <DATA> };

{
  my $gpx = Geo::Gpx->new;
  $gpx->add_waypoint(
    {
      lat  => 54.786989,
      lon  => -2.344214,
      time => $tm1,
    },
    {
      lat  => 39.98238,
      lon  => 12.91823,
      time => $tm2,
    },
    {
      lat  => 12.909038,
      lon  => 0.91823,
      time => $tm2->epoch,
    }
  );
  my @xtm    = xtm( $gpx->xml );
  my $expect = [
    '2009-05-05T16:12:47+00:00', '2008-03-01T09:11:13-05:00',
    '2008-03-01T14:11:13+00:00'
  ];

  unless ( is_deeply \@xtm, $expect, "times" ) {
    diag Dumper( \@xtm );
  }
}

{
  my @tm = parse( xml => $source );
  is_deeply \@tm, [ $tm2->epoch ], 'epoch';
}

{
  my @tm = parse( xml => $source, use_datetime => 1 );
  isa_ok $tm[0], 'DateTime';
  is $tm[0]->epoch,  $tm2->epoch,  'epoch';
  is $tm[0]->offset, $tm2->offset, 'offset';
}

sub parse {
  my @opts = @_;
  my $p    = Geo::Gpx->new( @opts );
  my $wpt  = $p->waypoints;
  return map { $_->{time} } @$wpt;
}

sub trim {
  my $str = shift;
  $str =~ s/^\s+//;
  $str =~ s/\s+$//;
  $str =~ s/\s+/ /g;
  return $str;
}

sub xtm {
  my $xml = shift;

  my @t = ();
  my $p = XML::Descent->new( { Input => \$xml } );

  $p->on(
    wpt => sub {
      my ( $elem, $attr, $ctx ) = @_;
      $p->on(
        time => sub {
          my ( $elem, $attr, $ctx ) = @_;
          push @t, trim( $p->text );
        }
      );
      $p->walk;
    }
  );
  $p->walk;

  return @t;
}

__DATA__
<?xml version="1.0" encoding="utf-8"?>
<gpx version="1.0">
  <name>Test</name>
  <wpt lat="54.786989" lon="-2.344214">
    <time>2008-03-01T09:11:13-05:00</time>
  </wpt>
</gpx>

