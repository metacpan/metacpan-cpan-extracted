#!/usr/bin/perl -w

use strict;
use Test::More;
use Test::Exception;
$| = 1;

BEGIN
{
	plan skip_all => 'TODO: Adopt for Forst';
}

# =begin testing SETUP
use Test::Requires {
    'DateTime'                  => '0',
    'DateTime::Calendar::Mayan' => '0',
};



# =begin testing SETUP
{

  package My::DateTime;

  use Moose;
  extends qw( DateTime Moose::Object );

  use DateTime::Calendar::Mayan;

  has 'mayan_date' => (
      is        => 'ro',
      isa       => 'DateTime::Calendar::Mayan',
      init_arg  => undef,
      lazy      => 1,
      builder   => '_build_mayan_date',
      clearer   => '_clear_mayan_date',
      predicate => 'has_mayan_date',
  );

  sub new {
      my $class = shift;

      my $obj = $class->SUPER::new(@_);

      return $class->meta->new_object(
          __INSTANCE__ => $obj,
          @_,
      );
  }

  after 'set' => sub {
      $_[0]->_clear_mayan_date;
  };

  sub _build_mayan_date {
      DateTime::Calendar::Mayan->from_object( object => $_[0] );
  }
}



# =begin testing
{
my $dt = My::DateTime->new( year => 1970, month => 2, day => 24 );

can_ok( $dt, 'mayan_date' );
isa_ok( $dt->mayan_date, 'DateTime::Calendar::Mayan' );
is( $dt->mayan_date->date, '12.17.16.9.19', 'got expected mayan date' );

$dt->set( year => 2009 );
ok( ! $dt->has_mayan_date, 'mayan_date is cleared after call to ->set' );
}


done_testing;

