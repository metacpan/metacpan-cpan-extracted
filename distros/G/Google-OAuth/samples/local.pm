package local ;
use Google::OAuth ;

sub Google::OAuth::setclient {
	my %client = Google::OAuth::Config->setclient ;
	$client{client_secret} = 'xAtN' ;
	$client{dsn}->connect( 'DBI:mysql:'.$dbname, @login ) ;
	Google::OAuth::Client->setclient( %client ) ;
	}

1
