#!/usr/bin/perl -t

use 5.010;
use strict;
use warnings;
use utf8;
use autodie;

use Test::More;
use List::MoreUtils qw/ all /;

use Geo::Openstreetmap::Parser;

my %count;

my $osm = Geo::Openstreetmap::Parser->new(
    node => sub {
        $count{n}++;
        my $n = shift;
        ok( ref $n && ref $n->{attr} eq 'HASH', 'node attr' );
    },
    way => sub {
        my $w = shift;
        $count{w} ++;
        ok( ref $w && ref $w->{attr} eq 'HASH', 'way attr' );
        ok( ref $w->{nd} eq 'ARRAY', 'way nodes' );
        ok( ref $w->{tag} eq 'HASH', 'way tags' );
    },
    relation => sub {
        my $r = shift;
        $count{r} ++;
        ok( ref $r && ref $r->{attr} eq 'HASH', 'rel attr' );
        ok( ref $r->{member} eq 'ARRAY', 'rel members' );
        ok( (all { ref $_ eq 'HASH' } @{$r->{member}}), 'rel members format' );
        ok( ref $r->{tag} eq 'HASH', 'rel tags' );
    },
);

$osm->parse(*DATA);

is( $count{n}, 511, 'nodes count' );
is( $count{w}, 121, 'ways count' );
is( $count{r}, 1, 'relations count' );


done_testing();



__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<osm version="0.6" generator="OpenStreetMap server" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">
  <node id="1879301453" version="1" changeset="12832459" lat="50.0035819" lon="36.1839151" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:43Z"/>
  <node id="1879301532" version="1" changeset="12832459" lat="50.0036229" lon="36.18345" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:46Z"/>
  <node id="1879301535" version="1" changeset="12832459" lat="50.003626" lon="36.184089" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:46Z"/>
  <node id="1879301627" version="1" changeset="12832459" lat="50.0036699" lon="36.1835941" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:48Z"/>
  <node id="1879301727" version="1" changeset="12832459" lat="50.003726" lon="36.18337" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:51Z"/>
  <node id="1879301736" version="1" changeset="12832459" lat="50.0037399" lon="36.183819" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:51Z"/>
  <node id="1879301812" version="1" changeset="12832459" lat="50.003773" lon="36.1835131" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:54Z"/>
  <node id="1879301830" version="1" changeset="12832459" lat="50.0037849" lon="36.1839931" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:54Z"/>
  <node id="1879301873" version="1" changeset="12832459" lat="50.003805" lon="36.1842561" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:56Z"/>
  <node id="1879301950" version="1" changeset="12832459" lat="50.003834" lon="36.184387" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:56:58Z"/>
  <node id="1879302022" version="1" changeset="12832459" lat="50.003864" lon="36.1837481" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:00Z"/>
  <node id="1879302031" version="1" changeset="12832459" lat="50.003866" lon="36.184082" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:00Z"/>
  <node id="1879302072" version="1" changeset="12832459" lat="50.003887" lon="36.1841841" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:01Z"/>
  <node id="1879302094" version="1" changeset="12832459" lat="50.003892" lon="36.183881" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:01Z"/>
  <node id="1879302098" version="1" changeset="12832459" lat="50.003893" lon="36.184212" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:02Z"/>
  <node id="1879302147" version="1" changeset="12832459" lat="50.003922" lon="36.1843441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:04Z"/>
  <node id="1879302153" version="1" changeset="12832459" lat="50.0039269" lon="36.1837141" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:04Z"/>
  <node id="1879302156" version="1" changeset="12832459" lat="50.003928" lon="36.183305" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:04Z"/>
  <node id="1879302213" version="1" changeset="12832459" lat="50.003953" lon="36.18341" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:06Z"/>
  <node id="1879302230" version="1" changeset="12832459" lat="50.003954" lon="36.184038" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:07Z"/>
  <node id="1879302238" version="1" changeset="12832459" lat="50.003956" lon="36.183847" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:07Z"/>
  <node id="1879302248" version="1" changeset="12832459" lat="50.003961" lon="36.183286" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:07Z"/>
  <node id="1879302283" version="1" changeset="12832459" lat="50.003975" lon="36.18414" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:08Z"/>
  <node id="1879302301" version="1" changeset="12832459" lat="50.0039859" lon="36.18339" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:08Z"/>
  <node id="1879302332" version="1" changeset="12832459" lat="50.0040009" lon="36.1830981" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:10Z"/>
  <node id="1879302383" version="1" changeset="12832459" lat="50.0040249" lon="36.183683" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:11Z"/>
  <node id="1879302437" version="1" changeset="12832459" lat="50.0040469" lon="36.1837831" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:13Z"/>
  <node id="1879302442" version="1" changeset="12832459" lat="50.0040499" lon="36.1833061" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:13Z"/>
  <node id="1879302500" version="1" changeset="12832459" lat="50.0040719" lon="36.1830631" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:14Z"/>
  <node id="1879302588" version="1" changeset="12832459" lat="50.004113" lon="36.183739" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:17Z"/>
  <node id="1879302606" version="1" changeset="12832459" lat="50.0041209" lon="36.1832711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:18Z"/>
  <node id="1879302649" version="1" changeset="12832459" lat="50.004136" lon="36.1838421" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:20Z"/>
  <node id="1879302697" version="1" changeset="12832459" lat="50.004154" lon="36.183609" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:21Z"/>
  <node id="1879302874" version="1" changeset="12832459" lat="50.0042039" lon="36.183807" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:26Z"/>
  <node id="1879303062" version="1" changeset="12832459" lat="50.00427" lon="36.1835479" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:32Z"/>
  <node id="1879303130" version="1" changeset="12832459" lat="50.0042979" lon="36.183655" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:34Z"/>
  <node id="1879303275" version="1" changeset="12832459" lat="50.004341" lon="36.1835021" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:37Z"/>
  <node id="1879303280" version="1" changeset="12832459" lat="50.004344" lon="36.1835001" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:38Z"/>
  <node id="1879303421" version="1" changeset="12832459" lat="50.004371" lon="36.1836069" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:40Z"/>
  <node id="1879303584" version="1" changeset="12832459" lat="50.004416" lon="36.183449" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:44Z"/>
  <node id="1879303605" version="1" changeset="12832459" lat="50.0044269" lon="36.18298" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:45Z"/>
  <node id="1879303656" version="1" changeset="12832459" lat="50.0044459" lon="36.1835781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:47Z"/>
  <node id="1879303684" version="1" changeset="12832459" lat="50.0044559" lon="36.1831111" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:48Z"/>
  <node id="1879303814" version="1" changeset="12832459" lat="50.0045149" lon="36.1829351" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:53Z"/>
  <node id="1879303851" version="1" changeset="12832459" lat="50.0045229" lon="36.1833841" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:54Z"/>
  <node id="1879303896" version="1" changeset="12832459" lat="50.004542" lon="36.183061" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:56Z"/>
  <node id="1879303913" version="1" changeset="12832459" lat="50.0045529" lon="36.183513" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:57:56Z"/>
  <node id="1879304159" version="1" changeset="12832459" lat="50.0046599" lon="36.183314" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:03Z"/>
  <node id="1879304260" version="1" changeset="12832459" lat="50.0047" lon="36.183473" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:06Z"/>
  <node id="1879304301" version="1" changeset="12832459" lat="50.004712" lon="36.183282" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:06Z"/>
  <node id="1879304460" version="1" changeset="12832459" lat="50.004752" lon="36.183441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:09Z"/>
  <node id="1879304960" version="1" changeset="12832459" lat="50.0048819" lon="36.183196" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:18Z"/>
  <node id="1879305071" version="1" changeset="12832459" lat="50.0049169" lon="36.183333" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:21Z"/>
  <node id="1879305172" version="1" changeset="12832459" lat="50.0049759" lon="36.183132" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:24Z"/>
  <node id="1879305216" version="1" changeset="12832459" lat="50.005011" lon="36.1832701" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:26Z"/>
  <node id="1879305328" version="1" changeset="12832459" lat="50.0050819" lon="36.183081" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:30Z"/>
  <node id="1879305330" version="1" changeset="12832459" lat="50.0050829" lon="36.1825771" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:30Z"/>
  <node id="1879305382" version="1" changeset="12832459" lat="50.00511" lon="36.1831941" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:32Z"/>
  <node id="1879305385" version="1" changeset="12832459" lat="50.0051139" lon="36.1826991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:32Z"/>
  <node id="1879305420" version="1" changeset="12832459" lat="50.0051379" lon="36.1823171" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:33Z"/>
  <node id="1879305436" version="1" changeset="12832459" lat="50.005144" lon="36.183044" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:34Z"/>
  <node id="1879305461" version="1" changeset="12832459" lat="50.0051589" lon="36.1824151" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:35Z"/>
  <node id="1879305467" version="1" changeset="12832459" lat="50.0051719" lon="36.1831571" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:35Z"/>
  <node id="1879305468" version="1" changeset="12832459" lat="50.005176" lon="36.182525" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:35Z"/>
  <node id="1879305474" version="1" changeset="12832459" lat="50.0051799" lon="36.1829861" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:35Z"/>
  <node id="1879305519" version="1" changeset="12832459" lat="50.005207" lon="36.182648" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:37Z"/>
  <node id="1879305544" version="1" changeset="12832459" lat="50.005222" lon="36.18315" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:38Z"/>
  <node id="1879305545" version="1" changeset="12832459" lat="50.005227" lon="36.182273" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:38Z"/>
  <node id="1879305589" version="1" changeset="12832459" lat="50.005248" lon="36.1823699" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:40Z"/>
  <node id="1879305596" version="1" changeset="12832459" lat="50.005258" lon="36.1824721" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:40Z"/>
  <node id="1879305600" version="1" changeset="12832459" lat="50.005264" lon="36.182935" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:40Z"/>
  <node id="1879305636" version="1" changeset="12832459" lat="50.0052869" lon="36.1826121" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:41Z"/>
  <node id="1879305662" version="1" changeset="12832459" lat="50.0053059" lon="36.1830991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:43Z"/>
  <node id="1879305675" version="1" changeset="12832459" lat="50.0053179" lon="36.1824421" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:43Z"/>
  <node id="1879305680" version="1" changeset="12832459" lat="50.0053259" lon="36.182815" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:43Z"/>
  <node id="1879305714" version="1" changeset="12832459" lat="50.0053469" lon="36.182582" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:44Z"/>
  <node id="1879305716" version="1" changeset="12832459" lat="50.0053479" lon="36.182902" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:44Z"/>
  <node id="1879305801" version="1" changeset="12832459" lat="50.0053889" lon="36.1827781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:47Z"/>
  <node id="1879305844" version="1" changeset="12832459" lat="50.0054109" lon="36.182864" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:49Z"/>
  <node id="1879305963" version="1" changeset="12832459" lat="50.0054869" lon="36.182877" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:52Z"/>
  <node id="1879305988" version="1" changeset="12832459" lat="50.0055099" lon="36.1829721" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:54Z"/>
  <node id="1879306194" version="1" changeset="12832459" lat="50.005635" lon="36.1827941" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:58:59Z"/>
  <node id="1879306223" version="1" changeset="12832459" lat="50.005657" lon="36.182889" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:01Z"/>
  <node id="1879306402" version="1" changeset="12832459" lat="50.005788" lon="36.1827819" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:07Z"/>
  <node id="1879306472" version="1" changeset="12832459" lat="50.0058389" lon="36.1829619" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:10Z"/>
  <node id="1879306495" version="1" changeset="12832459" lat="50.0058709" lon="36.182732" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:10Z"/>
  <node id="1879306540" version="1" changeset="12832459" lat="50.0058919" lon="36.182514" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:12Z"/>
  <node id="1879306588" version="1" changeset="12832459" lat="50.005919" lon="36.182621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:13Z"/>
  <node id="1879306595" version="1" changeset="12832459" lat="50.0059219" lon="36.182912" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:13Z"/>
  <node id="1879306664" version="1" changeset="12832459" lat="50.005975" lon="36.1824641" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:16Z"/>
  <node id="1879306704" version="1" changeset="12832459" lat="50.006002" lon="36.1825711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:18Z"/>
  <node id="1879306710" version="1" changeset="12832459" lat="50.006011" lon="36.182446" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:18Z"/>
  <node id="1879306785" version="1" changeset="12832459" lat="50.0060359" lon="36.182555" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:19Z"/>
  <node id="1879306917" version="1" changeset="12832459" lat="50.006143" lon="36.1823751" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:24Z"/>
  <node id="1879306966" version="1" changeset="12832459" lat="50.0061669" lon="36.1824841" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:26Z"/>
  <node id="1879307092" version="1" changeset="12832459" lat="50.0062539" lon="36.1823301" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:30Z"/>
  <node id="1879307125" version="1" changeset="12832459" lat="50.0062899" lon="36.1824441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:32Z"/>
  <node id="1879307186" version="1" changeset="12832459" lat="50.0063539" lon="36.182255" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:34Z"/>
  <node id="1879307223" version="1" changeset="12832459" lat="50.0063889" lon="36.1823691" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:35Z"/>
  <node id="1879307288" version="1" changeset="12832459" lat="50.0064329" lon="36.182429" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:38Z"/>
  <node id="1879307328" version="1" changeset="12832459" lat="50.006464" lon="36.1825291" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:40Z"/>
  <node id="1879307377" version="1" changeset="12832459" lat="50.006502" lon="36.1823731" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:41Z"/>
  <node id="1879307426" version="1" changeset="12832459" lat="50.006533" lon="36.182473" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:43Z"/>
  <node id="1879307429" version="1" changeset="12832459" lat="50.006535" lon="36.182168" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:43Z"/>
  <node id="1879307459" version="1" changeset="12832459" lat="50.0065569" lon="36.1822571" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:45Z"/>
  <node id="1879307499" version="1" changeset="12832459" lat="50.0066199" lon="36.1821172" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:47Z"/>
  <node id="1879307508" version="1" changeset="12832459" lat="50.0066419" lon="36.182206" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:48Z"/>
  <node id="1879307568" version="1" changeset="12832459" lat="50.0067509" lon="36.182037" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:52Z"/>
  <node id="1879307601" version="1" changeset="12832459" lat="50.006778" lon="36.182146" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:53Z"/>
  <node id="1879307646" version="1" changeset="12832459" lat="50.006853" lon="36.181968" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:57Z"/>
  <node id="1879307663" version="1" changeset="12832459" lat="50.00688" lon="36.1820781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T12:59:58Z"/>
  <node id="1879307748" version="1" changeset="12832459" lat="50.0069509" lon="36.1819081" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:01Z"/>
  <node id="1879307858" version="1" changeset="12832459" lat="50.006981" lon="36.1820401" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:03Z"/>
  <node id="1879308027" version="1" changeset="12832459" lat="50.0070509" lon="36.1818541" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:06Z"/>
  <node id="1879308077" version="1" changeset="12832459" lat="50.0070809" lon="36.1819851" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:08Z"/>
  <node id="1879308223" version="1" changeset="12832459" lat="50.0071869" lon="36.181771" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:12Z"/>
  <node id="1879308292" version="1" changeset="12832459" lat="50.0072289" lon="36.181953" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:14Z"/>
  <node id="1879308372" version="1" changeset="12832459" lat="50.007262" lon="36.181725" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:15Z"/>
  <node id="1879308454" version="1" changeset="12832459" lat="50.0073039" lon="36.181908" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:18Z"/>
  <node id="1879308624" version="1" changeset="12832459" lat="50.0075719" lon="36.181545" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:30Z"/>
  <node id="1879308648" version="1" changeset="12832459" lat="50.007605" lon="36.181679" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:32Z"/>
  <node id="1879308705" version="1" changeset="12832459" lat="50.0076809" lon="36.181473" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:36Z"/>
  <node id="1879308738" version="1" changeset="12832459" lat="50.0077139" lon="36.181607" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:38Z"/>
  <node id="1879309005" version="1" changeset="12832459" lat="50.007836" lon="36.18093" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:45Z"/>
  <node id="1879309145" version="1" changeset="12832459" lat="50.007873" lon="36.1810491" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:47Z"/>
  <node id="1879309260" version="1" changeset="12832459" lat="50.007902" lon="36.1813501" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:49Z"/>
  <node id="1879309283" version="1" changeset="12832459" lat="50.0079129" lon="36.180872" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:49Z"/>
  <node id="1879309359" version="1" changeset="12832459" lat="50.00795" lon="36.180991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:51Z"/>
  <node id="1879309371" version="1" changeset="12832459" lat="50.0079559" lon="36.181628" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:52Z"/>
  <node id="1879309396" version="1" changeset="12832459" lat="50.0079729" lon="36.181319" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:53Z"/>
  <node id="1879309435" version="1" changeset="12832459" lat="50.0079949" lon="36.1812831" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:54Z"/>
  <node id="1879309475" version="1" changeset="12832459" lat="50.0080269" lon="36.1815971" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:56Z"/>
  <node id="1879309485" version="1" changeset="12832459" lat="50.0080389" lon="36.1814561" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:56Z"/>
  <node id="1879309509" version="1" changeset="12832459" lat="50.0080799" lon="36.1812311" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:00:58Z"/>
  <node id="1879309530" version="1" changeset="12832459" lat="50.008124" lon="36.1814031" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:00Z"/>
  <node id="1879309764" version="1" changeset="12832459" lat="50.0083599" lon="36.180462" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:10Z"/>
  <node id="1879309797" version="1" changeset="12832459" lat="50.008396" lon="36.180576" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:12Z"/>
  <node id="1879309923" version="1" changeset="12832459" lat="50.0085249" lon="36.180338" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:17Z"/>
  <node id="1879309949" version="1" changeset="12832459" lat="50.008561" lon="36.1804521" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:19Z"/>
  <node id="1879310709" version="1" changeset="12832459" lat="50.009191" lon="36.1801021" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:44Z"/>
  <node id="1879310723" version="1" changeset="12832459" lat="50.0092149" lon="36.1802021" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:45Z"/>
  <node id="1879310783" version="1" changeset="12832459" lat="50.0093209" lon="36.18003" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:49Z"/>
  <node id="1879310796" version="1" changeset="12832459" lat="50.0093439" lon="36.1801301" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:50Z"/>
  <node id="1879310844" version="1" changeset="12832459" lat="50.0094409" lon="36.179947" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:54Z"/>
  <node id="1879310862" version="1" changeset="12832459" lat="50.0094749" lon="36.180066" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:01:56Z"/>
  <node id="1879310932" version="1" changeset="12832459" lat="50.009607" lon="36.179834" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:00Z"/>
  <node id="1879310946" version="1" changeset="12832459" lat="50.0096409" lon="36.179952" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:01Z"/>
  <node id="1879311065" version="1" changeset="12832459" lat="50.0097439" lon="36.179756" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:04Z"/>
  <node id="1879311119" version="1" changeset="12832459" lat="50.0097759" lon="36.179884" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:06Z"/>
  <node id="1879311254" version="1" changeset="12832459" lat="50.0099469" lon="36.179633" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:11Z"/>
  <node id="1879311269" version="1" changeset="12832459" lat="50.0099789" lon="36.1797611" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:13Z"/>
  <node id="1879311747" version="1" changeset="12832459" lat="50.0103909" lon="36.179327" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:29Z"/>
  <node id="1879311808" version="1" changeset="12832459" lat="50.010413" lon="36.1794351" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:30Z"/>
  <node id="1879311989" version="1" changeset="12832459" lat="50.01049" lon="36.17928" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:33Z"/>
  <node id="1879312009" version="1" changeset="12832459" lat="50.0105139" lon="36.179386" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:02:34Z"/>
  <node id="1879313772" version="1" changeset="12832459" lat="50.0115709" lon="36.1770469" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:04Z"/>
  <node id="1879313775" version="1" changeset="12832459" lat="50.0115719" lon="36.177151" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:04Z"/>
  <node id="1879313886" version="1" changeset="12832459" lat="50.011667" lon="36.177046" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:06Z"/>
  <node id="1879313888" version="1" changeset="12832459" lat="50.011667" lon="36.17715" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:06Z"/>
  <node id="1879313994" version="1" changeset="12832459" lat="50.0117989" lon="36.177172" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:08Z"/>
  <node id="1879313995" version="1" changeset="12832459" lat="50.0117999" lon="36.1770741" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:08Z"/>
  <node id="1879314087" version="1" changeset="12832459" lat="50.0118849" lon="36.1771761" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:09Z"/>
  <node id="1879314088" version="1" changeset="12832459" lat="50.0118869" lon="36.1770781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:09Z"/>
  <node id="1879314182" version="1" changeset="12832459" lat="50.0119689" lon="36.1770991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:11Z"/>
  <node id="1879314184" version="1" changeset="12832459" lat="50.011971" lon="36.1769611" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:11Z"/>
  <node id="1879314225" version="1" changeset="12832459" lat="50.0120369" lon="36.1771021" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:12Z"/>
  <node id="1879314229" version="1" changeset="12832459" lat="50.0120389" lon="36.1769641" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:12Z"/>
  <node id="1879314298" version="1" changeset="12832459" lat="50.012113" lon="36.1771109" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:13Z"/>
  <node id="1879314303" version="1" changeset="12832459" lat="50.0121149" lon="36.1769961" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:13Z"/>
  <node id="1879314348" version="1" changeset="12832459" lat="50.0122099" lon="36.1771151" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:15Z"/>
  <node id="1879314351" version="1" changeset="12832459" lat="50.012212" lon="36.1770001" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:15Z"/>
  <node id="1879314365" version="1" changeset="12832459" lat="50.0122859" lon="36.177115" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:15Z"/>
  <node id="1879314367" version="1" changeset="12832459" lat="50.0122879" lon="36.176978" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:15Z"/>
  <node id="1879314407" version="1" changeset="12832459" lat="50.0123759" lon="36.1771211" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314409" version="1" changeset="12832459" lat="50.0123789" lon="36.1769841" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314411" version="1" changeset="12832459" lat="50.0123939" lon="36.177334" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314416" version="1" changeset="12832459" lat="50.012416" lon="36.1774631" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314426" version="1" changeset="12832459" lat="50.012454" lon="36.177309" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314428" version="1" changeset="12832459" lat="50.0124559" lon="36.177112" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314431" version="1" changeset="12832459" lat="50.012458" lon="36.1769751" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:17Z"/>
  <node id="1879314462" version="1" changeset="12832459" lat="50.0124759" lon="36.1774391" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:18Z"/>
  <node id="1879314469" version="1" changeset="12832459" lat="50.012514" lon="36.1774391" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314472" version="1" changeset="12832459" lat="50.012518" lon="36.1773031" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314474" version="1" changeset="12832459" lat="50.012524" lon="36.177115" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314477" version="1" changeset="12832459" lat="50.0125259" lon="36.1769771" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314490" version="1" changeset="12832459" lat="50.0125689" lon="36.17711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314493" version="1" changeset="12832459" lat="50.012571" lon="36.1769731" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:19Z"/>
  <node id="1879314521" version="1" changeset="12832459" lat="50.012587" lon="36.1774441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314522" version="1" changeset="12832459" lat="50.0125909" lon="36.1773081" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314525" version="1" changeset="12832459" lat="50.0126369" lon="36.177113" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314528" version="1" changeset="12832459" lat="50.012639" lon="36.1769761" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314533" version="1" changeset="12832459" lat="50.012655" lon="36.177377" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314535" version="1" changeset="12832459" lat="50.012657" lon="36.177312" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:20Z"/>
  <node id="1879314549" version="1" changeset="12832459" lat="50.0127209" lon="36.1771121" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:21Z"/>
  <node id="1879314552" version="1" changeset="12832459" lat="50.0127229" lon="36.1769741" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:21Z"/>
  <node id="1879314557" version="1" changeset="12832459" lat="50.0127509" lon="36.177384" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:21Z"/>
  <node id="1879314558" version="1" changeset="12832459" lat="50.012753" lon="36.177315" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:21Z"/>
  <node id="1879314559" version="1" changeset="12832459" lat="50.0127889" lon="36.1771151" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:21Z"/>
  <node id="1879314584" version="1" changeset="12832459" lat="50.012792" lon="36.176977" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314597" version="1" changeset="12832459" lat="50.0128449" lon="36.177397" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314600" version="1" changeset="12832459" lat="50.0128479" lon="36.1773031" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314608" version="1" changeset="12832459" lat="50.0128859" lon="36.1770931" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314610" version="1" changeset="12832459" lat="50.0128899" lon="36.1769661" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314615" version="1" changeset="12832459" lat="50.012937" lon="36.1774031" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314616" version="1" changeset="12832459" lat="50.0129399" lon="36.1773091" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314617" version="1" changeset="12832459" lat="50.012977" lon="36.177101" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314618" version="1" changeset="12832459" lat="50.012982" lon="36.1769741" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:22Z"/>
  <node id="1879314620" version="1" changeset="12832459" lat="50.013001" lon="36.1774442" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:23Z"/>
  <node id="1879314642" version="1" changeset="12832459" lat="50.0130039" lon="36.177337" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:23Z"/>
  <node id="1879314647" version="1" changeset="12832459" lat="50.0130669" lon="36.1771131" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314650" version="1" changeset="12832459" lat="50.01307" lon="36.1769761" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314653" version="1" changeset="12832459" lat="50.013091" lon="36.17745" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314655" version="1" changeset="12832459" lat="50.013094" lon="36.1773441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314658" version="1" changeset="12832459" lat="50.0131259" lon="36.1774751" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314662" version="1" changeset="12832459" lat="50.0131279" lon="36.177338" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314663" version="1" changeset="12832459" lat="50.0131349" lon="36.1771161" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314664" version="1" changeset="12832459" lat="50.0131379" lon="36.1769791" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314672" version="1" changeset="12832459" lat="50.0132359" lon="36.17747" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314673" version="1" changeset="12832459" lat="50.0132399" lon="36.1773481" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:24Z"/>
  <node id="1879314679" version="1" changeset="12832459" lat="50.0132519" lon="36.177148" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:26Z"/>
  <node id="1879314681" version="1" changeset="12832459" lat="50.013255" lon="36.17701" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:26Z"/>
  <node id="1879314695" version="1" changeset="12832459" lat="50.0133209" lon="36.1771511" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:26Z"/>
  <node id="1879314698" version="1" changeset="12832459" lat="50.013323" lon="36.177013" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:26Z"/>
  <node id="1879314735" version="1" changeset="12832459" lat="50.0133419" lon="36.17753" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:26Z"/>
  <node id="1879314736" version="1" changeset="12832459" lat="50.0133469" lon="36.1773481" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:27Z"/>
  <node id="1879314739" version="1" changeset="12832459" lat="50.0133539" lon="36.1778381" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:27Z"/>
  <node id="1879314742" version="1" changeset="12832459" lat="50.0133569" lon="36.177729" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:27Z"/>
  <node id="1879314758" version="1" changeset="12832459" lat="50.0134039" lon="36.1771571" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:28Z"/>
  <node id="1879314759" version="1" changeset="12832459" lat="50.013407" lon="36.17702" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:28Z"/>
  <node id="1879314762" version="1" changeset="12832459" lat="50.0134119" lon="36.177535" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:28Z"/>
  <node id="1879314764" version="1" changeset="12832459" lat="50.013417" lon="36.177353" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:28Z"/>
  <node id="1879314813" version="1" changeset="12832459" lat="50.013452" lon="36.177845" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314819" version="1" changeset="12832459" lat="50.013455" lon="36.177736" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314830" version="1" changeset="12832459" lat="50.013473" lon="36.17716" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314831" version="1" changeset="12832459" lat="50.013475" lon="36.1770231" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314838" version="1" changeset="12832459" lat="50.013482" lon="36.1775399" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314840" version="1" changeset="12832459" lat="50.013487" lon="36.177358" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:29Z"/>
  <node id="1879314855" version="1" changeset="12832459" lat="50.0135609" lon="36.17748" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:30Z"/>
  <node id="1879314857" version="1" changeset="12832459" lat="50.0135649" lon="36.1773441" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:30Z"/>
  <node id="1879314922" version="1" changeset="12832459" lat="50.0136289" lon="36.1774851" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:31Z"/>
  <node id="1879314924" version="1" changeset="12832459" lat="50.013633" lon="36.177349" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:31Z"/>
  <node id="1879314967" version="1" changeset="12832459" lat="50.0137339" lon="36.176844" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:33Z"/>
  <node id="1879314973" version="1" changeset="12832459" lat="50.013752" lon="36.1767281" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:33Z"/>
  <node id="1879314989" version="1" changeset="12832459" lat="50.013825" lon="36.1768781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:33Z"/>
  <node id="1879314996" version="1" changeset="12832459" lat="50.0138429" lon="36.1767621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:33Z"/>
  <node id="1879315037" version="1" changeset="12832459" lat="50.0138879" lon="36.1774621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315039" version="1" changeset="12832459" lat="50.013888" lon="36.1775621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315047" version="1" changeset="12832459" lat="50.013898" lon="36.177105" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315052" version="1" changeset="12832459" lat="50.013922" lon="36.1769521" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315069" version="1" changeset="12832459" lat="50.013965" lon="36.177131" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315070" version="1" changeset="12832459" lat="50.01398" lon="36.177462" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315071" version="1" changeset="12832459" lat="50.01398" lon="36.177562" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:35Z"/>
  <node id="1879315089" version="1" changeset="12832459" lat="50.0139889" lon="36.1769771" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:37Z"/>
  <node id="1879315091" version="1" changeset="12832459" lat="50.0140009" lon="36.177193" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:37Z"/>
  <node id="1879315095" version="1" changeset="12832459" lat="50.0140229" lon="36.1769631" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:37Z"/>
  <node id="1879315100" version="1" changeset="12832459" lat="50.0140519" lon="36.17742" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:37Z"/>
  <node id="1879315101" version="1" changeset="12832459" lat="50.0140539" lon="36.1775521" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:37Z"/>
  <node id="1879315140" version="1" changeset="12832459" lat="50.0140969" lon="36.1772081" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:39Z"/>
  <node id="1879315152" version="1" changeset="12832459" lat="50.0141189" lon="36.1769781" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:39Z"/>
  <node id="1879315158" version="1" changeset="12832459" lat="50.014153" lon="36.1774171" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:39Z"/>
  <node id="1879315160" version="1" changeset="12832459" lat="50.0141539" lon="36.1775491" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:39Z"/>
  <node id="1879315209" version="1" changeset="12832459" lat="50.0142039" lon="36.1770271" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:40Z"/>
  <node id="1879315213" version="1" changeset="12832459" lat="50.014216" lon="36.1768972" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:40Z"/>
  <node id="1879315236" version="1" changeset="12832459" lat="50.0142759" lon="36.177043" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:41Z"/>
  <node id="1879315243" version="1" changeset="12832459" lat="50.0142879" lon="36.176913" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:41Z"/>
  <node id="1879315339" version="1" changeset="12832459" lat="50.0145009" lon="36.176996" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:45Z"/>
  <node id="1879315383" version="1" changeset="12832459" lat="50.0145319" lon="36.1768651" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:46Z"/>
  <node id="1879315399" version="1" changeset="12832459" lat="50.0145629" lon="36.1766981" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:47Z"/>
  <node id="1879315402" version="1" changeset="12832459" lat="50.0145639" lon="36.1770381" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:47Z"/>
  <node id="1879315409" version="1" changeset="12832459" lat="50.0146019" lon="36.176914" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:47Z"/>
  <node id="1879315412" version="1" changeset="12832459" lat="50.014623" lon="36.1765181" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:47Z"/>
  <node id="1879315429" version="1" changeset="12832459" lat="50.0146709" lon="36.1767841" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:48Z"/>
  <node id="1879315434" version="1" changeset="12832459" lat="50.014731" lon="36.1766161" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:48Z"/>
  <node id="1879315440" version="1" changeset="12832459" lat="50.0147929" lon="36.176387" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:49Z"/>
  <node id="1879315478" version="1" changeset="12832459" lat="50.014835" lon="36.176317" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:50Z"/>
  <node id="1879315487" version="1" changeset="12832459" lat="50.0148619" lon="36.1764881" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:50Z"/>
  <node id="1879315504" version="1" changeset="12832459" lat="50.0149039" lon="36.176418" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:50Z"/>
  <node id="1879315565" version="1" changeset="12832459" lat="50.0150179" lon="36.176057" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:52Z"/>
  <node id="1879315581" version="1" changeset="12832459" lat="50.015059" lon="36.176129" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:52Z"/>
  <node id="1879315593" version="1" changeset="12832459" lat="50.0151159" lon="36.175922" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:54Z"/>
  <node id="1879315609" version="1" changeset="12832459" lat="50.015157" lon="36.175994" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:54Z"/>
  <node id="1879315681" version="1" changeset="12832459" lat="50.015214" lon="36.1756051" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:56Z"/>
  <node id="1879315807" version="1" changeset="12832459" lat="50.015281" lon="36.175723" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:58Z"/>
  <node id="1879315809" version="1" changeset="12832459" lat="50.0152899" lon="36.175496" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:58Z"/>
  <node id="1879315855" version="1" changeset="12832459" lat="50.015358" lon="36.1756141" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:03:58Z"/>
  <node id="1879315941" version="1" changeset="12832459" lat="50.0154059" lon="36.1753711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:00Z"/>
  <node id="1879315967" version="1" changeset="12832459" lat="50.0154509" lon="36.175449" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:00Z"/>
  <node id="1879315971" version="1" changeset="12832459" lat="50.0154669" lon="36.1752891" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:00Z"/>
  <node id="1879316070" version="1" changeset="12832459" lat="50.0154829" lon="36.1751749" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:01Z"/>
  <node id="1879316086" version="1" changeset="12832459" lat="50.015506" lon="36.1752871" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:01Z"/>
  <node id="1879316095" version="1" changeset="12832459" lat="50.015511" lon="36.1753671" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:01Z"/>
  <node id="1879316120" version="1" changeset="12832459" lat="50.015528" lon="36.1752561" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:02Z"/>
  <node id="1879316127" version="1" changeset="12832459" lat="50.0155319" lon="36.1751071" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:02Z"/>
  <node id="1879316137" version="1" changeset="12832459" lat="50.0155489" lon="36.175363" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:02Z"/>
  <node id="1879316307" version="1" changeset="12832459" lat="50.0156209" lon="36.175264" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:03Z"/>
  <node id="1879316314" version="1" changeset="12832459" lat="50.0156309" lon="36.1751281" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:04Z"/>
  <node id="1879316429" version="1" changeset="12832459" lat="50.015686" lon="36.175224" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:05Z"/>
  <node id="1879316434" version="1" changeset="12832459" lat="50.015691" lon="36.175046" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:05Z"/>
  <node id="1879316467" version="1" changeset="12832459" lat="50.0157459" lon="36.1751421" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:06Z"/>
  <node id="1879316474" version="1" changeset="12832459" lat="50.0157559" lon="36.1749679" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:06Z"/>
  <node id="1879316554" version="1" changeset="12832459" lat="50.0157999" lon="36.175046" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:07Z"/>
  <node id="1879316561" version="1" changeset="12832459" lat="50.0158209" lon="36.174879" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:07Z"/>
  <node id="1879316589" version="1" changeset="12832459" lat="50.0158649" lon="36.1749569" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:07Z"/>
  <node id="1879316599" version="1" changeset="12832459" lat="50.0158889" lon="36.174728" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:07Z"/>
  <node id="1879316687" version="1" changeset="12832459" lat="50.01594" lon="36.1748191" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:09Z"/>
  <node id="1879316691" version="1" changeset="12832459" lat="50.015943" lon="36.174654" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:09Z"/>
  <node id="1879316723" version="1" changeset="12832459" lat="50.0159939" lon="36.1747451" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:09Z"/>
  <node id="1879316727" version="1" changeset="12832459" lat="50.015997" lon="36.174666" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:09Z"/>
  <node id="1879316753" version="1" changeset="12832459" lat="50.0160399" lon="36.1747431" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:09Z"/>
  <node id="1879316813" version="1" changeset="12832459" lat="50.016066" lon="36.174574" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316823" version="1" changeset="12832459" lat="50.016103" lon="36.174462" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316826" version="1" changeset="12832459" lat="50.0161089" lon="36.1746511" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316830" version="1" changeset="12832459" lat="50.0161539" lon="36.1745421" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316832" version="1" changeset="12832459" lat="50.0161819" lon="36.1743339" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316837" version="1" changeset="12832459" lat="50.0162329" lon="36.174415" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:11Z"/>
  <node id="1879316860" version="1" changeset="12832459" lat="50.0163009" lon="36.174219" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:13Z"/>
  <node id="1879316874" version="1" changeset="12832459" lat="50.0163509" lon="36.174306" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:13Z"/>
  <node id="1879316879" version="1" changeset="12832459" lat="50.016354" lon="36.1741479" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:13Z"/>
  <node id="1879316882" version="1" changeset="12832459" lat="50.0163659" lon="36.1741001" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:13Z"/>
  <node id="1879316890" version="1" changeset="12832459" lat="50.016403" lon="36.174235" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:13Z"/>
  <node id="1879316922" version="1" changeset="12832459" lat="50.0164119" lon="36.174182" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:14Z"/>
  <node id="1879316934" version="1" changeset="12832459" lat="50.0164339" lon="36.174007" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:14Z"/>
  <node id="1879316943" version="1" changeset="12832459" lat="50.01648" lon="36.1740881" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:15Z"/>
  <node id="1879316962" version="1" changeset="12832459" lat="50.0165359" lon="36.173878" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:15Z"/>
  <node id="1879317013" version="1" changeset="12832459" lat="50.0165919" lon="36.1737861" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:16Z"/>
  <node id="1879317016" version="1" changeset="12832459" lat="50.0166039" lon="36.1739691" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:16Z"/>
  <node id="1879317019" version="1" changeset="12832459" lat="50.0166599" lon="36.173877" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:16Z"/>
  <node id="1879317027" version="1" changeset="12832459" lat="50.016791" lon="36.1734121" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:17Z"/>
  <node id="1879317043" version="1" changeset="12832459" lat="50.016842" lon="36.1733351" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:18Z"/>
  <node id="1879317048" version="1" changeset="12832459" lat="50.016861" lon="36.173524" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:18Z"/>
  <node id="1879317063" version="1" changeset="12832459" lat="50.016912" lon="36.1734471" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:18Z"/>
  <node id="1879317077" version="1" changeset="12832459" lat="50.0170959" lon="36.173101" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:19Z"/>
  <node id="1879317112" version="1" changeset="12832459" lat="50.0171559" lon="36.173202" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317117" version="1" changeset="12832459" lat="50.0172029" lon="36.173488" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317120" version="1" changeset="12832459" lat="50.0172039" lon="36.173657" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317122" version="1" changeset="12832459" lat="50.0172179" lon="36.172926" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317124" version="1" changeset="12832459" lat="50.017278" lon="36.1730271" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317126" version="1" changeset="12832459" lat="50.0172949" lon="36.1734931" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317127" version="1" changeset="12832459" lat="50.017296" lon="36.1736621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317128" version="1" changeset="12832459" lat="50.017402" lon="36.1731551" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317129" version="1" changeset="12832459" lat="50.017402" lon="36.17327" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317130" version="1" changeset="12832459" lat="50.017442" lon="36.173688" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317131" version="1" changeset="12832459" lat="50.017443" lon="36.173804" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317132" version="1" changeset="12832459" lat="50.0174909" lon="36.173271" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317133" version="1" changeset="12832459" lat="50.0174919" lon="36.1731561" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317135" version="1" changeset="12832459" lat="50.0175469" lon="36.173687" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317138" version="1" changeset="12832459" lat="50.0175479" lon="36.173803" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317140" version="1" changeset="12832459" lat="50.0175619" lon="36.173279" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317143" version="1" changeset="12832459" lat="50.0175629" lon="36.1731751" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317145" version="1" changeset="12832459" lat="50.0176059" lon="36.1737041" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:20Z"/>
  <node id="1879317177" version="1" changeset="12832459" lat="50.017611" lon="36.173483" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317178" version="1" changeset="12832459" lat="50.017647" lon="36.1732811" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317179" version="1" changeset="12832459" lat="50.0176479" lon="36.1731771" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317180" version="1" changeset="12832459" lat="50.017678" lon="36.1737079" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317181" version="1" changeset="12832459" lat="50.0176829" lon="36.173487" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317182" version="1" changeset="12832459" lat="50.0176839" lon="36.173117" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317183" version="1" changeset="12832459" lat="50.0176879" lon="36.173259" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317186" version="1" changeset="12832459" lat="50.017791" lon="36.1734761" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317187" version="1" changeset="12832459" lat="50.017792" lon="36.173673" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317193" version="1" changeset="12832459" lat="50.017867" lon="36.173475" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317194" version="1" changeset="12832459" lat="50.017868" lon="36.1736721" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317199" version="1" changeset="12832459" lat="50.0179009" lon="36.1731011" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:22Z"/>
  <node id="1879317201" version="1" changeset="12832459" lat="50.0179049" lon="36.1732431" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:23Z"/>
  <node id="1879317206" version="1" changeset="12832459" lat="50.0179939" lon="36.1732721" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317208" version="1" changeset="12832459" lat="50.017995" lon="36.1731161" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317216" version="1" changeset="12832459" lat="50.0180359" lon="36.173437" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317218" version="1" changeset="12832459" lat="50.0180359" lon="36.1735491" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317225" version="1" changeset="12832459" lat="50.0180749" lon="36.173273" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317226" version="1" changeset="12832459" lat="50.0180759" lon="36.173117" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317229" version="1" changeset="12832459" lat="50.0181249" lon="36.1734361" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317231" version="1" changeset="12832459" lat="50.018125" lon="36.1735481" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317233" version="1" changeset="12832459" lat="50.0181309" lon="36.1734831" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317235" version="1" changeset="12832459" lat="50.018135" lon="36.173642" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:24Z"/>
  <node id="1879317274" version="1" changeset="12832459" lat="50.018138" lon="36.173097" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:25Z"/>
  <node id="1879317275" version="1" changeset="12832459" lat="50.018139" lon="36.172954" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:25Z"/>
  <node id="1879317280" version="1" changeset="12832459" lat="50.0181989" lon="36.1734791" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317282" version="1" changeset="12832459" lat="50.018203" lon="36.173638" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317284" version="1" changeset="12832459" lat="50.0182049" lon="36.1730981" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317287" version="1" changeset="12832459" lat="50.0182059" lon="36.172955" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317300" version="1" changeset="12832459" lat="50.0182659" lon="36.1735271" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317302" version="1" changeset="12832459" lat="50.018267" lon="36.1736961" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317305" version="1" changeset="12832459" lat="50.018286" lon="36.173114" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317308" version="1" changeset="12832459" lat="50.018287" lon="36.1729991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:26Z"/>
  <node id="1879317359" version="1" changeset="12832459" lat="50.0183579" lon="36.173526" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:27Z"/>
  <node id="1879317362" version="1" changeset="12832459" lat="50.0183589" lon="36.1736941" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:27Z"/>
  <node id="1879317364" version="1" changeset="12832459" lat="50.0183709" lon="36.173116" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:27Z"/>
  <node id="1879317367" version="1" changeset="12832459" lat="50.0183719" lon="36.1730011" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317369" version="1" changeset="12832459" lat="50.0183799" lon="36.1734971" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317372" version="1" changeset="12832459" lat="50.0183809" lon="36.1736601" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317384" version="1" changeset="12832459" lat="50.0184339" lon="36.173245" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317387" version="1" changeset="12832459" lat="50.018435" lon="36.173098" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317394" version="1" changeset="12832459" lat="50.0184669" lon="36.173496" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317395" version="1" changeset="12832459" lat="50.0184679" lon="36.1736581" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:28Z"/>
  <node id="1879317436" version="1" changeset="12832459" lat="50.0185159" lon="36.1736691" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:29Z"/>
  <node id="1879317438" version="1" changeset="12832459" lat="50.0185179" lon="36.173487" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:29Z"/>
  <node id="1879317441" version="1" changeset="12832459" lat="50.0185409" lon="36.1732521" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:29Z"/>
  <node id="1879317444" version="1" changeset="12832459" lat="50.0185419" lon="36.173105" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:29Z"/>
  <node id="1879317448" version="1" changeset="12832459" lat="50.0185879" lon="36.173671" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:29Z"/>
  <node id="1879317449" version="1" changeset="12832459" lat="50.0185889" lon="36.173488" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:30Z"/>
  <node id="1879317450" version="1" changeset="12832459" lat="50.0185909" lon="36.173175" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:30Z"/>
  <node id="1879317451" version="1" changeset="12832459" lat="50.0185919" lon="36.173027" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:30Z"/>
  <node id="1879317518" version="1" changeset="12832459" lat="50.0186629" lon="36.1731761" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:31Z"/>
  <node id="1879317519" version="1" changeset="12832459" lat="50.0186639" lon="36.173029" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:31Z"/>
  <node id="1879317541" version="1" changeset="12832459" lat="50.0187299" lon="36.1731061" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:31Z"/>
  <node id="1879317543" version="1" changeset="12832459" lat="50.018731" lon="36.172997" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:31Z"/>
  <node id="1879317610" version="1" changeset="12832459" lat="50.0188259" lon="36.173627" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:33Z"/>
  <node id="1879317617" version="1" changeset="12832459" lat="50.0188309" lon="36.173108" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:33Z"/>
  <node id="1879317619" version="1" changeset="12832459" lat="50.0188309" lon="36.1734249" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:33Z"/>
  <node id="1879317622" version="1" changeset="12832459" lat="50.0188319" lon="36.1729991" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:33Z"/>
  <node id="1879317683" version="1" changeset="12832459" lat="50.0188709" lon="36.1732531" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:35Z"/>
  <node id="1879317686" version="1" changeset="12832459" lat="50.0188719" lon="36.173087" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:35Z"/>
  <node id="1879317693" version="1" changeset="12832459" lat="50.0188969" lon="36.1736311" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:35Z"/>
  <node id="1879317700" version="1" changeset="12832459" lat="50.0189019" lon="36.173429" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:35Z"/>
  <node id="1879317731" version="1" changeset="12832459" lat="50.0189349" lon="36.173087" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:37Z"/>
  <node id="1879317732" version="1" changeset="12832459" lat="50.0189349" lon="36.17309" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:37Z"/>
  <node id="1879317733" version="1" changeset="12832459" lat="50.0189349" lon="36.1732541" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:37Z"/>
  <node id="1879317749" version="1" changeset="12832459" lat="50.0190029" lon="36.173616" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:39Z"/>
  <node id="1879317759" version="1" changeset="12832459" lat="50.019019" lon="36.173463" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:39Z"/>
  <node id="1879317782" version="1" changeset="12832459" lat="50.0190449" lon="36.173125" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:39Z"/>
  <node id="1879317807" version="1" changeset="12832459" lat="50.0190469" lon="36.173237" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:41Z"/>
  <node id="1879317814" version="1" changeset="12832459" lat="50.0190749" lon="36.173634" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:41Z"/>
  <node id="1879317834" version="1" changeset="12832459" lat="50.0190909" lon="36.173481" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:41Z"/>
  <node id="1879317889" version="1" changeset="12832459" lat="50.019129" lon="36.173636" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317892" version="1" changeset="12832459" lat="50.019134" lon="36.173506" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317893" version="1" changeset="12832459" lat="50.019142" lon="36.173121" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317894" version="1" changeset="12832459" lat="50.019144" lon="36.173233" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317900" version="1" changeset="12832459" lat="50.0191749" lon="36.173223" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317902" version="1" changeset="12832459" lat="50.01918" lon="36.1733291" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317907" version="1" changeset="12832459" lat="50.019194" lon="36.173642" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317909" version="1" changeset="12832459" lat="50.019198" lon="36.173511" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317911" version="1" changeset="12832459" lat="50.01921" lon="36.173723" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317946" version="1" changeset="12832459" lat="50.0192149" lon="36.173537" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:43Z"/>
  <node id="1879317953" version="1" changeset="12832459" lat="50.0192799" lon="36.1737399" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:44Z"/>
  <node id="1879317959" version="1" changeset="12832459" lat="50.0192849" lon="36.173554" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:44Z"/>
  <node id="1879317966" version="1" changeset="12832459" lat="50.0192979" lon="36.173735" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:45Z"/>
  <node id="1879317969" version="1" changeset="12832459" lat="50.0192999" lon="36.1735541" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:45Z"/>
  <node id="1879317974" version="1" changeset="12832459" lat="50.019312" lon="36.1732081" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:45Z"/>
  <node id="1879317979" version="1" changeset="12832459" lat="50.0193159" lon="36.173314" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:45Z"/>
  <node id="1879318025" version="1" changeset="12832459" lat="50.0193709" lon="36.173362" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:46Z"/>
  <node id="1879318029" version="1" changeset="12832459" lat="50.0193809" lon="36.1732571" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:46Z"/>
  <node id="1879318035" version="1" changeset="12832459" lat="50.0193839" lon="36.1737371" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:46Z"/>
  <node id="1879318037" version="1" changeset="12832459" lat="50.0193859" lon="36.173556" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:46Z"/>
  <node id="1879318040" version="1" changeset="12832459" lat="50.019426" lon="36.1738521" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:46Z"/>
  <node id="1879318043" version="1" changeset="12832459" lat="50.019445" lon="36.1736711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:47Z"/>
  <node id="1879318050" version="1" changeset="12832459" lat="50.0194479" lon="36.1733801" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:47Z"/>
  <node id="1879318053" version="1" changeset="12832459" lat="50.019458" lon="36.173275" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:47Z"/>
  <node id="1879318088" version="1" changeset="12832459" lat="50.019466" lon="36.173267" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318090" version="1" changeset="12832459" lat="50.0194759" lon="36.173162" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318100" version="1" changeset="12832459" lat="50.019506" lon="36.173872" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318105" version="1" changeset="12832459" lat="50.019525" lon="36.1736911" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318109" version="1" changeset="12832459" lat="50.019537" lon="36.1734431" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318112" version="1" changeset="12832459" lat="50.019543" lon="36.173285" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318114" version="1" changeset="12832459" lat="50.01955" lon="36.173304" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318117" version="1" changeset="12832459" lat="50.019553" lon="36.17318" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:48Z"/>
  <node id="1879318127" version="1" changeset="12832459" lat="50.0195989" lon="36.1737881" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:49Z"/>
  <node id="1879318158" version="1" changeset="12832459" lat="50.0196029" lon="36.173657" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318160" version="1" changeset="12832459" lat="50.0196059" lon="36.173459" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318167" version="1" changeset="12832459" lat="50.019619" lon="36.17332" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318179" version="1" changeset="12832459" lat="50.019645" lon="36.173456" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318183" version="1" changeset="12832459" lat="50.0196589" lon="36.173315" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318188" version="1" changeset="12832459" lat="50.0196629" lon="36.173793" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318191" version="1" changeset="12832459" lat="50.0196669" lon="36.1736621" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:50Z"/>
  <node id="1879318230" version="1" changeset="12832459" lat="50.0197069" lon="36.1734711" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:52Z"/>
  <node id="1879318235" version="1" changeset="12832459" lat="50.0197209" lon="36.173329" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:52Z"/>
  <node id="1879318238" version="1" changeset="12832459" lat="50.0197269" lon="36.173848" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:52Z"/>
  <node id="1879318253" version="1" changeset="12832459" lat="50.0197439" lon="36.173687" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:52Z"/>
  <node id="1879318302" version="1" changeset="12832459" lat="50.0198069" lon="36.173868" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:53Z"/>
  <node id="1879318308" version="1" changeset="12832459" lat="50.0198239" lon="36.173707" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:54Z"/>
  <node id="1879318320" version="1" changeset="12832459" lat="50.0198549" lon="36.173394" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:54Z"/>
  <node id="1879318321" version="1" changeset="12832459" lat="50.019864" lon="36.173216" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:54Z"/>
  <node id="1879318337" version="1" changeset="12832459" lat="50.019912" lon="36.1738831" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:54Z"/>
  <node id="1879318370" version="1" changeset="12832459" lat="50.019926" lon="36.173716" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:54Z"/>
  <node id="1879318371" version="1" changeset="12832459" lat="50.0199389" lon="36.173409" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:55Z"/>
  <node id="1879318372" version="1" changeset="12832459" lat="50.0199489" lon="36.173232" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:55Z"/>
  <node id="1879318391" version="1" changeset="12832459" lat="50.01997" lon="36.17351" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318395" version="1" changeset="12832459" lat="50.019973" lon="36.173401" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318399" version="1" changeset="12832459" lat="50.019977" lon="36.173896" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318403" version="1" changeset="12832459" lat="50.019991" lon="36.1737291" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318407" version="1" changeset="12832459" lat="50.020035" lon="36.173789" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318411" version="1" changeset="12832459" lat="50.0200399" lon="36.1739401" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318422" version="1" changeset="12832459" lat="50.0200599" lon="36.173517" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318423" version="1" changeset="12832459" lat="50.0200639" lon="36.173408" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:56Z"/>
  <node id="1879318501" version="1" changeset="12832459" lat="50.0201239" lon="36.173792" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:57Z"/>
  <node id="1879318502" version="1" changeset="12832459" lat="50.0201289" lon="36.1739321" user="dima_ua" uid="252456" visible="true" timestamp="2012-08-23T13:04:57Z"/>
  <node id="403981160" version="2" changeset="6469149" lat="50.0146063" lon="36.1770706" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:28Z"/>
  <node id="404745245" version="2" changeset="6469149" lat="50.0152588" lon="36.1760472" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:33Z"/>
  <node id="404745115" version="2" changeset="6469149" lat="50.0189995" lon="36.1733159" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:32Z"/>
  <node id="403981163" version="3" changeset="7108060" lat="50.0121645" lon="36.1771908" user="Vort" uid="189858" visible="true" timestamp="2011-01-27T21:38:22Z"/>
  <node id="403882831" version="2" changeset="6468694" lat="50.0043769" lon="36.1832762" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:07Z"/>
  <node id="404745907" version="2" changeset="6468694" lat="50.0097015" lon="36.1801577" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:08Z"/>
  <node id="403882892" version="2" changeset="6468694" lat="50.0049637" lon="36.1829285" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:08Z"/>
  <node id="403882732" version="2" changeset="6468694" lat="50.0033805" lon="36.1838665" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:09Z"/>
  <node id="403882897" version="2" changeset="6468694" lat="50.0041259" lon="36.1834249" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:12Z"/>
  <node id="403882919" version="2" changeset="6468694" lat="50.0075209" lon="36.1813944" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:14Z"/>
  <node id="403882022" version="2" changeset="6468694" lat="50.0101376" lon="36.179911" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:15Z"/>
  <node id="403882893" version="2" changeset="6468694" lat="50.0055379" lon="36.1825884" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:15Z"/>
  <node id="403883121" version="2" changeset="6468694" lat="50.006908" lon="36.1817662" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:16Z"/>
  <node id="441609517" version="2" changeset="6468694" lat="50.0061792" lon="36.1822087" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T11:22:16Z"/>
  <node id="1007336871" version="1" changeset="6469149" lat="50.0135991" lon="36.1772622" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:24Z"/>
  <node id="1007336889" version="1" changeset="6469149" lat="50.0115724" lon="36.1774506" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:25Z"/>
  <node id="1007336909" version="1" changeset="6469149" lat="50.0107654" lon="36.1788754" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:25Z"/>
  <node id="1007336959" version="1" changeset="6469149" lat="50.0140535" lon="36.1772924" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:26Z"/>
  <node id="403981166" version="3" changeset="6469149" lat="50.0105212" lon="36.1795283" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:34Z"/>
  <node id="403981165" version="2" changeset="6469149" lat="50.0113553" lon="36.1778011" user="Vort" uid="189858" visible="true" timestamp="2010-11-27T12:17:39Z"/>
  <node id="1277419503" version="1" changeset="8085592" lat="50.0163788" lon="36.1744989" user="Vort" uid="189858" visible="true" timestamp="2011-05-08T18:05:24Z"/>
  <node id="1277419543" version="1" changeset="8085592" lat="50.0157267" lon="36.1753553" user="Vort" uid="189858" visible="true" timestamp="2011-05-08T18:05:25Z"/>
  <node id="403882824" version="3" changeset="13217611" lat="50.0082359" lon="36.180987" user="_sev" uid="356014" visible="true" timestamp="2012-09-23T09:56:46Z"/>
  <node id="1938008465" version="1" changeset="13297111" lat="50.0143035" lon="36.1772773" user="dimonster" uid="719573" visible="true" timestamp="2012-09-29T14:14:29Z"/>
  <node id="1938008469" version="1" changeset="13297111" lat="50.0170208" lon="36.1734679" user="dimonster" uid="719573" visible="true" timestamp="2012-09-29T14:14:29Z"/>
  <node id="1938008470" version="1" changeset="13297111" lat="50.0171059" lon="36.1733401" user="dimonster" uid="719573" visible="true" timestamp="2012-09-29T14:14:29Z"/>
  <node id="404745090" version="3" changeset="13297111" lat="50.0203055" lon="36.1737069" user="dimonster" uid="719573" visible="true" timestamp="2012-09-29T14:14:39Z"/>
  <way id="177506692" visible="true" timestamp="2012-09-02T21:16:14Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879316837"/>
    <nd ref="1879316830"/>
    <nd ref="1879316823"/>
    <nd ref="1879316832"/>
    <nd ref="1879316837"/>
    <tag k="addr:housenumber" v="103"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506698" visible="true" timestamp="2012-09-02T21:17:06Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317394"/>
    <nd ref="1879317395"/>
    <nd ref="1879317372"/>
    <nd ref="1879317369"/>
    <nd ref="1879317394"/>
    <tag k="addr:housenumber" v="106"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506703" visible="true" timestamp="2012-09-02T21:17:28Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879316943"/>
    <nd ref="1879316922"/>
    <nd ref="1879316882"/>
    <nd ref="1879316934"/>
    <nd ref="1879316943"/>
    <tag k="addr:housenumber" v="107"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506705" visible="true" timestamp="2012-09-02T21:17:43Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317449"/>
    <nd ref="1879317448"/>
    <nd ref="1879317436"/>
    <nd ref="1879317438"/>
    <nd ref="1879317449"/>
    <tag k="addr:housenumber" v="108"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506803" visible="true" timestamp="2012-09-02T21:24:38Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317700"/>
    <nd ref="1879317693"/>
    <nd ref="1879317610"/>
    <nd ref="1879317619"/>
    <nd ref="1879317700"/>
    <tag k="addr:housenumber" v="112"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506807" visible="true" timestamp="2012-09-02T21:25:05Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317834"/>
    <nd ref="1879317814"/>
    <nd ref="1879317749"/>
    <nd ref="1879317759"/>
    <nd ref="1879317834"/>
    <tag k="addr:housenumber" v="114"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506899" visible="true" timestamp="2012-09-02T21:31:43Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879303130"/>
    <nd ref="1879303062"/>
    <nd ref="1879303275"/>
    <nd ref="1879303280"/>
    <nd ref="1879303421"/>
    <nd ref="1879303130"/>
    <tag k="addr:housenumber" v="12"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506932" visible="true" timestamp="2012-09-02T21:33:39Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317208"/>
    <nd ref="1879317226"/>
    <nd ref="1879317225"/>
    <nd ref="1879317206"/>
    <nd ref="1879317208"/>
    <tag k="addr:housenumber" v="123"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506938" visible="true" timestamp="2012-09-02T21:34:13Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318308"/>
    <nd ref="1879318302"/>
    <nd ref="1879318238"/>
    <nd ref="1879318253"/>
    <nd ref="1879318308"/>
    <tag k="addr:housenumber" v="126"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506940" visible="true" timestamp="2012-09-02T21:34:20Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317367"/>
    <nd ref="1879317364"/>
    <nd ref="1879317305"/>
    <nd ref="1879317308"/>
    <nd ref="1879317367"/>
    <tag k="addr:housenumber" v="127"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506941" visible="true" timestamp="2012-09-02T21:34:32Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318403"/>
    <nd ref="1879318399"/>
    <nd ref="1879318337"/>
    <nd ref="1879318370"/>
    <nd ref="1879318403"/>
    <tag k="addr:housenumber" v="128"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506943" visible="true" timestamp="2012-09-02T21:34:36Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317444"/>
    <nd ref="1879317441"/>
    <nd ref="1879317384"/>
    <nd ref="1879317387"/>
    <nd ref="1879317444"/>
    <tag k="addr:housenumber" v="129"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507072" visible="true" timestamp="2012-09-02T21:41:46Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317893"/>
    <nd ref="1879317894"/>
    <nd ref="1879317807"/>
    <nd ref="1879317782"/>
    <nd ref="1879317893"/>
    <tag k="addr:housenumber" v="137"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507195" visible="true" timestamp="2012-09-02T21:47:48Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318235"/>
    <nd ref="1879318230"/>
    <nd ref="1879318179"/>
    <nd ref="1879318183"/>
    <nd ref="1879318235"/>
    <tag k="addr:housenumber" v="147"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507197" visible="true" timestamp="2012-09-02T21:48:10Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318372"/>
    <nd ref="1879318371"/>
    <nd ref="1879318320"/>
    <nd ref="1879318321"/>
    <nd ref="1879318372"/>
    <tag k="addr:housenumber" v="149"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507253" visible="true" timestamp="2012-09-02T21:49:44Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305545"/>
    <nd ref="1879305589"/>
    <nd ref="1879305461"/>
    <nd ref="1879305420"/>
    <nd ref="1879305545"/>
    <tag k="addr:housenumber" v="15"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177508573" visible="true" timestamp="2012-09-02T22:28:37Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305801"/>
    <nd ref="1879305844"/>
    <nd ref="1879305716"/>
    <nd ref="1879305680"/>
    <nd ref="1879305801"/>
    <tag k="addr:housenumber" v="22"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510376" visible="true" timestamp="2012-09-03T18:59:53Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879302156"/>
    <nd ref="1879302248"/>
    <nd ref="1879302301"/>
    <nd ref="1879302213"/>
    <nd ref="1879302156"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="5"/>
  </way>
  <way id="177510471" visible="true" timestamp="2012-09-03T19:04:45Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314087"/>
    <nd ref="1879313994"/>
    <nd ref="1879313995"/>
    <nd ref="1879314088"/>
    <nd ref="1879314087"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="51"/>
  </way>
  <way id="177510521" visible="true" timestamp="2012-09-03T19:08:09Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314229"/>
    <nd ref="1879314225"/>
    <nd ref="1879314182"/>
    <nd ref="1879314184"/>
    <nd ref="1879314229"/>
    <tag k="addr:housenumber" v="53"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511116" visible="true" timestamp="2012-09-03T19:37:54Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314831"/>
    <nd ref="1879314830"/>
    <nd ref="1879314758"/>
    <nd ref="1879314759"/>
    <nd ref="1879314831"/>
    <tag k="addr:housenumber" v="71"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511120" visible="true" timestamp="2012-09-03T19:38:28Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314426"/>
    <nd ref="1879314462"/>
    <nd ref="1879314416"/>
    <nd ref="1879314411"/>
    <nd ref="1879314426"/>
    <tag k="addr:housenumber" v="72"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511139" visible="true" timestamp="2012-09-03T19:39:14Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314996"/>
    <nd ref="1879314989"/>
    <nd ref="1879314967"/>
    <nd ref="1879314973"/>
    <nd ref="1879314996"/>
    <tag k="addr:housenumber" v="73"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511168" visible="true" timestamp="2012-09-03T19:41:19Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314535"/>
    <nd ref="1879314558"/>
    <nd ref="1879314557"/>
    <nd ref="1879314533"/>
    <nd ref="1879314535"/>
    <tag k="addr:housenumber" v="76"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511204" visible="true" timestamp="2012-09-03T19:42:26Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314600"/>
    <nd ref="1879314616"/>
    <nd ref="1879314615"/>
    <nd ref="1879314597"/>
    <nd ref="1879314600"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="78"/>
  </way>
  <way id="177511313" visible="true" timestamp="2012-09-03T19:46:16Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879302153"/>
    <nd ref="1879302238"/>
    <nd ref="1879302094"/>
    <nd ref="1879302022"/>
    <nd ref="1879302153"/>
    <tag k="addr:housenumber" v="8"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511344" visible="true" timestamp="2012-09-03T19:49:18Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314655"/>
    <nd ref="1879314653"/>
    <nd ref="1879314620"/>
    <nd ref="1879314642"/>
    <nd ref="1879314655"/>
    <tag k="addr:housenumber" v="80"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511354" visible="true" timestamp="2012-09-03T19:49:57Z" version="3" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314673"/>
    <nd ref="1879314672"/>
    <nd ref="1879314658"/>
    <nd ref="1879314662"/>
    <nd ref="1879314673"/>
    <tag k="addr:housenumber" v="80а"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511375" visible="true" timestamp="2012-09-03T19:51:39Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314819"/>
    <nd ref="1879314813"/>
    <nd ref="1879314739"/>
    <nd ref="1879314742"/>
    <nd ref="1879314819"/>
    <tag k="addr:housenumber" v="84"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511403" visible="true" timestamp="2012-09-03T19:53:25Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315609"/>
    <nd ref="1879315581"/>
    <nd ref="1879315565"/>
    <nd ref="1879315593"/>
    <nd ref="1879315609"/>
    <tag k="addr:housenumber" v="87"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511409" visible="true" timestamp="2012-09-03T19:53:49Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315070"/>
    <nd ref="1879315071"/>
    <nd ref="1879315039"/>
    <nd ref="1879315037"/>
    <nd ref="1879315070"/>
    <tag k="addr:housenumber" v="88"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511658" visible="true" timestamp="2012-09-03T20:03:49Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879316589"/>
    <nd ref="1879316554"/>
    <nd ref="1879316474"/>
    <nd ref="1879316561"/>
    <nd ref="1879316589"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="97"/>
  </way>
  <way id="177506660" visible="true" timestamp="2012-09-02T21:14:58Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879302874"/>
    <nd ref="1879302649"/>
    <nd ref="1879302588"/>
    <nd ref="1879302437"/>
    <nd ref="1879302383"/>
    <nd ref="1879302697"/>
    <nd ref="1879302874"/>
    <tag k="addr:housenumber" v="10"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506678" visible="true" timestamp="2012-09-02T21:15:30Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317229"/>
    <nd ref="1879317231"/>
    <nd ref="1879317218"/>
    <nd ref="1879317216"/>
    <nd ref="1879317229"/>
    <tag k="addr:housenumber" v="100"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506682" visible="true" timestamp="2012-09-02T21:15:39Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879316826"/>
    <nd ref="1879316753"/>
    <nd ref="1879316727"/>
    <nd ref="1879316813"/>
    <nd ref="1879316826"/>
    <tag k="addr:housenumber" v="101"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506687" visible="true" timestamp="2012-09-02T21:16:00Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317280"/>
    <nd ref="1879317282"/>
    <nd ref="1879317235"/>
    <nd ref="1879317233"/>
    <nd ref="1879317280"/>
    <tag k="addr:housenumber" v="102"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506694" visible="true" timestamp="2012-09-02T21:16:40Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317359"/>
    <nd ref="1879317362"/>
    <nd ref="1879317302"/>
    <nd ref="1879317300"/>
    <nd ref="1879317359"/>
    <tag k="addr:housenumber" v="104"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506696" visible="true" timestamp="2012-09-02T21:16:55Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879316890"/>
    <nd ref="1879316874"/>
    <nd ref="1879316860"/>
    <nd ref="1879316879"/>
    <nd ref="1879316890"/>
    <tag k="addr:housenumber" v="105"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506706" visible="true" timestamp="2012-09-02T21:18:02Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317019"/>
    <nd ref="1879317016"/>
    <nd ref="1879316962"/>
    <nd ref="1879317013"/>
    <nd ref="1879317019"/>
    <tag k="addr:housenumber" v="109"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177506805" visible="true" timestamp="2012-09-02T21:24:47Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317043"/>
    <nd ref="1879317063"/>
    <nd ref="1879317048"/>
    <nd ref="1879317027"/>
    <nd ref="1879317043"/>
    <tag k="addr:housenumber" v="113"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506809" visible="true" timestamp="2012-09-02T21:25:17Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317124"/>
    <nd ref="1879317112"/>
    <nd ref="1879317077"/>
    <nd ref="1879317122"/>
    <nd ref="1879317124"/>
    <tag k="addr:housenumber" v="115"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506813" visible="true" timestamp="2012-09-02T21:25:22Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317959"/>
    <nd ref="1879317953"/>
    <nd ref="1879317911"/>
    <nd ref="1879317946"/>
    <nd ref="1879317959"/>
    <tag k="addr:housenumber" v="116"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506816" visible="true" timestamp="2012-09-02T21:25:43Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317133"/>
    <nd ref="1879317132"/>
    <nd ref="1879317129"/>
    <nd ref="1879317128"/>
    <nd ref="1879317133"/>
    <tag k="addr:housenumber" v="117"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506817" visible="true" timestamp="2012-09-02T21:25:48Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317909"/>
    <nd ref="1879317907"/>
    <nd ref="1879317889"/>
    <nd ref="1879317892"/>
    <nd ref="1879317909"/>
    <tag k="addr:housenumber" v="118"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506819" visible="true" timestamp="2012-09-02T21:26:05Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317179"/>
    <nd ref="1879317178"/>
    <nd ref="1879317140"/>
    <nd ref="1879317143"/>
    <nd ref="1879317179"/>
    <tag k="addr:housenumber" v="119"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506923" visible="true" timestamp="2012-09-02T21:33:10Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318037"/>
    <nd ref="1879318035"/>
    <nd ref="1879317966"/>
    <nd ref="1879317969"/>
    <nd ref="1879318037"/>
    <tag k="addr:housenumber" v="120"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506925" visible="true" timestamp="2012-09-02T21:33:29Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317199"/>
    <nd ref="1879317201"/>
    <nd ref="1879317183"/>
    <nd ref="1879317182"/>
    <nd ref="1879317199"/>
    <tag k="addr:housenumber" v="121"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506929" visible="true" timestamp="2012-09-02T21:33:30Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318105"/>
    <nd ref="1879318100"/>
    <nd ref="1879318040"/>
    <nd ref="1879318043"/>
    <nd ref="1879318105"/>
    <tag k="addr:housenumber" v="122"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506934" visible="true" timestamp="2012-09-02T21:33:51Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318191"/>
    <nd ref="1879318188"/>
    <nd ref="1879318127"/>
    <nd ref="1879318158"/>
    <nd ref="1879318191"/>
    <tag k="addr:housenumber" v="124"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177506935" visible="true" timestamp="2012-09-02T21:34:03Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317287"/>
    <nd ref="1879317284"/>
    <nd ref="1879317274"/>
    <nd ref="1879317275"/>
    <nd ref="1879317287"/>
    <tag k="addr:housenumber" v="125"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507018" visible="true" timestamp="2012-09-02T21:35:22Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305519"/>
    <nd ref="1879305385"/>
    <nd ref="1879305330"/>
    <nd ref="1879305468"/>
    <nd ref="1879305519"/>
    <tag k="addr:housenumber" v="13"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507030" visible="true" timestamp="2012-09-02T21:40:01Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318407"/>
    <nd ref="1879318501"/>
    <nd ref="1879318502"/>
    <nd ref="1879318411"/>
    <nd ref="1879318407"/>
    <tag k="addr:housenumber" v="130"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507035" visible="true" timestamp="2012-09-02T21:40:09Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317519"/>
    <nd ref="1879317518"/>
    <nd ref="1879317450"/>
    <nd ref="1879317451"/>
    <nd ref="1879317519"/>
    <tag k="addr:housenumber" v="131"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507051" visible="true" timestamp="2012-09-02T21:40:45Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317622"/>
    <nd ref="1879317617"/>
    <nd ref="1879317541"/>
    <nd ref="1879317543"/>
    <nd ref="1879317622"/>
    <tag k="addr:housenumber" v="133"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507057" visible="true" timestamp="2012-09-02T21:41:13Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317683"/>
    <nd ref="1879317686"/>
    <nd ref="1879317731"/>
    <nd ref="1879317732"/>
    <nd ref="1879317733"/>
    <nd ref="1879317683"/>
    <tag k="addr:housenumber" v="135"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507086" visible="true" timestamp="2012-09-02T21:42:01Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879317974"/>
    <nd ref="1879317979"/>
    <nd ref="1879317902"/>
    <nd ref="1879317900"/>
    <nd ref="1879317974"/>
    <tag k="addr:housenumber" v="139"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507139" visible="true" timestamp="2012-09-02T21:43:50Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879303851"/>
    <nd ref="1879303913"/>
    <nd ref="1879303656"/>
    <nd ref="1879303584"/>
    <nd ref="1879303851"/>
    <tag k="addr:housenumber" v="14"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507184" visible="true" timestamp="2012-09-02T21:46:41Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318053"/>
    <nd ref="1879318050"/>
    <nd ref="1879318025"/>
    <nd ref="1879318029"/>
    <nd ref="1879318053"/>
    <tag k="addr:housenumber" v="141"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507187" visible="true" timestamp="2012-09-02T21:47:11Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318117"/>
    <nd ref="1879318112"/>
    <nd ref="1879318088"/>
    <nd ref="1879318090"/>
    <nd ref="1879318117"/>
    <tag k="addr:housenumber" v="143"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507191" visible="true" timestamp="2012-09-02T21:47:27Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318167"/>
    <nd ref="1879318160"/>
    <nd ref="1879318109"/>
    <nd ref="1879318114"/>
    <nd ref="1879318167"/>
    <tag k="addr:housenumber" v="145"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507323" visible="true" timestamp="2012-09-02T21:53:00Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879318422"/>
    <nd ref="1879318391"/>
    <nd ref="1879318395"/>
    <nd ref="1879318423"/>
    <nd ref="1879318422"/>
    <tag k="addr:housenumber" v="151"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507374" visible="true" timestamp="2012-09-02T21:53:54Z" version="3" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305675"/>
    <nd ref="1879305714"/>
    <nd ref="1879305636"/>
    <nd ref="1879305596"/>
    <nd ref="1879305675"/>
    <tag k="addr:housenumber" v="15а"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507509" visible="true" timestamp="2012-09-02T21:55:26Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879304301"/>
    <nd ref="1879304460"/>
    <nd ref="1879304260"/>
    <nd ref="1879304159"/>
    <nd ref="1879304301"/>
    <tag k="addr:housenumber" v="16"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177507906" visible="true" timestamp="2012-09-02T22:05:49Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305172"/>
    <nd ref="1879305216"/>
    <nd ref="1879305071"/>
    <nd ref="1879304960"/>
    <nd ref="1879305172"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="18"/>
  </way>
  <way id="177508357" visible="true" timestamp="2012-09-02T22:18:30Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879303605"/>
    <nd ref="1879303814"/>
    <nd ref="1879303896"/>
    <nd ref="1879303684"/>
    <nd ref="1879303605"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="2/9"/>
  </way>
  <way id="177508392" visible="true" timestamp="2012-09-02T22:21:21Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305436"/>
    <nd ref="1879305467"/>
    <nd ref="1879305382"/>
    <nd ref="1879305328"/>
    <nd ref="1879305436"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="20"/>
  </way>
  <way id="177508636" visible="true" timestamp="2012-09-02T22:30:39Z" version="3" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879305600"/>
    <nd ref="1879305662"/>
    <nd ref="1879305544"/>
    <nd ref="1879305474"/>
    <nd ref="1879305600"/>
    <tag k="addr:housenumber" v="22а"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177508739" visible="true" timestamp="2012-09-02T22:35:44Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879306194"/>
    <nd ref="1879306223"/>
    <nd ref="1879305988"/>
    <nd ref="1879305963"/>
    <nd ref="1879306194"/>
    <tag k="addr:housenumber" v="24"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177508906" visible="true" timestamp="2012-09-02T22:42:23Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879306495"/>
    <nd ref="1879306595"/>
    <nd ref="1879306472"/>
    <nd ref="1879306402"/>
    <nd ref="1879306495"/>
    <tag k="addr:housenumber" v="26"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509099" visible="true" timestamp="2012-09-02T22:49:33Z" version="2" changeset="12960315" user="_sev" uid="356014">
    <nd ref="1879306664"/>
    <nd ref="1879306704"/>
    <nd ref="1879306588"/>
    <nd ref="1879306540"/>
    <nd ref="1879306664"/>
    <tag k="addr:housenumber" v="28"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509231" visible="true" timestamp="2012-09-03T18:12:35Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879301812"/>
    <nd ref="1879301627"/>
    <nd ref="1879301532"/>
    <nd ref="1879301727"/>
    <nd ref="1879301812"/>
    <tag k="addr:housenumber" v="3"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509369" visible="true" timestamp="2012-09-03T18:15:38Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879306966"/>
    <nd ref="1879306785"/>
    <nd ref="1879306710"/>
    <nd ref="1879306917"/>
    <nd ref="1879306966"/>
    <tag k="addr:housenumber" v="30"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509466" visible="true" timestamp="2012-09-03T18:17:48Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879309359"/>
    <nd ref="1879309145"/>
    <nd ref="1879309005"/>
    <nd ref="1879309283"/>
    <nd ref="1879309359"/>
    <tag k="addr:housenumber" v="31"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177509497" visible="true" timestamp="2012-09-03T18:19:26Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879307186"/>
    <nd ref="1879307223"/>
    <nd ref="1879307125"/>
    <nd ref="1879307092"/>
    <nd ref="1879307186"/>
    <tag k="addr:housenumber" v="32"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177509625" visible="true" timestamp="2012-09-03T18:22:57Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879309949"/>
    <nd ref="1879309797"/>
    <nd ref="1879309764"/>
    <nd ref="1879309923"/>
    <nd ref="1879309949"/>
    <tag k="addr:housenumber" v="33"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509643" visible="true" timestamp="2012-09-03T18:23:55Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879307377"/>
    <nd ref="1879307426"/>
    <nd ref="1879307328"/>
    <nd ref="1879307288"/>
    <nd ref="1879307377"/>
    <tag k="addr:housenumber" v="34"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177509727" visible="true" timestamp="2012-09-03T18:28:27Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879307646"/>
    <nd ref="1879307663"/>
    <nd ref="1879307601"/>
    <nd ref="1879307568"/>
    <nd ref="1879307646"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="36"/>
  </way>
  <way id="177509770" visible="true" timestamp="2012-09-03T18:29:15Z" version="3" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879307499"/>
    <nd ref="1879307508"/>
    <nd ref="1879307459"/>
    <nd ref="1879307429"/>
    <nd ref="1879307499"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="36а"/>
  </way>
  <way id="177509783" visible="true" timestamp="2012-09-03T18:30:00Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879310796"/>
    <nd ref="1879310723"/>
    <nd ref="1879310709"/>
    <nd ref="1879310783"/>
    <nd ref="1879310796"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="37"/>
  </way>
  <way id="177509806" visible="true" timestamp="2012-09-03T18:32:07Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879308027"/>
    <nd ref="1879308077"/>
    <nd ref="1879307858"/>
    <nd ref="1879307748"/>
    <nd ref="1879308027"/>
    <tag k="addr:housenumber" v="38"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177509858" visible="true" timestamp="2012-09-03T18:33:24Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879310946"/>
    <nd ref="1879310862"/>
    <nd ref="1879310844"/>
    <nd ref="1879310932"/>
    <nd ref="1879310946"/>
    <tag k="addr:housenumber" v="39"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177509942" visible="true" timestamp="2012-09-03T18:39:00Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879301736"/>
    <nd ref="1879301830"/>
    <nd ref="1879301535"/>
    <nd ref="1879301453"/>
    <nd ref="1879301736"/>
    <tag k="addr:housenumber" v="4"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177509979" visible="true" timestamp="2012-09-03T18:42:16Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879308372"/>
    <nd ref="1879308454"/>
    <nd ref="1879308292"/>
    <nd ref="1879308223"/>
    <nd ref="1879308372"/>
    <tag k="addr:housenumber" v="40"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510000" visible="true" timestamp="2012-09-03T18:43:26Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879311269"/>
    <nd ref="1879311119"/>
    <nd ref="1879311065"/>
    <nd ref="1879311254"/>
    <nd ref="1879311269"/>
    <tag k="addr:housenumber" v="41"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510084" visible="true" timestamp="2012-09-03T18:48:27Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879308705"/>
    <nd ref="1879308738"/>
    <nd ref="1879308648"/>
    <nd ref="1879308624"/>
    <nd ref="1879308705"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="44"/>
  </way>
  <way id="177510181" visible="true" timestamp="2012-09-03T18:50:51Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879309396"/>
    <nd ref="1879309475"/>
    <nd ref="1879309371"/>
    <nd ref="1879309260"/>
    <nd ref="1879309396"/>
    <tag k="addr:housenumber" v="46"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510153" visible="true" timestamp="2012-09-03T18:50:02Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879311989"/>
    <nd ref="1879312009"/>
    <nd ref="1879311808"/>
    <nd ref="1879311747"/>
    <nd ref="1879311989"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="45"/>
  </way>
  <way id="177510222" visible="true" timestamp="2012-09-03T18:54:18Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879309509"/>
    <nd ref="1879309530"/>
    <nd ref="1879309485"/>
    <nd ref="1879309435"/>
    <nd ref="1879309509"/>
    <tag k="addr:housenumber" v="48"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510266" visible="true" timestamp="2012-09-03T18:55:57Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879313888"/>
    <nd ref="1879313775"/>
    <nd ref="1879313772"/>
    <nd ref="1879313886"/>
    <nd ref="1879313888"/>
    <tag k="addr:housenumber" v="49"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510273" visible="true" timestamp="2012-09-03T18:56:18Z" version="3" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879302098"/>
    <nd ref="1879302147"/>
    <nd ref="1879301950"/>
    <nd ref="1879301873"/>
    <nd ref="1879302098"/>
    <tag k="addr:housenumber" v="4а"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510592" visible="true" timestamp="2012-09-03T19:09:54Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314348"/>
    <nd ref="1879314298"/>
    <nd ref="1879314303"/>
    <nd ref="1879314351"/>
    <nd ref="1879314348"/>
    <tag k="addr:housenumber" v="55"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510651" visible="true" timestamp="2012-09-03T19:12:57Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314409"/>
    <nd ref="1879314407"/>
    <nd ref="1879314365"/>
    <nd ref="1879314367"/>
    <nd ref="1879314409"/>
    <tag k="addr:housenumber" v="57"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510672" visible="true" timestamp="2012-09-03T19:14:46Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314477"/>
    <nd ref="1879314474"/>
    <nd ref="1879314428"/>
    <nd ref="1879314431"/>
    <nd ref="1879314477"/>
    <tag k="addr:housenumber" v="59"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510701" visible="true" timestamp="2012-09-03T19:15:46Z" version="3" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879302606"/>
    <nd ref="1879302442"/>
    <nd ref="1879302332"/>
    <nd ref="1879302500"/>
    <nd ref="1879302606"/>
    <tag k="addr:housenumber" v="5а"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510868" visible="true" timestamp="2012-09-03T19:23:45Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314528"/>
    <nd ref="1879314525"/>
    <nd ref="1879314490"/>
    <nd ref="1879314493"/>
    <nd ref="1879314528"/>
    <tag k="addr:housenumber" v="61"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177510896" visible="true" timestamp="2012-09-03T19:25:28Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314584"/>
    <nd ref="1879314559"/>
    <nd ref="1879314549"/>
    <nd ref="1879314552"/>
    <nd ref="1879314584"/>
    <tag k="addr:housenumber" v="63"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510915" visible="true" timestamp="2012-09-03T19:27:29Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314618"/>
    <nd ref="1879314617"/>
    <nd ref="1879314608"/>
    <nd ref="1879314610"/>
    <nd ref="1879314618"/>
    <tag k="addr:housenumber" v="65"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510928" visible="true" timestamp="2012-09-03T19:29:19Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314664"/>
    <nd ref="1879314663"/>
    <nd ref="1879314647"/>
    <nd ref="1879314650"/>
    <nd ref="1879314664"/>
    <tag k="addr:housenumber" v="67"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177510949" visible="true" timestamp="2012-09-03T19:30:13Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314698"/>
    <nd ref="1879314695"/>
    <nd ref="1879314679"/>
    <nd ref="1879314681"/>
    <nd ref="1879314698"/>
    <tag k="addr:housenumber" v="69"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511159" visible="true" timestamp="2012-09-03T19:39:57Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314522"/>
    <nd ref="1879314521"/>
    <nd ref="1879314469"/>
    <nd ref="1879314472"/>
    <nd ref="1879314522"/>
    <tag k="addr:housenumber" v="74"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511163" visible="true" timestamp="2012-09-03T19:40:16Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315052"/>
    <nd ref="1879315089"/>
    <nd ref="1879315069"/>
    <nd ref="1879315047"/>
    <nd ref="1879315052"/>
    <tag k="addr:housenumber" v="75"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511196" visible="true" timestamp="2012-09-03T19:41:49Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315152"/>
    <nd ref="1879315140"/>
    <nd ref="1879315091"/>
    <nd ref="1879315095"/>
    <nd ref="1879315152"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="77"/>
  </way>
  <way id="177511210" visible="true" timestamp="2012-09-03T19:42:50Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315243"/>
    <nd ref="1879315236"/>
    <nd ref="1879315209"/>
    <nd ref="1879315213"/>
    <nd ref="1879315243"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="79"/>
  </way>
  <way id="177511618" visible="true" timestamp="2012-09-03T20:01:32Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879317126"/>
    <nd ref="1879317127"/>
    <nd ref="1879317120"/>
    <nd ref="1879317117"/>
    <nd ref="1879317126"/>
    <tag k="addr:housenumber" v="92"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511357" visible="true" timestamp="2012-09-03T19:50:26Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315409"/>
    <nd ref="1879315402"/>
    <nd ref="1879315339"/>
    <nd ref="1879315383"/>
    <nd ref="1879315409"/>
    <tag k="addr:housenumber" v="81"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511362" visible="true" timestamp="2012-09-03T19:50:38Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314840"/>
    <nd ref="1879314838"/>
    <nd ref="1879314762"/>
    <nd ref="1879314764"/>
    <nd ref="1879314840"/>
    <tag k="addr:housenumber" v="82"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511366" visible="true" timestamp="2012-09-03T19:50:58Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314764"/>
    <nd ref="1879314762"/>
    <nd ref="1879314735"/>
    <nd ref="1879314736"/>
    <nd ref="1879314764"/>
    <tag k="addr:housenumber" v="82/1"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511368" visible="true" timestamp="2012-09-03T19:51:13Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315434"/>
    <nd ref="1879315429"/>
    <nd ref="1879315399"/>
    <nd ref="1879315412"/>
    <nd ref="1879315434"/>
    <tag k="addr:housenumber" v="83"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511380" visible="true" timestamp="2012-09-03T19:52:24Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315504"/>
    <nd ref="1879315487"/>
    <nd ref="1879315440"/>
    <nd ref="1879315478"/>
    <nd ref="1879315504"/>
    <tag k="addr:housenumber" v="85"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511387" visible="true" timestamp="2012-09-03T19:52:51Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879314924"/>
    <nd ref="1879314922"/>
    <nd ref="1879314855"/>
    <nd ref="1879314857"/>
    <nd ref="1879314924"/>
    <tag k="addr:housenumber" v="86"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
  </way>
  <way id="177511414" visible="true" timestamp="2012-09-03T19:54:31Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315809"/>
    <nd ref="1879315855"/>
    <nd ref="1879315807"/>
    <nd ref="1879315681"/>
    <nd ref="1879315809"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="89"/>
  </way>
  <way id="177511418" visible="true" timestamp="2012-09-03T19:54:46Z" version="3" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879302230"/>
    <nd ref="1879302283"/>
    <nd ref="1879302072"/>
    <nd ref="1879302031"/>
    <nd ref="1879302230"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="8а"/>
  </way>
  <way id="177511608" visible="true" timestamp="2012-09-03T20:00:41Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879315158"/>
    <nd ref="1879315160"/>
    <nd ref="1879315101"/>
    <nd ref="1879315100"/>
    <nd ref="1879315158"/>
    <tag k="addr:housenumber" v="90"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511613" visible="true" timestamp="2012-09-03T20:00:58Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879316095"/>
    <nd ref="1879315967"/>
    <nd ref="1879315941"/>
    <nd ref="1879315971"/>
    <nd ref="1879316095"/>
    <tag k="addr:housenumber" v="91"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511626" visible="true" timestamp="2012-09-03T20:02:22Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879316127"/>
    <nd ref="1879316307"/>
    <nd ref="1879316137"/>
    <nd ref="1879316086"/>
    <nd ref="1879316120"/>
    <nd ref="1879316070"/>
    <nd ref="1879316127"/>
    <tag k="addr:housenumber" v="93"/>
    <tag k="building" v="yes"/>
    <tag k="building:levels" v="1"/>
  </way>
  <way id="177511629" visible="true" timestamp="2012-09-03T20:02:52Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879317135"/>
    <nd ref="1879317138"/>
    <nd ref="1879317131"/>
    <nd ref="1879317130"/>
    <nd ref="1879317135"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="94"/>
  </way>
  <way id="177511632" visible="true" timestamp="2012-09-03T20:03:10Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879316467"/>
    <nd ref="1879316429"/>
    <nd ref="1879316314"/>
    <nd ref="1879316434"/>
    <nd ref="1879316467"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="95"/>
  </way>
  <way id="177511637" visible="true" timestamp="2012-09-03T20:03:21Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879317181"/>
    <nd ref="1879317180"/>
    <nd ref="1879317145"/>
    <nd ref="1879317177"/>
    <nd ref="1879317181"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="96"/>
  </way>
  <way id="177511682" visible="true" timestamp="2012-09-03T20:04:12Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879317193"/>
    <nd ref="1879317194"/>
    <nd ref="1879317187"/>
    <nd ref="1879317186"/>
    <nd ref="1879317193"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="98"/>
  </way>
  <way id="177511694" visible="true" timestamp="2012-09-03T20:04:30Z" version="2" changeset="12970502" user="_sev" uid="356014">
    <nd ref="1879316723"/>
    <nd ref="1879316687"/>
    <nd ref="1879316599"/>
    <nd ref="1879316691"/>
    <nd ref="1879316723"/>
    <tag k="building:levels" v="1"/>
    <tag k="building" v="yes"/>
    <tag k="addr:housenumber" v="99"/>
  </way>
  <way id="34731509" visible="true" timestamp="2012-09-29T14:14:36Z" version="4" changeset="13297111" user="dimonster" uid="719573">
    <nd ref="404745090"/>
    <nd ref="404745115"/>
    <nd ref="1938008470"/>
    <nd ref="1938008469"/>
    <nd ref="1277419503"/>
    <nd ref="1277419543"/>
    <nd ref="404745245"/>
    <nd ref="403981160"/>
    <nd ref="1938008465"/>
    <nd ref="1007336959"/>
    <nd ref="1007336871"/>
    <nd ref="403981163"/>
    <nd ref="1007336889"/>
    <nd ref="403981165"/>
    <nd ref="1007336909"/>
    <nd ref="403981166"/>
    <nd ref="403882022"/>
    <nd ref="404745907"/>
    <nd ref="403882824"/>
    <nd ref="403882919"/>
    <nd ref="403883121"/>
    <nd ref="441609517"/>
    <nd ref="403882893"/>
    <nd ref="403882892"/>
    <nd ref="403882831"/>
    <nd ref="403882897"/>
    <nd ref="403882732"/>
    <tag k="note" v="Вроде бы по русски это Краснопоселковая. Но в документе она Червоноселищная"/>
    <tag k="name" v="Червоноселищна вулиця"/>
    <tag k="name:ru" v="Червоноселищная улица"/>
    <tag k="highway" v="residential"/>
  </way>
  <relation id="2391763" visible="true" timestamp="2012-09-29T14:14:33Z" version="2" changeset="13297111" user="dimonster" uid="719573">
    <member type="way" ref="34731509" role="street"/>
    <member type="way" ref="177506660" role="house"/>
    <member type="way" ref="177506678" role="house"/>
    <member type="way" ref="177506682" role="house"/>
    <member type="way" ref="177506687" role="house"/>
    <member type="way" ref="177506692" role="house"/>
    <member type="way" ref="177506694" role="house"/>
    <member type="way" ref="177506696" role="house"/>
    <member type="way" ref="177506698" role="house"/>
    <member type="way" ref="177506703" role="house"/>
    <member type="way" ref="177506705" role="house"/>
    <member type="way" ref="177506706" role="house"/>
    <member type="way" ref="177506803" role="house"/>
    <member type="way" ref="177506805" role="house"/>
    <member type="way" ref="177506807" role="house"/>
    <member type="way" ref="177506809" role="house"/>
    <member type="way" ref="177506813" role="house"/>
    <member type="way" ref="177506816" role="house"/>
    <member type="way" ref="177506817" role="house"/>
    <member type="way" ref="177506819" role="house"/>
    <member type="way" ref="177506899" role="house"/>
    <member type="way" ref="177506923" role="house"/>
    <member type="way" ref="177506925" role="house"/>
    <member type="way" ref="177506929" role="house"/>
    <member type="way" ref="177506932" role="house"/>
    <member type="way" ref="177506934" role="house"/>
    <member type="way" ref="177506935" role="house"/>
    <member type="way" ref="177506938" role="house"/>
    <member type="way" ref="177506940" role="house"/>
    <member type="way" ref="177506941" role="house"/>
    <member type="way" ref="177506943" role="house"/>
    <member type="way" ref="177507018" role="house"/>
    <member type="way" ref="177507030" role="house"/>
    <member type="way" ref="177507035" role="house"/>
    <member type="way" ref="177507051" role="house"/>
    <member type="way" ref="177507057" role="house"/>
    <member type="way" ref="177507072" role="house"/>
    <member type="way" ref="177507086" role="house"/>
    <member type="way" ref="177507139" role="house"/>
    <member type="way" ref="177507184" role="house"/>
    <member type="way" ref="177507187" role="house"/>
    <member type="way" ref="177507191" role="house"/>
    <member type="way" ref="177507195" role="house"/>
    <member type="way" ref="177507197" role="house"/>
    <member type="way" ref="177507253" role="house"/>
    <member type="way" ref="177507323" role="house"/>
    <member type="way" ref="177507374" role="house"/>
    <member type="way" ref="177507509" role="house"/>
    <member type="way" ref="177507906" role="house"/>
    <member type="way" ref="177508357" role="house"/>
    <member type="way" ref="177508392" role="house"/>
    <member type="way" ref="177508573" role="house"/>
    <member type="way" ref="177508636" role="house"/>
    <member type="way" ref="177508739" role="house"/>
    <member type="way" ref="177508906" role="house"/>
    <member type="way" ref="177509099" role="house"/>
    <member type="way" ref="177509231" role="house"/>
    <member type="way" ref="177509369" role="house"/>
    <member type="way" ref="177509466" role="house"/>
    <member type="way" ref="177509497" role="house"/>
    <member type="way" ref="177509625" role="house"/>
    <member type="way" ref="177509643" role="house"/>
    <member type="way" ref="177509727" role="house"/>
    <member type="way" ref="177509770" role="house"/>
    <member type="way" ref="177509783" role="house"/>
    <member type="way" ref="177509806" role="house"/>
    <member type="way" ref="177509858" role="house"/>
    <member type="way" ref="177509942" role="house"/>
    <member type="way" ref="177509979" role="house"/>
    <member type="way" ref="177510000" role="house"/>
    <member type="way" ref="177510084" role="house"/>
    <member type="way" ref="177510153" role="house"/>
    <member type="way" ref="177510181" role="house"/>
    <member type="way" ref="177510222" role="house"/>
    <member type="way" ref="177510266" role="house"/>
    <member type="way" ref="177510273" role="house"/>
    <member type="way" ref="177510376" role="house"/>
    <member type="way" ref="177510471" role="house"/>
    <member type="way" ref="177510521" role="house"/>
    <member type="way" ref="177510592" role="house"/>
    <member type="way" ref="177510651" role="house"/>
    <member type="way" ref="177510672" role="house"/>
    <member type="way" ref="177510701" role="house"/>
    <member type="way" ref="177510868" role="house"/>
    <member type="way" ref="177510896" role="house"/>
    <member type="way" ref="177510915" role="house"/>
    <member type="way" ref="177510928" role="house"/>
    <member type="way" ref="177510949" role="house"/>
    <member type="way" ref="177511116" role="house"/>
    <member type="way" ref="177511120" role="house"/>
    <member type="way" ref="177511139" role="house"/>
    <member type="way" ref="177511159" role="house"/>
    <member type="way" ref="177511163" role="house"/>
    <member type="way" ref="177511168" role="house"/>
    <member type="way" ref="177511196" role="house"/>
    <member type="way" ref="177511204" role="house"/>
    <member type="way" ref="177511210" role="house"/>
    <member type="way" ref="177511313" role="house"/>
    <member type="way" ref="177511344" role="house"/>
    <member type="way" ref="177511354" role="house"/>
    <member type="way" ref="177511357" role="house"/>
    <member type="way" ref="177511362" role="house"/>
    <member type="way" ref="177511366" role="house"/>
    <member type="way" ref="177511368" role="house"/>
    <member type="way" ref="177511375" role="house"/>
    <member type="way" ref="177511380" role="house"/>
    <member type="way" ref="177511387" role="house"/>
    <member type="way" ref="177511403" role="house"/>
    <member type="way" ref="177511409" role="house"/>
    <member type="way" ref="177511414" role="house"/>
    <member type="way" ref="177511418" role="house"/>
    <member type="way" ref="177511608" role="house"/>
    <member type="way" ref="177511613" role="house"/>
    <member type="way" ref="177511618" role="house"/>
    <member type="way" ref="177511626" role="house"/>
    <member type="way" ref="177511629" role="house"/>
    <member type="way" ref="177511632" role="house"/>
    <member type="way" ref="177511637" role="house"/>
    <member type="way" ref="177511658" role="house"/>
    <member type="way" ref="177511682" role="house"/>
    <member type="way" ref="177511694" role="house"/>
    <tag k="name" v="Червоноселищна вулиця"/>
    <tag k="name:uk" v="uk-name"/>
    <tag k="name:ru" v="ru-name"/>
    <tag k="street:id" v="929"/>
    <tag k="type" v="street"/>
  </relation>
</osm>
