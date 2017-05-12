#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

use_ok( 'HTML::Bare', qw/htmlin/ );

my $xml;
my $root;
my $simple;

( $xml, $root, $simple ) = reparse( "<xml><node>val</node></xml>" );
is( $root->{xml}->{node}->{value}, 'val', 'normal node value reading' );
is( $simple->{node}, 'val', 'simple - normal node value reading' );

( $xml, $root, $simple ) = reparse( "<xml><node/></xml>" );
is( ref( $root->{xml}->{node} ), 'HASH', 'existence of blank node' );
is( $simple->{node}, '', 'simple - existence of blank node' );

( $xml, $root, $simple ) = reparse( "<xml><node att=12>val</node></xml>" );
is( $root->{xml}->{node}->{att}->{value}, '12', 'reading of attribute value' );
is( $simple->{node}{att}, '12', 'simple - reading of attribute value' );

( $xml, $root, $simple ) = reparse( "<xml><node att=\"12\">val</node></xml>" );
is( $root->{xml}->{node}->{att}->{value}, '12', 'reading of " surrounded attribute value' );
is( $simple->{node}{att}, '12', 'simple - reading of " surrounded attribute value' );

( $xml, $root, $simple ) = reparse( "<xml><node att>val</node></xml>" );
is( $root->{xml}{node}{att}{value}, '1', "reading of value of standalone attribute" );
is( $simple->{node}{att}, '1', "simple - reading of value of standalone attribute" );
    
( $xml, $root, $simple ) = reparse( "<xml><node><![CDATA[<cval>]]></node></xml>" );
is( $root->{xml}->{node}->{value}, '<cval>', 'reading of cdata' );
is( $simple->{node}, '<cval>', 'simple - reading of cdata' );

( $xml, $root, $simple ) = reparse( "<xml><node>a</node><node>b</node></xml>" );
is( $root->{xml}->{node}->[1]->{value}, 'b', 'multiple node array creation' );
is( $simple->{node}[1], 'b', 'simple - multiple node array creation' );

( $xml, $root, $simple ) = reparse( "<xml><multi_node/><node>a</node></xml>" );
is( $root->{xml}->{node}->[0]->{value}, 'a', 'use of multi_' );
is( $simple->{node}[0], 'a', 'simple - use of multi_' );

# note output of this does not work
( $xml, $root ) = new HTML::Bare( text => "<xml><node>val<a/></node></xml>" );
is( $root->{xml}->{node}->{value}, 'val', 'basic mixed - value before' );
#is( $simple->{xml}{node}[0], 'val', 'simple - basic mixed - value before' );

# note output of this does not work
( $xml, $root ) = new HTML::Bare( text => "<xml><node><a/>val</node></xml>" );
is( $root->{xml}->{node}->{value}, 'val', 'basic mixed - value after' );

( $xml, $root, $simple ) = reparse( "<xml><!--test--></xml>",1  );
is( $root->{xml}->{comment}, 'test', 'loading a comment' );

# test node addition
( $xml, $root ) = new HTML::Bare( text => "<xml></xml>" );
$xml->add_node( $root, 'item', name => 'bob' );
is( ref( $root->{'item'}[0]{'name'} ), 'HASH', 'node addition' );
is( $root->{'item'}[0]{'name'}{'value'}, 'bob', 'node addition' );

# test cyclic equalities
cyclic( "<xml><b><!--test--></b><c/><c/></xml>", 'comment' );
cyclic( "<xml><a><![CDATA[cdata]]></a></xml>", 'cdata' ); # with cdata

my $text = '<xml><node>checkval</node></xml>';
( $xml, $root ) = new HTML::Bare( text => $text );
my $i = $root->{'xml'}{'node'}{'_i'}-1;
my $z = $root->{'xml'}{'node'}{'_z'}-$i+1;
#is( substr( $text, $i, $z ), '<node>checkval</node>', '_i and _z vals' );

# saving test
( $xml, $root ) = HTML::Bare->new( file => 't/test.xml' );
$xml->save();

sub reparse {
  my $text = shift;
  my $nosimp = shift;
  my ( $xml, $root ) = new HTML::Bare( text => $text );
  my $a = $xml->html( $root );
  ( $xml, $root ) = new HTML::Bare( text => $a );
  my $simple = $nosimp ? 0 : htmlin( $text );
  return ( $xml, $root, $simple );
}

sub cyclic {
  my ( $text, $name ) = @_;
  ( $xml, $root ) = new HTML::Bare( text => $text );
  my $a = $xml->html( $root );
  ( $xml, $root ) = new HTML::Bare( text => $a );
  my $b = $xml->html( $root );
  is( $a, $b, "cyclic - $name" );
}

# test bad closing tags
# we need to a way to ensure that something dies... ?
