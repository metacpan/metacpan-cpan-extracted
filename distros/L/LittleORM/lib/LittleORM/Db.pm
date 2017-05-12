use strict;

package LittleORM::Db;

my $cached_read_dbh = [];
my $cached_write_dbh = [];

use Carp::Assert 'assert';

sub dbh_is_ok
{
	my $dbh = shift;

	my $rv = $dbh;

	if( $dbh )
	{
		unless( $dbh -> ping() )
		{
			$rv = undef;
		}
	}

	return $rv;
}

sub init
{
	my ( $self, $dbh ) = @_;

	unless( $dbh )
	{
		# non-object call ?
		$dbh = $self;
	}

	if( ref( $dbh ) eq 'HASH' )
	{
		my ( $rdbh, $wdbh ) = @{ $dbh }{ 'read', 'write' };
		assert( $rdbh and $wdbh );

		$cached_read_dbh = ( ref( $rdbh ) eq 'ARRAY' ? $rdbh : [ $rdbh ] );
		$cached_write_dbh = ( ref( $wdbh ) eq 'ARRAY' ? $wdbh : [ $wdbh ] );

	} else
	{
		# $cached_dbh = $dbh;
		# old way
		
		$cached_read_dbh = [ $dbh ];
		$cached_write_dbh = [ $dbh ];
	}
}

sub __get_rand_array_el
{
	my $arr = shift;
# 	return $arr -> [ 0 ]; # not very random


# sub rand_el
# {
# 	my $arr = shift;

	return $arr -> [ rand @{ $arr } ];

#}


# this method is tested to work:


# use strict;


# my @arr = ( 1 .. 10 );

# my %stats = ();

# foreach ( 1 .. 10000 )
# {
# 	$stats{ &rand_el( \@arr ) } ++;
# }

# while( my ( $k, $v ) = each %stats )
# {
# 	print $k, " => ", $v, "\n";
# }


# sub rand_el
# {
# 	my $arr = shift;

# 	return $arr -> [ rand @{ $arr } ];

# }

# 6 => 1023
# 3 => 1000
# 7 => 961
# 9 => 945
# 2 => 998
# 8 => 1040
# 1 => 1071
# 4 => 974
# 10 => 997
# 5 => 991
# eugenek@carbon:~$ perl /tmp/test.pl
# 6 => 995
# 3 => 979
# 7 => 984
# 9 => 1026
# 2 => 983
# 8 => 984
# 4 => 1008
# 1 => 1048
# 10 => 1021
# 5 => 972


}

sub get_dbh
{
	my $for_what = shift;

	my $rv = undef;

	if( $for_what eq 'write' )
	{
		$rv = &get_write_dbh();
	} else
	{
		$rv = &get_read_dbh();
	}
	return $rv;

}

sub get_read_dbh
{
	return &__get_rand_array_el( $cached_read_dbh );
}

sub get_write_dbh
{
	return &__get_rand_array_el( $cached_write_dbh );
}

sub dbq
{
	my ( $v, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = &get_read_dbh();
	}

	my $rv = undef;

	eval {
		$rv = $dbh -> quote( $v );
	};

	if( my $err = $@ )
	{
		assert( 0, $err );
	}

	return $rv;
}

sub getrow
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		warn( "(getrow) no DBH passed, failing back to write DBH" );
		$dbh = &get_write_dbh();
		# assert( 0, 'cant safely fall back to read dbh here' );
	}


	return $dbh -> selectrow_hashref( $sql );

}

sub prep
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		warn( "(prep) no DBH passed, failing back to write DBH" );
		$dbh = &get_write_dbh();
		# assert( 0, 'cant safely fall back to read dbh here' );
	}

	return $dbh -> prepare( $sql );
	
}

sub doit
{
	my ( $sql, $dbh ) = @_;

	unless( $dbh )
	{
		warn( "(doit) no DBH passed, failing back to write DBH" );
		$dbh = &get_write_dbh();
		#assert( 0, 'cant safely fall back to read dbh here too' );
	}

	return $dbh -> do( $sql );
}

sub errstr
{
	my $dbh = shift;

	return $dbh -> errstr();
}

sub nextval
{
	my ( $sn, $dbh ) = @_;

	unless( $dbh )
	{
		$dbh = &get_write_dbh();
	}

	my $sql = sprintf( "SELECT nextval(%s) AS newval", &dbq( $sn, $dbh ) );

	assert( my $rec = &getrow( $sql, $dbh ),
		sprintf( 'could not get new value from sequence %s: %s',
			 $sn,
			 &errstr( $dbh ) ) );

	return $rec -> { 'newval' };
}

42;
