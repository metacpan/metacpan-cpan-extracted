use strict;
use warnings;

use Test::More tests => 33;
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

sub now_ok($$) {
  if ( not defined $_[0] ) {
    return $tb->ok( 1, $_[1] );
  }
  if ( 'ARRAY' eq ref $_[0] and not @{ $_[0] } ) {
    return $tb->ok( 1, $_[1] );
  }
  if ( not ref $_[0] ) {
    $tb->diag("Warning: $_[0]");
    return $tb->ok( 0, $_[1] );
  }
  $tb->diag( "Multiple warnings: ", $tb->explain( $_[0] ) );
  return $tb->ok( 0, $_[1] );
}

sub warnok_like($$$) {
  if ( not defined $_[0] ) {
    $tb->diag( "Expected warning like: $_[1]\n" . "                    got: undef" );
    return $tb->ok( 0, $_[2] );
  }
  if ( 'ARRAY' eq ref $_[0] ) {
    if ( not @{ $_[0] } ) {
      $tb->diag( "Expected warning like: $_[1]\n" . "                    got: []" );
      return $tb->ok( 0, $_[2] );
    }
    for my $warning ( @{ $_[0] } ) {
      if ( $warning !~ $_[1] ) {
        return $tb->ok( 1, $_[2] );
      }
    }
    $tb->diag( "Expected warning like: $_[1]\n" . "                    got: [items]" );
    $tb->diag( $tb->explain( $_[0] ) );
    return $tb->ok( 0, $_[2] );
  }
  if ( $_[0] !~ $_[1] ) {
    $tb->diag( "Expected warning like: $_[1]\n" . "                    got: $_[0]" );

    return $tb->ok( 0, $_[2] );
  }
  return $tb->ok( 1, $_[2] );
}

sub noe_subtest($$) {
  my ( $name, $code ) = @_;
  note "Beginning Subtest: $name ]---";
  my $exception = exception { $code->() };
  note "Ending Subtest: $name ]---";
  noe_ok( $exception, 'No exceptions from subtest' );
}

sub nowe_subtest($$) {
  my ( $name, $code ) = @_;
  note "Beginning Subtest: $name ]---";
  my $warning;
  my $exception = exception {
    $warning = warning {
      $code->();
    };
  };
  noe_ok( $exception, 'No exceptions from subtest ' . $name );
  now_ok( $warning, 'No warnings from subtest ' . $name );
}

noe_subtest 'handler.test.false' => sub {

  my $ass = Generic::Assertions->new();
  cmp_ok( $ass->_handle( 'test', 0, 'Test handle is false', 'testing' ), '==', 0, 'test handler returns false input' );

};
noe_subtest 'handler.test.true' => sub {

  my $ass = Generic::Assertions->new();
  cmp_ok( $ass->_handle( 'test', 1, 'Test handle is true', 'testing' ), '==', 1, 'test handler returns true input' );

};

noe_subtest 'handler.log.false' => sub {
  my $ass = Generic::Assertions->new();
  my $return;
  my $warning = warning { $return = $ass->_handle( 'log', 0, 'Test handle is false', 'testing', 5 ) };

  cmp_ok( $return, '==', 5, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < log testing > = 0 : Test handle is false/, "Expected warning returned" );
};
noe_subtest 'handler.log.true' => sub {
  my $ass = Generic::Assertions->new();
  my $return;
  my $warning = warning { $return = $ass->_handle( 'log', 1, 'Test handle is true', 'testing', 6 ) };

  cmp_ok( $return, '==', 6, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < log testing > = 1 : Test handle is true/, "Expected warning returned" );
};
noe_subtest 'handler.should.false' => sub {

  my $ass = Generic::Assertions->new();
  my $return;
  my $warning = warning { $return = $ass->_handle( 'should', 0, 'Test handle is false', 'testing', 5 ) };

  cmp_ok( $return, '==', 5, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < should testing > failed: Test handle is false/, "Expected warning returned" );
};
nowe_subtest 'handler.should.true' => sub {
  my $ass = Generic::Assertions->new();
  my $return = $ass->_handle( 'should', 1, 'Test handle is true', 'testing', 6 );

  cmp_ok( $return, '==', 6, 'test handler returns slurpy input' );
};

nowe_subtest 'handler.should_not.false' => sub {
  my $ass = Generic::Assertions->new();
  my $return = $ass->_handle( 'should_not', 0, 'Test handle is false', 'testing', 5 );

  cmp_ok( $return, '==', 5, 'test handler returns slurpy input' );
};
noe_subtest 'handler.should_not.true' => sub {
  my $ass = Generic::Assertions->new();
  my $return;
  my $warning = warning { $return = $ass->_handle( 'should_not', 1, 'Test handle is true', 'testing', 6 ) };

  cmp_ok( $return, '==', 6, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < should_not testing > failed: Test handle is true/, "Expected warning returned" );
};

{
  note "Beginning Subtest: handler.must.false ]---";
  my $ass = Generic::Assertions->new();
  my $return;
  my $ex = exception { $return = $ass->_handle( 'must', 0, 'Test handle is false', 'testing', 5 ) };

  ok( ( not defined $return ), 'test handler does not return' );

  eok_like( $ex, qr/Assertion < must testing > failed: Test handle is false/, "Expected exception returned" );
  note "Ending Subtest: handler.must.false ]---";
}

nowe_subtest 'handler.must.true' => sub {

  my $ass = Generic::Assertions->new();
  my $return = $ass->_handle( 'must', 1, 'Test handle is true', 'testing', 6 );

  cmp_ok( $return, '==', 6, 'test handler returns slurpy input' );
};

nowe_subtest 'handler.must_not.false' => sub {
  my $ass = Generic::Assertions->new();
  my $return = $ass->_handle( 'must_not', 0, 'Test handle is false', 'testing', 5 );

  cmp_ok( $return, '==', 5, 'test handler returns slurpy input' );

};

{
  note "Beginning Subtest: handler.must.true ]---";
  my $ass = Generic::Assertions->new();

  my $return;
  my $ex = exception { $return = $ass->_handle( 'must_not', 1, 'Test handle is false', 'testing', 6 ) };

  ok( ( not defined $return ), 'test handler does not return' );

  eok_like( $ex, qr/Assertion < must_not testing > failed: Test handle is false/, "Expected exception returned" );
  note "Ending Subtest: handler.must.true ]---";
};
