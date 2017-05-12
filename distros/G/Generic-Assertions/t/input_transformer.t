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
  note "Ending Subtest: $name ]---";
  noe_ok( $exception, 'No exceptions from subtest ' . $name );
  now_ok( $warning, 'No warnings from subtest ' . $name );
}

{

  package Boo;

  sub new {
    my ( $class, @args ) = @_;
    return bless {@args}, $class;
  }

  sub is_true {
    if ( $_[0]->value ) { return 1 }
    return;
  }
  sub value { return $_[0]->{value} }
}

sub mk_ass {
  return Generic::Assertions->new(
    -input_transformer => sub {
      my ( $name, $value ) = @_;
      return Boo->new( value => $value );
    },
    passfail => sub {
      return ( 0, "Test handle is false" ) unless $_[0]->is_true;
      return ( 1, "Test handle is true" );
    }
  );
}

noe_subtest 'handler.test.false' => sub {
  my $ass = mk_ass;
  cmp_ok( $ass->test( passfail => 0 ), '==', 0, 'test handler returns false input' );

};
noe_subtest 'handler.test.true' => sub {
  my $ass = mk_ass;
  cmp_ok( $ass->test( passfail => 1 ), '==', 1, 'test handler returns true input' );
};

noe_subtest 'handler.log.false' => sub {
  my $ass = mk_ass;
  my $return;
  my $warning = warning { $return = $ass->log( passfail => 0 ) };

  cmp_ok( $return->value, '==', 0, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < log passfail > = 0 : Test handle is false/, "Expected warning returned" );
};
noe_subtest 'handler.log.true' => sub {
  my $ass = mk_ass;
  my $return;
  my $warning = warning { $return = $ass->log( passfail => 1 ) };

  cmp_ok( $return->value, '==', 1, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < log passfail > = 1 : Test handle is true/, "Expected warning returned" );
};
noe_subtest 'handler.should.false' => sub {
  my $ass = mk_ass;
  my $return;
  my $warning = warning { $return = $ass->should( passfail => 0 ) };

  cmp_ok( $return->value, '==', 0, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < should passfail > failed: Test handle is false/, "Expected warning returned" );
};
nowe_subtest 'handler.should.true' => sub {
  my $ass = mk_ass;
  my $return = $ass->should( passfail => 1 );

  cmp_ok( $return->value, '==', 1, 'test handler returns slurpy input' );
};

nowe_subtest 'handler.should_not.false' => sub {
  my $ass = mk_ass;
  my $return = $ass->should_not( passfail => 0 );

  cmp_ok( $return->value, '==', 0, 'test handler returns slurpy input' );
};
noe_subtest 'handler.should_not.true' => sub {
  my $ass = mk_ass;
  my $return;
  my $warning = warning { $return = $ass->should_not( passfail => 1 ) };

  cmp_ok( $return->value, '==', 1, 'test handler returns slurpy input' );

  warnok_like( $warning, qr/Assertion < should_not passfail > failed: Test handle is true/, "Expected warning returned" );
};

{
  note "Beginning Subtest: handler.must.false ]---";
  my $ass = mk_ass;
  my $return;
  my $ex = exception { $return = $ass->must( passfail => 0 ) };

  ok( ( not defined $return ), 'test handler does not return' );

  eok_like( $ex, qr/Assertion < must passfail > failed: Test handle is false/, "Expected exception returned" );
  note "Ending Subtest: handler.must.false ]---";
}

nowe_subtest 'handler.must.true' => sub {

  my $ass = mk_ass;
  my $return = $ass->must( passfail => 1 );

  cmp_ok( $return->value, '==', 1, 'test handler returns slurpy input' );
};

nowe_subtest 'handler.must_not.false' => sub {
  my $ass = mk_ass;
  my $return = $ass->must_not( passfail => 0 );

  cmp_ok( $return->value, '==', 0, 'test handler returns slurpy input' );

};

{
  note "Beginning Subtest: handler.must.true ]---";
  my $ass = mk_ass;

  my $return;
  my $ex = exception { $return = $ass->must_not( passfail => 1 ) };

  ok( ( not defined $return ), 'test handler does not return' );

  eok_like( $ex, qr/Assertion < must_not passfail > failed: Test handle is true/, "Expected exception returned" );
  note "Ending Subtest: handler.must.true ]---";
};
