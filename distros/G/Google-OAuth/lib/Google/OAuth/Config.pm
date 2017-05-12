package Google::OAuth::Config ;

use NoSQL::PL2SQL::DBI ;

our %test ;
my %client ;

$client{client_id} = 'Js6XzxwxR9KA0g0kkEdEFjPPyv9kNKLfmfUuhu3A' ;
$client{client_secret} = 'WWGG3mJ8PREkuYeWAykn4hRTog0ISAbC3DLJ4ZOt' ;
$client{redirect_uri} = 'XFygUanB0BYszi3ehzNxfJM5BBV6xkSm7CcKmEAo' ;
$client{dsn} = new NoSQL::PL2SQL::DBI 'googletokens' ;

$test{grantcode} = '1/fk7qwDysHKcwfa2S8ZKWTv2-nwTfxpPva3dzmujc_gQ' ;

BEGIN {
	use 5.008009;
	use strict;
	use warnings;
	
	require Exporter;
	
	our @ISA = qw( Exporter ) ;
	
	our %EXPORT_TAGS = ( 'all' => [ qw() ] );
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
	our @EXPORT = qw() ;
	our $VERSION = '0.01';
	}

sub setclient {
	return %client ;
	}

1;
