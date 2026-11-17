#!/usr/bin/env perl
# The example suites the distribution ships under share/suites (k22, ADR 0010).
# Claims: every shipped suite loads -- lint is part of loading, so each case's
# self-check and both mock runs hold; the set is the one ADR 0010 lists and
# covers a device, a world without devices (handlers), generated input and an
# image on a user message with the answer world sehen (k27), and a typed
# answer world plugin, the invented dragon roost (k43), and a suite in the case
# DSL whose cases a seeded generate block builds, the invented beacon chain (k50),
# which exports to format 2 with the same digest; each suite says where it comes
# from and under which license; and through the
# command line, mock-solution passes every case and mock-text fails every case
# (exit 0 and 1). Runs on the share/ next to t/ -- the checkout, and the build
# directory under dzil test -- without a network.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Tiny qw( path );
use Test::More;

use Holmgang::CLI qw( cli );
use Langertha::Holmgang::Loader;

my $root = path( $FindBin::Bin, '..', 'share', 'suites' );
ok( -d $root, 'share/suites is there' ) or BAIL_OUT('no share/suites');

my @dirs = sort grep { -f $_->child('suite.yaml') || -f $_->child('suite.pl') } $root->children;
is_deeply( [ map { $_->basename } @dirs ], [qw( demo-beacons demo-haystack demo-lamp demo-linux demo-roost demo-sehen )], 'the shipped suites' );

my $loader = Langertha::Holmgang::Loader->new;
my %suite;
for my $dir ( @dirs ) {
  my $s = eval { $loader->load("$dir") };
  ok( $s, $dir->basename.' loads (lint included)' ) or diag $@;
  next unless $s;
  $suite{ $s->id } = $s;
  is( $s->license, 'Perl_5', '... license Perl_5' );
  like( $s->source && $s->source->{authors}, qr/Torsten Raudssus/, '... author in source' );
  my $head = ( -f $dir->child('suite.pl') ? $dir->child('suite.pl') : $dir->child('suite.yaml') )->slurp_utf8;
  like( $head, qr/^# Origin: written for this distribution;.*invented/ms, '... origin in the header' );
  like( $head, qr/^# License: same terms as Perl itself/m, '... license in the header' );
}

# what each one is there to show
{
  my %types = map {
    my $s = $_;
    ( $s->id => { map { ( ref $_ eq 'HASH' && $_->{type} ) ? ( $_->{type} => 1 ) : () } map { values %{ $_->state } } @{ $s->cases } } )
  } values %suite;
  ok( $types{'demo-linux'}{linux}, 'demo-linux: a linux device' );
  is_deeply( $types{'demo-lamp'}, {}, 'demo-lamp: no typed entry, a world without devices' );
  my $c = $suite{'demo-haystack'} && $suite{'demo-haystack'}->cases->[0];
  is( ref( $c && $c->messages->[0]{content} ), 'ARRAY', 'demo-haystack: the case keeps its generate spec' );
  like( $c && $c->prompt_messages->[0]{content}, qr/thumb-render\[\d+\]: ERROR: .*disk quota exceeded/,
    '... and the model gets the generated journal with the planted line' );
  ok( $types{'demo-roost'}{roost}, 'demo-roost: the answer world roost' );
  is_deeply( [ sort map { $_->{simulator} } @{ $suite{'demo-roost'} ? $suite{'demo-roost'}->tools : [] } ], [ ('roost') x 3 ],
    '... all three tools are the world\'s' );
  my $img = $suite{'demo-sehen'} && $suite{'demo-sehen'}->cases->[0];
  ok( $types{'demo-sehen'}{sehen}, 'demo-sehen: the answer world sehen' );
  ok( $img && $img->has_images, '... a user message with an image' );
  is_deeply( [ map { @{$_}{qw( media_type width height )} } values %{ $img ? $img->image_files : {} } ], [ 'image/png', 770, 160 ],
    '... the shipped PNG' );
  my $b = $suite{'demo-beacons'};
  ok( -f $root->child( 'demo-beacons', 'suite.pl' ), 'demo-beacons: a suite.pl, the case DSL' );
  is_deeply( $types{'demo-beacons'}, {}, '... a world without devices' );
  is_deeply( [ map { $_->id } @{ $b ? $b->cases : [] } ], [qw( light-01 light-02 light-03 )], '... three generated cases' );
  my $other = Langertha::Holmgang::Loader->new( seeds => { 'demo-beacons' => 7 } )->load( $root->child('demo-beacons')->stringify );
  isnt( join( '|', map { $_->title } @{ $other->cases } ), join( '|', map { $_->title } @{ $b ? $b->cases : [] } ),
    '... another seed, other hills' );
  my $tmp = Path::Tiny->tempdir;
  my $out = Langertha::Holmgang::Loader->new->export( $root->child('demo-beacons')->stringify, "$tmp" );
  is( Langertha::Holmgang::Loader->new->load($out)->digest, $b && $b->digest, '... its YAML export is the same suite' );
}

# through the command line, as a user runs them
my @suite_args = map { ( '--suite', "$_" ) } @dirs;
{
  my ( $code, $out, $err ) = cli( 'lint', "$root" );
  is( $code, 0, 'holmgang lint share/suites: exit 0' ) or diag $out.$err;
  like( $out, qr/^6 suites: 6 ok, 0 refused$/m, '... 6 ok' );
}
{
  my ( $code, $out, $err ) = cli( 'run', @suite_args, '--target', 'mock-solution' );
  is( $code, 0, 'run --target mock-solution: exit 0' ) or diag $out.$err;
  my @lines = $out =~ /^demo-\S+ \S+ #1 (\w+)$/mg;
  is( scalar @lines, 10, '... ten cases run' );
  is_deeply( [ grep { $_ ne 'passed' } @lines ], [], '... every one passed' );
}
{
  my ( $code, $out, $err ) = cli( 'run', @suite_args, '--target', 'mock-text' );
  is( $code, 1, 'run --target mock-text: exit 1' ) or diag $out.$err;
  my @lines = $out =~ /^demo-\S+ \S+ #1 (\w+)$/mg;
  is( scalar @lines, 10, '... ten cases run' );
  is_deeply( [ grep { $_ ne 'failed' } @lines ], [], '... every one failed' );
}

done_testing;
