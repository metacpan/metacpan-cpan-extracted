package Device::Nest;

use warnings;
use strict;
use 5.006_001; 

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::Nest ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw( new 
    fetch_Auth_Token                fetch_Thermostat_Designation    fetch_Ambient_Temperature_C 
    fetch_Target_Temperature_C      fetch_Target_Temperature_high_C fetch_Target_Temperature_low_C 
    fetch_Away_Temperature_low_C    fetch_Ambient_Temperature_F     fetch_Away_Temperature_low_F 
    fetch_Away_Temperature_high_F   fetch_Target_Temperature_low_F  fetch_Target_Temperature_F 
    fetch_Target_Temperature_high_F fetch_Temperature_Scale         fetch_Locale fetch_Name 
    fetch_Long_Name fetch_HVAC_Mode fetch_SW_Version                fetch_Away_State  
    fetch_Country_Code              fetch_Can_Cool                  fetch_Can_Heat
    fetch_Has_Fan                   fetch_Is_Online                 fetch_Is_Using_Emergency_Heat
    set_Target_Temperature_C        set_Target_Temperature_F        set_Target_Temperature_high_C
    set_Target_Temperature_low_C    set_Target_Temperature_high_F   set_Target_Temperature_low_F
    set_Away_State
    ) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT    = qw( $EXPORT_TAGS{'all'});

BEGIN
{
  if ($^O eq "MSWin32"){
    use LWP::UserAgent;
    use JSON qw(decode_json encode_json);
    use Time::HiRes qw/gettimeofday/;
    use Data::Dumper;
  } else {
    use LWP::UserAgent;
    use JSON qw(decode_json encode_json);
    use Time::HiRes qw/gettimeofday/;
    use Data::Dumper;
  }
}


=head1 NAME

Device::Nest - Methods for wrapping the Nest API calls so that they are 
               accessible via Perl

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

#*****************************************************************

=head1 SYNOPSIS

 This module provides a Perl interface to a Nest Thermostat via the following 
 methods:
   - new
   - connect
   - fetch_Ambient_Temperature
   - fetch_Designation

 In order to use this module, you will require a Nest thermostat installed in 
 your home as well.  You will also need your ClientID and ClientSecret provided
 by Nest when you register as a developper at https://developer.nest.com.  
 You will aos need an access code which can be obtained at 
 https://home.nest.com/login/oauth2?client_id=CLIENT_ID&state=FOO
 Your authorization code will be obtained and stored in this module when you
 call it.

 The module is written entirely in Perl and has been developped on Raspbian Linux.

=head1 SAMPLE CODE

    use Device::Nest;

    $my_Nest = Device::Nest->new($ClientID,$ClientSecret,$code,$phrase,$debug);

    $my_Nest->connect();
  
    undef $my_Nest;


 You need to get an authorization code by going to https://home.nest.com/login/oauth2?client_id=CLIENT_ID&state=FOO
 and specifying your client ID in the URL along with a random string for state
 
 Use this code, along with your ClientID and ClientSecret to get an authorization code
 by using the 'connect' function below.  
 
 From now on, all you need is your auth_token
 


=head2 EXPORT

 All by default.


=head1 SUBROUTINES/METHODS

=head2 new - the constructor for a Nest object

 Creates a new instance which will be able to fetch data from a unique Nest 
 sensor.

 my $Nest = Device::Nest->new($ClientID, $ClientSecret, $phrase, $debug);

   This method accepts the following parameters:
     - $ClientID     : Client ID for the account - Required 
     - $ClientSecret : Secret key for the account - Required
     - $auth_token   : authentication token to access the account - Required 
     - $debug        : enable or disable debug messages (disabled by default - Optional)

 Returns a Nest object if successful.
 Returns 0 on failure
=cut
sub new {
    my $class = shift;
    my $self;
    
    $self->{'ua'}             = LWP::UserAgent->new(max_redirect=>3,requests_redirectable=>['GET','HEAD','PUT']);
    $self->{'ClientID'}       = shift;
    $self->{'ClientSecret'}   = shift;
    $self->{'PIN_code'}       = shift;
    $self->{'auth_token'}     = shift;
    $self->{'debug'}          = shift;
    $self->{'last_code'}      = '';
    $self->{'last_reason'}    = '';
    $self->{'device_url'}     = "https://developer-api.nest.com/devices.json?auth=".$self->{'auth_token'};
	$self->{'last_exec_time'} = 0;
    
    if (!defined $self->{'debug'}) {
      $self->{'debug'} = 0;
    }
    
    if ((!defined $self->{'ClientID'}) || (!defined $self->{'ClientSecret'}) || (!defined $self->{'PIN_code'}) || (!defined $self->{'auth_token'})) {
      print "Nest->new(): ClientID, ClientSecret, PIN_code and auth_token are REQUIRED parameters.\n";
      return 0;
    }
    
    bless $self, $class;
    
    return $self;
}


#*****************************************************************

=head2 fetch_Auth_Token - generates and displays the auth_token 

 This function will display the authenticaton token for the PIN code
 provided.  This can only be done once per PIN code.  Pleas make sure
 to note and store your auth code since it will be the only thing requiired
 for all other API calls.

   $Nest->fetch_Auth_Token();
 
 This method accepts no parameters
 
 Returns 1 on success and prints auth_token
 Returns 0 on failure
=cut
sub fetch_Auth_Token {
	my $self       = shift;
	my $auth_token = '';
	
    # Submit request for authentiaction token.
    my $response = $self->{'ua'}->post('https://api.home.nest.com/oauth2/access_token',
          { code          => $self->{'PIN_code'},
        	grant_type    => 'authorization_code', 
        	client_id     => $self->{'ClientID'},
        	client_secret => $self->{'ClientSecret'},
          }
        );
    
    $self->{'last_code'}   = $response->code;
    
    if($response->is_success) {
      if ($response->content =~ /\"access_token\":\"(.*?)\"/) {
      	print "Found authentication code.  Please use it when calling functions\n";
      	print "Authentication code: $1\n";
      	return 1;
      } else {
        print "No authentication token found.\n";
        print "Make sure your PIN is correct.\n";
        print "You may need to request a new PIN\n";
        return 0;
      }
    } else {
      print "No authentication token found.\n";
      print "Make sure your PIN is correct.\n";
      print "You may need to request a new PIN\n";
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Thermostat_Designation - fetch the designation for your thermostat

 Retrieves the code designating your thermostat and stores it in $self

   $Nest->fetch_Thermostat_Designation();

   This method accepts no parameters
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub fetch_Thermostat_Designation {
    my $self     = shift;
	my $response = $self->{'ua'}->get($self->{'device_url'});
    
    $self->{'last_code'} = $response->code;
    
    if ($response->is_success) {
      my $decoded_response      = decode_json($response->content);
      my $designation           = ($decoded_response->{'thermostats'});
      my @designation2          = keys(%$designation);
      $self->{'thermostat'}     = $designation2[0];
      $self->{'thermostat_url'} = "https://developer-api.nest.com/devices/thermostats/".$self->{'thermostat'};
      print "Thermostat designation: ".$self->{'thermostat'}."\n" if ($self->{'debug'});

      my $response = $self->{'ua'}->get("https://developer-api.nest.com/structures?auth=".$self->{'auth_token'});

      $self->{'last_code'}   = $response->code;
    
      if ($response->is_success) {
        my $decoded_response  = decode_json($response->content);
        my @designation       = keys(%$decoded_response);        
        $self->{'structure'}  = $designation[0];
        $self->{'struct_url'} = "https://developer-api.nest.com/structures/".$self->{'structure'}."?auth=".$self->{'auth_token'};
        print "Structure Designation: ".$self->{'structure'}."\n" if ($self->{'debug'});
        return 1;
      } else {
        print "Nest->fetch_Thermostat_Designation(): Response from server for structure URL is not valid\n";
        print "  \"".$response->content."\"\n\n";
        return 0;
      }
    } else {
      print "Nest->fetch_Thermostat_Designation(): Failed with return code ".$self->get_last_code()."\n";
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Ambient_Temperature_C - Fetch the ambient temperature reported by Nest in Celcius

 Retrieves the ambient temperature reported by the Nest in Celcius

   $Nest->fetch_Ambient_Temperature_C();

   This method accepts no parameters
 
 Returns the ambient temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Ambient_Temperature_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Ambient_Temperature_C(): No thermostat designation found\n";
      return 0;
    }

    return $self->__process_get($self->{'device_url'},'ambient_temperature_c');
}

#*****************************************************************

=head2 fetch_Target_Temperature_C - Fetch the target temperature reported by Nest in Celcius

 Retrieves the target temperature reported by the Nest in Celcius

   $Nest->fetch_Target_Temperature_C();

   This method accepts no parameters
 
 Returns the target temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_C(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_c');
}

#*****************************************************************

=head2 fetch_Target_Temperature_high_C - Fetch the higher target temperature reported by Nest in Celcius

 Retrieves the high target temperature reported by the Nest in Celcius

   $Nest->fetch_Target_Temperature_high_C();

   This method accepts no parameters
 
 Returns the high target temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_high_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_high_C(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_high_c');
}

#*****************************************************************

=head2 fetch_Target_Temperature_low_C - Fetch the lower target temperature reported by Nest in Celcius

 Retrieves the lower target temperature reported by the Nest in Celcius

   $Nest->fetch_Target_Temperature_low_C();

   This method accepts no parameters
 
 Returns the lower target temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_low_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_low_C(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_low_c');
}

#*****************************************************************

=head2 fetch_Away_Temperature_low_C - Fetch the lower away temperature reported by Nest in Celcius

 Retrieves the lower away temperature reported by the Nest in Celcius

   $Nest->fetch_Away_Temperature_low_C();

   This method accepts no parameters
 
 Returns the lower away temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Away_Temperature_low_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Away_Temperature_low_C(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'away_temperature_low_c');
}

#*****************************************************************

=head2 fetch_Away_Temperature_high_C - Fetch the high away temperature reported by Nest in Celcius

 Retrieves the high away temperature reported by the Nest in Celcius

   $Nest->fetch_Away_Temperature_high_C();

   This method accepts no parameters
 
 Returns the high away temperature in Celcius
 Returns 0 on failure
 
=cut
sub fetch_Away_Temperature_high_C {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Away_Temperature_high_C(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'away_temperature_high_c');
}

#*****************************************************************

=head2 fetch_Ambient_Temperature_F - Fetch the ambient temperature reported by Nest in Fahrenheit

 Retrieves the ambient temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Ambient_Temperature_F();

   This method accepts no parameters
 
 Returns the ambient temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Ambient_Temperature_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Ambient_Temperature_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'ambient_temperature_f');
}

#*****************************************************************

=head2 fetch_Away_Temperature_low_F - Fetch the lower away temperature reported by Nest in Fahrenheit

 Retrieves the lower away temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Away_Temperature_low_F();

   This method accepts no parameters
 
 Returns the lower away temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Away_Temperature_low_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Away_Temperature_low_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'away_temperature_low_f');
}

#*****************************************************************

=head2 fetch_Away_Temperature_high_F - Fetch the higher away temperature reported by Nest in Fahrenheit

 Retrieves the higher away temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Away_Temperature_high_F();

   This method accepts no parameters
 
 Returns the higher away temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Away_Temperature_high_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Away_Temperature_high_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'away_temperature_high_f');
}

#*****************************************************************

=head2 fetch_Target_Temperature_low_F - Fetch the lower target temperature reported by Nest in Fahrenheit

 Retrieves the lower target temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Target_Temperature_low_F();

   This method accepts no parameters
 
 Returns the lower target temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_low_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_low_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_low_f');
}

#*****************************************************************

=head2 fetch_Target_Temperature_F - Fetch the target temperature reported by Nest in Fahrenheit

 Retrieves the target temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Target_Temperature_F();

   This method accepts no parameters
 
 Returns the target temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_f');
}

#*****************************************************************

=head2 fetch_Target_Temperature_high_F - Fetch the higher target temperature reported by Nest in Fahrenheit

 Retrieves the higher target temperature reported by the Nest in Fahrenheit

   $Nest->fetch_Target_Temperature_high_F();

   This method accepts no parameters
 
 Returns the target temperature in Fahrenheit
 Returns 0 on failure
 
=cut
sub fetch_Target_Temperature_high_F {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Target_Temperature_high_F(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'target_temperature_high_f');
}

#*****************************************************************

=head2 fetch_Temperature_Scale - Fetch the temperature scale reported by Nest

 Retrieves the temperature scale reported by the Nest as either F (Fahrenheit)
 or C (Celcius)

   $Nest->fetch_Temperature_Scale();

   This method accepts no parameters
 
 Returns the temperature scale
 Returns 0 on failure
 
=cut
sub fetch_Temperature_Scale {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Temperature_Scale(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'temperature_scale');
}


##*****************************************************************
#
#=head2 fetch_Humidity - Fetch the humidity reported by Nest
#
# Retrieves the humidity reported as a percentage by the Nest 
#
#   $Nest->fetch_Humidity();
#
#   This method accepts no parameters
# 
# Returns the humidity
# Returns 0 on failure
# 
#=cut
#sub fetch_Humidity {
#    my $self = shift;
#    
#    if (!defined $self->{'thermostat'}) {
#      print "Nest->fetch_Humidity(): No thermostat designation found\n";
#      return 0;
#    }
#    
#    return $self->__process_get($self->{'device_url'},'humidity');
#}


#*****************************************************************

=head2 fetch_Is_Using_Emergency_Heat - Fetches true or false

 Retrieves the state of the Nest indicating whether it is using Emergency Heat 

   $Nest->fetch_Is_Using_Emergency_Heat();

   This method accepts no parameters
 
 Returns a Boolean
 
=cut
sub fetch_Is_Using_Emergency_Heat {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Is_Using_Emergency_Heat(): No thermostat designation found\n";
      return 0;
    }
    
    if ($self->__process_get($self->{'device_url'},'is_using_emergency_heat')) {
      return 1;
    } else { 
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Is_Online - Fetches true or false

 Retrieves the state of the Nest indicating whether it is online 

   $Nest->fetch_Is_Online();

   This method accepts no parameters
 
 Returns a Boolean
 
=cut
sub fetch_Is_Online {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Is_Online(): No thermostat designation found\n";
      return 0;
    }
    
    if ($self->__process_get($self->{'device_url'},'is_online')) {
      return 1;
    } else { 
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Can_Heat - Fetches true or false

 Retrieves the state of the Nest indicating whether it can heat

   $Nest->fetch_Can_Heat();

   This method accepts no parameters
 
 Returns a Boolean
 
=cut
sub fetch_Can_Heat {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Can_Heat(): No thermostat designation found\n";
      return 0;
    }
    
    if ($self->__process_get($self->{'device_url'},'can_heat')) {
      return 1;
    } else { 
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Can_Cool - Fetches true or false

 Retrieves the state of the Nest indicating whether it can cool

   $Nest->fetch_Can_Cool();

   This method accepts no parameters
 
 Returns a Boolean
 
=cut
sub fetch_Can_Cool {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Can_Cool(): No thermostat designation found\n";
      return 0;
    }
    
    if ($self->__process_get($self->{'device_url'},'can_cool')) {
      return 1;
    } else { 
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Has_Fan - Fetches true or false

 Retrieves the state of the Nest indicating whether it has a fan

   $Nest->fetch_Has_Fan();

   This method accepts no parameters
 
 Returns a Boolean
 
=cut
sub fetch_Has_Fan {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Has_Fan(): No thermostat designation found\n";
      return 0;
    }
    
    if ($self->__process_get($self->{'device_url'},'has_fan')) {
      return 1;
    } else { 
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Away_State - Fetch the away state reported by Nest

 Retrieves the away state reported by the Nest 

   $Nest->fetch_Away_State();

   This method accepts no parameters
 
 Returns the away state
 Returns 0 on failure
 
=cut
sub fetch_Away_State {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Away_State(): No thermostat designation found\n";
      return 0;
    }
    
	my $response = $self->{'ua'}->get($self->{'struct_url'});

    $self->{'last_code'}   = $response->code;
    
    if ($response->is_success) {
      my $decoded_response = decode_json($response->content);
      return $decoded_response->{'away'};
    } else {
      print "Nest->fetch_Away_State(): Failed with return code ".$self->get_last_code()."\n";
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Country_Code - Fetch the country code reported by Nest

 Retrieves the country code reported by the Nest 

   $Nest->fetch_Country_Code();

   This method accepts no parameters
 
 Returns the away state
 Returns 0 on failure
 
=cut
sub fetch_Country_Code {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Country_Code(): No thermostat designation found\n";
      return 0;
    }
    
	my $response = $self->{'ua'}->get($self->{'struct_url'});
    
    $self->{'last_code'}   = $response->code;
    
    if ($response->is_success) {
      my $decoded_response = decode_json($response->content);
      return $decoded_response->{$self->{'structure'}}->{'country_code'};
    } else {
      print "Nest->fetch_Country_Code(): Failed with return code ".$self->get_last_code()."\n";
      return 0;
    }
}


#*****************************************************************

=head2 fetch_Locale - Fetch the locale reported by Nest

 Retrieves the locale reported by the Nest 

   $Nest->fetch_Locale();

   This method accepts no parameters
 
 Returns the locale
 Returns 0 on failure
 
=cut
sub fetch_Locale {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Locale(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'locale');
}

#*****************************************************************

=head2 fetch_Name - Fetch the name reported by Nest

 Retrieves the name reported by the Nest 

   $Nest->fetch_Name();

   This method accepts no parameters
 
 Returns the name of the thermostat
 Returns 0 on failure
 
=cut
sub fetch_Name {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Name(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'name');
}


#*****************************************************************

=head2 fetch_Long_Name - Fetch the long name reported by Nest

 Retrieves the long name reported by the Nest 

   $Nest->fetch_Long_Name();

   This method accepts no parameters
 
 Returns the long name of the thermostat
 Returns 0 on failure
 
=cut
sub fetch_Long_Name {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_Long_Name(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'name_long');
}


#*****************************************************************

=head2 fetch_HVAC_Mode - Fetch the HVAC Mode reported by Nest

 Retrieves the HVAC Mode reported by the Nest as either 'heat' or 'cool'

   $Nest->fetch_HVAC_Mode();

   This method accepts no parameters
 
 Returns the HVAC mode
 Returns 0 on failure
 
=cut
sub fetch_HVAC_Mode {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_HVAC_Mode(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'hvac_mode');
}


#*****************************************************************

=head2 fetch_SW_Version - Fetch the software version reported by Nest

 Retrieves the software version reported by the Nest

   $Nest->fetch_SW_Version();

   This method accepts no parameters
 
 Returns the software version
 Returns 0 on failure
 
=cut
sub fetch_SW_Version {
    my $self = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->fetch_SW_Version(): No thermostat designation found\n";
      return 0;
    }
    
    return $self->__process_get($self->{'device_url'},'software_version');
}


#*****************************************************************

=head2 set_Target_Temperature_C - Set the target temperature in Celcius

 Set the target temperature in Celcius

   $Nest->set_Target_Temperature_C($temperature);

   This method accepts the following parameters:
     - $temperature : target temperature in Celcius - Required 
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_C {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_C(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_C(): Temperature is a required perameter\n";
      return 0;
    }

    return $self->__process_set($self->{'thermostat_url'},'target_temperature_C',$temperature);
}


#*****************************************************************

=head2 set_Target_Temperature_high_C - Set the high target temperature in Celcius

 Set the high target temperature in Celcius

   $Nest->set_Target_Temperature_high_C($temperature);

   This method accepts the following parameters:
     - $temperature : high target temperature in Celcius - Required 
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_high_C {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_high_C(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_high_C(): Temperature is a required perameter\n";
      return 0;
    }
    
    return $self->__process_set($self->{'thermostat_url'},'target_temperature_high_C',$temperature);
}


#*****************************************************************

=head2 set_Target_Temperature_low_C - Set the low target temperature in Celcius

 Set the low target temperature in Celcius

   $Nest->set_Target_Temperature_low_C($temperature);

   This method accepts the following parameters:
     - $temperature : low target temperature in Celcius - Required 
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_low_C {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_low_C(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_low_C(): Temperature is a required perameter\n";
      return 0;
    }
    
    return $self->__process_set($self->{'thermostat_url'},'target_temperature_low_C',$temperature);
}


#*****************************************************************

=head2 set_Target_Temperature_F - Set the target temperature in Fahrenheit

 Set the target temperature in Fahrenheit

   $Nest->set_Target_Temperature_F($temperature);

   This method accepts the following parameters:
     - $temperature : target temperature in Fahrenheit - Required 
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_F {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_F(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_F(): Temperature is a required perameter\n";
      return 0;
    }
    
    return $self->__process_set($self->{'thermostat_url'},'target_temperature_F',$temperature);
}


#*****************************************************************

=head2 set_Target_Temperature_high_F - Set the high target temperature in Fahrenheit

 Set the high target temperature in Fahrenheit

   $Nest->set_Target_Temperature_high_F($temperature);

   This method accepts the following parameters:
     - $temperature : high target temperature in Fahrenheit - Required 
 
 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_high_F {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_high_F(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_high_F(): Temperature is a required perameter\n";
      return 0;
    }
    
    return $self->__process_set($self->{'thermostat_url'},'target_temperature_high_F',$temperature);
}


#*****************************************************************

=head2 set_Target_Temperature_low_F - Set the low target temperature in Fahrenheit

 Set the low target temperature in Fahrenheit

   $Nest->set_Target_Temperature_low_F($temperature);

   This method accepts the following parameters:
     - $temperature : low target temperature in Fahrenheit - Required 

 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Target_Temperature_low_F {
    my $self        = shift;
    my $temperature = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Target_Temperature_low_F(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $temperature) {
      print "Nest->set_Target_Temperature_low_F(): Temperature is a required perameter\n";
      return 0;
    }
    
    return $self->__process_set($self->{'thermostat_url'},'target_temperature_low_F',$temperature);
}


#*****************************************************************

=head2 set_Away_State - Set the away state of the Nest

 Set the away state of the Nest to either 'home' or 'away'

   $Nest->set_Away_State($state);

   This method accepts the following parameters:
     - $state : away state either 'home' or 'away' - Required 

 Returns 1 on success
 Returns 0 on failure
 
=cut
sub set_Away_State {
    my $self  = shift;
    my $state = shift;
    
    if (!defined $self->{'thermostat'}) {
      print "Nest->set_Away_State(): No thermostat designation found\n";
      return 0;
    }
    if (!defined $state) {
      print "Nest->set_Away_State(): State is a required perameter\n";
      return 0;
    }
    
    my %state = ('away' => $state);
    my $json  = encode_json(\%state);

	my $response = $self->{'ua'}->put($self->{'struct_url'}, 
	         Content_Type => 'application/json',
             content      => $json);

    $self->{'last_code'}   = $response->code;
    
    if ($response->is_success) {
      return $response->content;
    } else {
      print "Nest->set_Away_State(): Failed with return code ".$self->get_last_code()."\n";
      return 0;
    }
}


##*****************************************************************
#
#=head2 set_Temperature_Scale - Set the temperature scale 
#
# Set the temperature as either F (Fahrenheit) or C (Celcius)
#
#   $Nest->set_Temperature_Scale($scale);
#
#   This method accepts the following parameters:
#     - $scale : F (Fahrenheit) or C (Celcius) - Required 
#
# Returns 1 on success
# Returns 0 on failure
# 
#=cut
#
#sub set_Temperature_Scale {
#    my $self  = shift;
#    my $scale = shift;
#    
#    if (!defined $self->{'thermostat'}) {
#      print "Nest->set_Temperature_Scale(): No thermostat designation found\n";
#      return 0;
#    }
#    if (!defined $scale) {
#      print "Nest->set_Temperature_Scale(): Scale is a required perameter\n";
#      return 0;
#    }
#    
#    return $self->__process_set($self->{'thermostat_url'},'temperature_scale');
#}
#


#*****************************************************************

=head2 dump_Object - shows the contents of the local Nest object

 shows the contents of the local Nest object in human readable form

   $Nest->dump_Object();

   This method accepts no parameters
 
 Returns nothing 
 
=cut
sub dump_Object {
    my $self  = shift;
    
    print "ClientID       : ".substr($self->{'ClientID'},      0,120)."\n";
    print "ClientSecret   : ".substr($self->{'ClientSecret'},  0,120)."\n";
    print "auth_token     : ".substr($self->{'auth_token'},    0,120)."\n";
    print "PIN_code       : ".substr($self->{'PIN_code'},      0,120)."\n";
    print "device_url     : ".substr($self->{'device_url'},    0,120)."\n";
    print "struct_url     : ".substr($self->{'struct_url'},    0,120)."\n";
    print "structure      : ".substr($self->{'structure'},     0,120)."\n";
    print "thermostat_url : ".substr($self->{'thermostat_url'},0,120)."\n";
    print "thermostat     : ".substr($self->{'thermostat'},    0,120)."\n";
    print "debug          : ".substr($self->{'debug'},         0,120)."\n";
    print "last_code      : ".substr($self->{'last_code'},     0,120)."\n";
    print "last_reason    : ".substr($self->{'last_reason'},   0,120)."\n";
    print "\n";
}


#*****************************************************************

=head2 get_last_code - returns the code generated by the most recent fetch

 Returns the HTTP Header code for the most recent fetch command

   $Nest->get_last_code();

   This method accepts no parameters
 
 Returns the numeric code
 
=cut

sub get_last_code {
    my $self  = shift;
    return $self->{'last_code'};
}

#*****************************************************************

=head2 get_last_reason - returns the text generated by the most recent fetch

 Returns the HTTP Header reason for the most recent fetch command

   $Nest->get_last_reason();

   This method accepts no parameters
 
 Returns the textual reason
 
=cut

sub get_last_reason {
    my $self  = shift;
    return $self->{'last_reason'};
}

#******************************************************************************
=head2 get_last_exec_time - returns the execution time for the last fetch

 Returns the number of milliseconds it took for the last fetch call

   $Nest->get_last_exec_time();

   This method accepts no parameters
 
 Returns the number of milliseconds
 
=cut

sub get_last_exec_time {
    my $self  = shift;
    return $self->{'last_exec_time'};
}

#*****************************************************************

sub __process_get {
    my $self        = shift;
    my $url         = shift;
    my $tag         = shift;
    my $time_before = gettimeofday;
	my $response    = $self->{'ua'}->get($url);
    my $time_after  = gettimeofday;
	
    $self->{'last_exec_time'} = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}      = $response->code;
    
    if ($response->is_success) {
      my $decoded_response = decode_json($response->content);
#      print Dumper($decoded_response);
      return $decoded_response->{'thermostats'}->{$self->{'thermostat'}}->{$tag};
    } else {
      print "\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()."\n";
      return 0;
    }
}


#*****************************************************************

sub __process_set {
    my $self     = shift;
    my $url      = shift;
    my $tag      = shift;
    my $value    = shift;

	my $response = $self->{'ua'}->put($url."/".$tag."?auth=".$self->{'auth_token'}, 
	         Content_Type => 'application/json',
             content      => $value );
    $self->{'last_code'}   = $response->code;
    $self->{'last_reason'} = decode_json($response->content)->{'error'};

    if ($response->is_success) {
      return $response->content;
    } else {
      print "\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n";
      return 0;
    }
}


#*****************************************************************

=head1 AUTHOR

Kedar Warriner, C<kedar at cpan.org>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-device-Nest at rt.cpan.org>
 or through the web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Nest
 I will be notified, and then you'll automatically be notified of progress on 
 your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

  perldoc Device::Nest

 You can also look for information at:

=over 5

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Nest>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Nest>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Nest>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Nest/>

=back

=head1 ACKNOWLEDGEMENTS

 Many thanks to:
  The guys at Nest for creating the Nest Thermostat sensor and 
      developping the API.
  Everyone involved with CPAN.

=head1 LICENSE AND COPYRIGHT

 Copyright 2014 Kedar Warriner <kedar at cpan.org>.

 This program is free software; you can redistribute it and/or modify it
 under the terms of either: the GNU General Public License as published
 by the Free Software Foundation; or the Artistic License.

 See http://dev.perl.org/licenses/ for more information.

=cut

#********************************************************************
1; # End of Device::Nest - Return success to require/use statement
#********************************************************************

    