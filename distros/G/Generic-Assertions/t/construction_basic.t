use strict;
use warnings;

use Test::More tests => 5;
use Test::Warnings qw( warning );
use Test::Fatal qw( exception );

# FILENAME: construction.t
# CREATED: 10/19/14 15:57:49 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic construction

use Generic::Assertions;
my $tb = Test::Builder->new();

sub noe_ok($$) {
  if ( not defined $_[0] ) {
    return $tb->ok( 1, $_[1] );
  }
  $tb->diag("Exception: $_[0]");
  return $tb->ok( 0, $_[1] );
}

sub eok_like($$$) {
  if ( not defined $_[0] ) {
    $tb->diag( "Expected exception like: $_[1]\n" . "                    got: undef" );
    return $tb->ok( 0, $_[2] );
  }
  if ( $_[0] !~ $_[1] ) {
    $tb->diag( "Expected exception like: $_[1]\n" . "                    got: $_[0]" );

    return $tb->ok( 0, $_[2] );
  }
  return $tb->ok( 1, $_[2] );
}

noe_ok( exception { my $ass = Generic::Assertions->new() }, 'No args => no problem' );

eok_like( exception { my $ass = Generic::Assertions->new('foo') }, qr/even/, 'Odd args bad' );

eok_like( exception { my $ass = Generic::Assertions->new( x => 'y' ) }, qr/must be a CodeRef/, 'two args badder' );
eok_like( exception { my $ass = Generic::Assertions->new( 'foo', 'foo', 'foo' ) }, qr/even/, 'Three args bad' );
