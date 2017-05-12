use strict;

package LittleORM::Db::Connector;
use Moose;

has 'do_dbh_caching' => ( is => 'ro', isa => 'Bool', default  => 1 );

has 'connect_code'       => ( is => 'ro', isa => 'CodeRef' );
has 'connect_read_code'  => ( is => 'ro', isa => 'CodeRef' );
has 'connect_write_code' => ( is => 'ro', isa => 'CodeRef' );

has '__cached_read_dbh'  => ( is => 'rw', isa => 'DBI::db' );
has '__cached_write_dbh' => ( is => 'rw', isa => 'DBI::db' );

use Carp::Assert 'assert';
use LittleORM::Db ();

sub get_dbh
{
	my ( $self, $for_what ) = @_;

	my $rv = undef;

	if( $for_what eq 'read' )
	{
		$rv = $self -> get_read_dbh();

	} elsif( $for_what eq 'write' )
	{
		$rv = $self -> get_write_dbh();

	} else
	{
		assert( 0, 'for what: ' . $for_what );
	}

	assert( &LittleORM::Db::dbh_is_ok( $rv ) );

	return $rv;
}

sub get_read_dbh
{
	my $self = shift;

	my $rv = undef;

	if( $self -> do_dbh_caching() )
	{
		if( my $t = &LittleORM::Db::dbh_is_ok( $self -> __cached_read_dbh() ) )
		{
			$rv = $t;
		} else
		{
			$rv = $self -> __do_actually_connect_read_dbh();
			$self -> __cached_read_dbh( $rv );
		}

	} else
	{
		$rv = $self -> __do_actually_connect_read_dbh();
	}

	return $rv;
}

sub get_write_dbh
{
	my $self = shift;

	my $rv = undef;

	if( $self -> do_dbh_caching() )
	{
		if( my $t = &LittleORM::Db::dbh_is_ok( $self -> __cached_write_dbh() ) )
		{
			$rv = $t;
		} else
		{
			$rv = $self -> __do_actually_connect_write_dbh();
			$self -> __cached_write_dbh( $rv );
		}

	} else
	{
		$rv = $self -> __do_actually_connect_write_dbh();
	}

	return $rv;
}

sub __do_actually_connect_read_dbh
{
	my $self = shift;

	my $code = ( $self -> connect_read_code()
		     or
		     $self -> connect_code() );

	assert( ref( $code ) eq 'CODE' );

	my $rv = $code -> ();

	return $rv;
}

sub __do_actually_connect_write_dbh
{
	my $self = shift;

	my $code = ( $self -> connect_write_code()
		     or
		     $self -> connect_code() );

	assert( ref( $code ) eq 'CODE' );

	my $rv = $code -> ();

	return $rv;
}

"yz";
