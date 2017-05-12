package Forex;

use JSON::XS;
use DateTime;
use LWP::UserAgent;

our $LASTERROR = undef;

$FOREX::VERSION  = '1.3';

=pod

=head1 NAME

Forex - Historic Foreign Exchange Rates from Open Exchange Rates 

=head1 VERSION

1.3

=head1 SYNOPSIS

 use Forex;
 
 my $forex = new Forex( 'APP_ID' => $app_id, 'BASE' => 'USD');
 
 #__fetch and initialize daily rates from $from_date to $to_date in yyyy-mm-dd 
 $forex->get_rates_from ( $from_date, $to_date );

 #___ fetches rates for $date (yyyy-mm-dd)
 $forex->get_rates( $date );
	 
 #___ fetches reates for today 
 $forex->get_rates();
	
 #___ gives AUD on 2012-09-01 in USD Base currency
 $usd = $forex->get_rate_of ( 'AUD', '2012-09-01' );  
 
 if ($Forex::LASTERROR )
    { print "\n Something went wrong" , $oxr->last_error_message(); }  

=head1 DESCRIPTION

=head1 METHODS

=head2 Constructors

=head3 new Forex()

returns new Forex object with defaults values for 

=over 2

=item OXR_HOME = 'http://openexchangerates.org',

=item API_HOOK = 'api',

=item APP_ID   = 'temp-e091fc14b3884a516d6cc2c299a',

=item BASE     = 'USD'

=back

 my $oxe = new Forex( OXR_HOME => 'https://openexchangerates.org',
                      API_HOOK => 'api',
                      APP_ID   => 'temp-e091fc14b3884a516d6cc2c299a',
                      BASE     => 'AUD');

=cut

sub new {
	my $class = shift;
	my $self = {@_};
	bless $self, $class;
	$self->{ 'OXR_HOME' } = 'http://openexchangerates.org'     unless defined ($self->{'OXR_HOME'});
	$self->{ 'API_HOOK' } = 'api'                              unless defined ($self->{'API_HOOK'});
	$self->{ 'APP_ID'   } = 'temp-e091fc14b3884a516d6cc2c299a' unless defined ($self->{APP_ID});
	$self->{ 'BASE'     } = 'USD'                              unless defined ($self->{'BASE'});
	return $self;
}

=pod

=head3 get_rate_of( $currency, <$date> )

This method returns forex rate for C<$currency> on $date in BASE currency, $date should be in C<yyyy-mm-dd> format.

my $AUD = $oxr->get_rate_of( 'AUD' , '2012-09-10' );

=cut

sub get_rate_of {
	my ($self, $currency, $date ) = @_;

	if (!$date)
		{ my $_d = DateTime->now();
		  $date = join "-",($_d->year, $_d->month, $_d->day); }
		  
	if ($date !~ m/-/)
		{ $LASTERROR = 1;
		  $self->{ERROR} = 'date parameter not is in yyyy-mm-dd format';
		  return undef;                                               }

	if( !$self->{ 'CURRENCIES'} || !$self->{'CURRENCIES'}->{$date})
	  { $self->get_rates( $date ); }
		  
	return $self->{ 'CURRENCIES' }->{ $currency }->{ $date };
}

sub _fetch_data {
	my ($self) = @_;
	my ($response);
		   
	if ( !$self->{'LWP_OBJ'} )
		{  $self->{ 'LWP_OBJ' } = new LWP::UserAgent();
		   $self->{ 'LWP_OBJ' }->timeout( $self->{'TIMEOUT'} );  }

	      $response = $self->{'LWP_OBJ'}->get( $self->{ 'REQUEST_URL' } );

	if ( $response->is_success )
	   { $self->{ 'CONTENT' } = decode_json $response->decoded_content; $LASTERROR = undef; }
	else
		{ $self->{ 'ERROR'} = decode_json $response->decoded_content;
		  $LASTERROR = 1; }
		
	delete $self->{ 'REQUEST_URL' };

	1;
}

=pod

=head3 get_rates_from ( $from_date , $to_date ) 

downloads and fills CURRENCIES hash for $from_date to $to_date
both dates should be in C<yyyy-mm-dd> formate

=cut

sub get_rates_from {
	my ($self, $from , $to) = @_;
	my ( $from_dt, $to_dt );
	
	if ( $from !~ m/-/ && $to !~ m/-/ )
		{ $self->{ERROR} = "to date or from date not in yyyy-mm-dd formate";
		  $LASTERROR = 1; 
		  return undef;                                                    }
		
	   ( $y, $m , $d ) = split '-' , $from;
	     $from_dt = new DateTime( year => $y, month => $m , day => $d );
	   ( $y, $m , $d ) = split '-' , $to;
	     $to_dt   = new DateTime( year => $y, month => $m , day => $d );
	
	while ( DateTime->compare( $from_dt , $to_dt ) )
	{ $self->get_rates( $from_dt->ymd('-') );
	  $from_dt->add( days => 1 );	              }
	
	1;
}

=pod

=head3 get_rates ( <$day> ) 

downloads and fills in values for all currencies in the CURRENCIES hash for given C<$day>
$day should be in C<yyyy-mm-dd> formate if $day is skipped , it uses C<todays date>,

=cut

sub get_rates {
	my ($self, $day) = @_;
	my ($request_day, $response_day );

	if ( !$day )
	{ $request_day = DateTime->now();
	  $request_day = new DateTime ( year  => $request_day->year,
				        month => $request_day->month,
			                day   => $request_day->day );     	 }
	else
	   { my ( $y, $m , $d ) = split '-' , $day;
	     $request_day = new DateTime( year => $y, month => $m , day => $d ); }
	
	if ( !$request_day )
	   { $LASTERROR = 1; $self->{ERROR} = "request day is not defined ";   return undef;}
	if ( !$self->{'OXR_HOME'} )
	   { $LASTERROR = 1; $self->{ERROR} = "OXR HOME is not defined ";      return undef;}
	if ( !$self->{'API_HOOK'} )
	   { $LASTERROR = 1; $self->{ERROR} = "API HOOK is not defined ";      return undef;}
	if ( !$self->{'APP_ID'} )
	   { $LASTERROR = 1; $self->{ERROR} = "APP ID is not defined ";        return undef;}
	if ( !$self->{'BASE'} )
	   { $LASTERROR = 1; $self->{ERROR} = "BASE Currency is not defined "; return undef;}
	   	   	   	   	
	$self->{'REQUEST_URL'} = join "/", ( $self->{ 'OXR_HOME'},
  				             $self->{'API_HOOK' },
	  				     'historical'        ,
	  				     $request_day->ymd('-') . '.json' );
 	$self->{'REQUEST_URL'} .= '?app_id='   . $self->{'APP_ID'}
			       .   "&base="    . $self->{'BASE'} ;
	
	$self->_fetch_data();
		
	if ( $self->{ CONTENT } )
	{ $response_day = DateTime->from_epoch( epoch => $self->{ 'CONTENT' }->{ 'timestamp' } );
	  $response_day = new DateTime (	year  => $response_day->year,
	  					month => $response_day->month,
	  	  			        day   => $response_day->day );          }

	if ( DateTime->compare($request_day , $response_day) )
	{ $LASTERROR = 1; $self->{ERROR} = "Request Date is not equal to Received Date"; }
			
	my $hash = $self->{ 'CONTENT' }->{ 'rates' };	
	map {	$self->{ 'CURRENCIES' } { $_ } { $response_day->ymd() } = $hash->{ $_}; } keys( %$hash );	
	delete $self->{ 'CONTENT' };
								
}

=pod

=head3 get_currency_symbols()

this method downloads and initializes all currency symbols from openexchangerates site.
this method should be run before either C<get_rates> or C<get_rates_from>

=cut

sub get_currency_symbols {
	my ($self) = @_;
	my $currenciesJSON = 'currencies.json';

	if ( !$self->{'OXR_HOME'} )
	   { $LASTERROR = 1; $self->{ERROR} = "OXR HOME is not defined ";      return undef;}
	if ( !$self->{'API_HOOK'} )
	   { $LASTERROR = 1; $self->{ERROR} = "API HOOK is not defined ";      return undef;}

         $self->{'REQUEST_URL'} = join "/" , ( $self->{ 'OXR_HOME'},
				               $self->{ 'API_HOOK'},
		   			       $currenciesJSON   );  
        #_____ fetching data	
        $self->_fetch_data();
	
	my $hash = $self->{ 'CONTENT' };
	map {	$self->{ 'CURRENCIES' } { $_ } { 'description' } = $hash->{ $_}; } keys( %$hash );
	delete $self->{ 'CONTENT' };	   
}

=pod

=head3 base_currency( <$BASE_CURRENCY> )

sets BASE currency so that succeeding request will request the rates with base currency as specified by $BASE_CURRENCY.
if the parameter is omitted it return the current BASE_CURRENCY value;

Note: you will have to flush the $CURRENCIES hash if you change the BASE currency. with C<flush_values()>

=cut

sub base_currency { 	return ($_[1]) ? $_[0]->{ 'BASE'    } = $_[1] : $_[0]->{ 'BASE'     }; }

=pod

=head3 oxr_home ( <$OXR_HOME> )

sets OXR_HOME parameter to $OXR_HOME value , if the parameter is omitted it returns the current value of the OXR_HOME.
OXR_HOME value should cuntaion "http://" .

Note: you could you it to change the default "http://" to "https://" if you have enterprise APP_ID

=cut

sub oxr_home	   { 	return ($_[1]) ? $_[0]->{ 'OXR_HOME'} = $_[1] : $_[0]->{ 'OXR_HOME' }; }

=pod

=head3 app_id ( <$APP_ID> )

sets app_id for all succeeding requests. return current app_id if the parameter is omitted.

=cut

sub app_id	  { 	return ($_[1]) ? $_[0]->{ 'APP_ID'  } = $_[1] : $_[0]->{ 'APP_ID'   }; }

=pod

=head3 get_currencies()

returns all the currencies in the currencies hash

=cut

sub get_currencies { return  keys ( %{$_[0]->{ 'CURRENCIES'}}); }

=pod

=head3 last_error()

returns last error object as returned by Open Exchange Rates API

=cut

sub last_error    {  return  $_[0]->{ 'ERROR' }; }

=pod

=head3 last_error_message ()

returns last error message 

=cut

sub last_error_message {
	my $self = shift; 
	return ($self->{ ERROR }->{message}) ? $self->{ERROR}->{message} : $self->{ERROR}; 
}
1;

=pod

=head3 ERROR

on errors module sets $LASTERROR global variable which can be accessed by $Forex::LASTERROR.
And error message can be accessed via last_error_message() or last_error()

=head3 KNOWN BUGS


=head3 SUPPORT

please submit known issues or bugs to mail4bhavin@yahoo.com

=head3 AUTHOR

Bhavin Patel

=head3 COPYRIGHT AND LICENSE

This Software is free to use , licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut


