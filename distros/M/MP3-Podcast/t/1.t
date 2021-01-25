#!/usr/bin/perl

use lib '../lib';

use Test::More qw(no_plan);
BEGIN { use_ok('MP3::Podcast') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $pod = MP3::Podcast->new('/home/jmerelo/public_html/muzak','http://geneura.ugr.es/~jmerelo/muzak'); #Using dummy dirs
isa_ok( $pod, 'MP3::Podcast' );

my $dir = ( -d 't' )? 't':'.';
$pod = MP3::Podcast->new($dir,'http://animaadversa.es');
my $subdir = 'music';
my $rss =  $pod->podcast($subdir, "Anima Adversa: El Otro Yo");
isa_ok( $rss, 'XML::RSS' );
my $regex = qr/(Alter Ego|En tus Brazos)/;
like( $rss->{'items'}->[0]->{title}, $regex, "RSS" );
like( $rss->{'items'}->[1]->{title}, $regex, "RSS" );
is( scalar(@{$rss->{'items'}}), 2, 'RSS items' );

