package Device::Neurio;

use warnings;
use strict;
use 5.006_001; 

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Device::NeurioTools ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our %EXPORT_TAGS = ( 'all' => [ qw(
    new connect fetch_Samples_Recent_Live fetch_Samples_Last_Live fetch_Samples 
    fetch_Samples_Full fetch_Stats_Energy fetch_Appliances fetch_Appliances_Events_by_Appliance
    fetch_Appliances_Events_by_Location fetch_Appliance fetch_Appliances_Stats
    get_last_code get_last_exec_time get_last_reason
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( $EXPORT_TAGS{'all'});

BEGIN
{
  if ($^O eq "MSWin32"){
    use LWP::UserAgent;
    use HTTP::Request;
    use Time::Local;
    use JSON qw(decode_json encode_json);
    use MIME::Base64 (qw(encode_base64));
    use Time::HiRes (qw/gettimeofday/);
    use Data::Dumper;
  } else {
    use LWP::UserAgent;
    use HTTP::Request;
    use Time::Local;
    use JSON qw(decode_json encode_json);
    use MIME::Base64 (qw(encode_base64));
    use Time::HiRes (qw/gettimeofday/);
    use Data::Dumper;
  }
}


=head1 NAME

Device::Neurio - Methods for wrapping the Neurio API calls so that they are 
                 accessible via Perl

=head1 VERSION

Version 0.16

=cut

our $VERSION = '0.16';

###################################################################################################
=head1 SYNOPSIS

 This module provides a Perl interface to a Neurio sensor via the following 
 methods:
   - new
   - connect
   - fetch_Samples
   - fetch_Samples_Full
   - fetch_Samples_Last_Live
   - fetch_Samples_Recent_Live
   - fetch_Stats_Energy
   - fetch_Appliances
   - fetch_Appliances_Events
   - fetch_Appliance
   - fetch_Appliances_Stats

 Please note that in order to use the 'Samples' methods in this module you will 
 require three parameters (key, secret, sensor_id) as well as an Energy Aware 
 Neurio sensor installed in your house.  In order to use the 'Appliances'
 methods, you will also require another parameter (location_id).  This information
 can be obtained from the Neurio developpers website.

 The module is written entirely in Perl and was developped on Raspbian Linux.

 All date/time values are specified using ISO8601 format (yyyy-mm-ddThh:mm:ssZ)

=head1 SAMPLE CODE

    use Device::Neurio;

    $my_Neurio = Device::Neurio->new($key,$secret,$sensor_id);

    $my_Neurio->connect($location_id);
  
    $data = $my_Neurio->fetch_Samples_Last_Live();
    print $data->{'consumptionPower'}

    $data = $my_Neurio->fetch_Samples_Recent_Live("2014-06-18T19:20:21Z");
    print $data->[0]->{'consumptionPower'}

    undef $my_Neurio;


=head2 EXPORT

 All by default.


=head1 SUBROUTINES/METHODS

=head2 new - the constructor for a Neurio object

 Creates a new instance which will be able to fetch data from a unique Neurio 
 sensor.  All three parameters are required and can be obtained from the
 Neurio developpers website.

 my $Neurio = Device::Neurio->new($key, $secret, $sensor_id, $debug);

   This method accepts the following parameters:
     - $key       : unique key for the account - Required 
     - $secret    : secret key for the account - Required 
     - $sensor_id : sensor ID connected to the account - Required 
     - $debug     : turn on debug messages - Optional

 Returns a Neurio object if successful.
 Returns 0 on failure
 
=cut

sub new {
    my $class = shift;
    my $self;
    
    $self->{'ua'}        = LWP::UserAgent->new();
    $self->{'key'}       = shift;
    $self->{'secret'}    = shift;
    $self->{'sensor_id'} = shift;
    $self->{'debug'}     = 0;

    if ((!defined $self->{'key'}) || (!defined $self->{'secret'}) || (!defined $self->{'sensor_id'})) {
      print "\nNeurio->new(): Key, Secret and Sensor_ID are REQUIRED parameters\n";
      $self->{'last_code'}      = '0';
      $self->{'last_reason'}    = 'Neurio->new(): Key, Secret and Sensor_ID are REQUIRED parameters';
      return 0;
    }
    
    $self->{'base64'} = encode_base64($self->{'key'}.":".$self->{'secret'});
    chomp($self->{'base64'});
    
    if (!defined $self->{'debug'}) {
      $self->{'debug'} = 0;
    }
    
    $self->{'base_url'}                = "https://api-staging.neur.io/v1";
#    $self->{'base_url'}                = "https://api.neur.io/v1";
    $self->{'Samples_Recent_Live_url'} = $self->{'base_url'}."/samples/live?sensorId=".$self->{'sensor_id'};
    $self->{'Samples_Last_Live_url'}   = $self->{'base_url'}."/samples/live/last?sensorId=".$self->{'sensor_id'};
    $self->{'Samples_url'}             = $self->{'base_url'}."/samples?sensorId=".$self->{'sensor_id'};
    $self->{'Samples_Full_url'}        = $self->{'base_url'}."/samples/full?sensorId=".$self->{'sensor_id'};
    $self->{'Stats_Energy_url'}        = $self->{'base_url'}."/samples/stats?sensorId=".$self->{'sensor_id'};
    $self->{'Appliances_url'}          = $self->{'base_url'}."/appliances";
    $self->{'Appliances_Specs_url'}    = $self->{'base_url'}."/appliances/specs";
    $self->{'Appliances_Stats_url'}    = $self->{'base_url'}."/appliances/stats";
    $self->{'Appliances_Status_url'}   = $self->{'base_url'}."/appliances/status";
    $self->{'Appliances_Events_url'}   = $self->{'base_url'}."/appliances/events";
    $self->{'Users_url'}               = $self->{'base_url'}."/users";
    $self->{'Location_url'}            = $self->{'base_url'}."/locations";
    $self->{'Cycles_url'}              = $self->{'base_url'}."/cycles";
    $self->{'Cycles_Full_url'}         = $self->{'base_url'}."/cycles/full";
    $self->{'Cycles_Groups_url'}       = $self->{'base_url'}."/cycles/groups";
    $self->{'Edges_url'}               = $self->{'base_url'}."/edges?sensorId=".$self->{'sensor_id'};
    $self->{'Sensors_url'}             = $self->{'base_url'}."/sensors";
    $self->{'Analytics_url'}           = $self->{'base_url'}."/analytics/results";
    $self->{'last_code'}               = '';
    $self->{'last_reason'}             = '';
	$self->{'last_exec_time'}          = 0;
    $self->{'rateLimitRemaining'}      = 0;
    $self->{'rateLimitReset'}          = 0;
    $self->{'rateLimitLimit'}          = 0;
    $self->{'contentLength'}           = 0;
	
    bless $self, $class;
    
    return $self;
}




#*****************************************************************

=head2 DESTROY - the destructor for a Neurio object

 Destroys a previously created Neuri object.
 
=cut
sub DESTROY {
    my $self = shift;
    
    print"\nDestroying ".ref($self), "...\n\n";

    undef $self->{'ua'};
    undef $self->{'key'};
    undef $self->{'secret'};
    undef $self->{'sensor_id'};
    undef $self->{'debug'};
    undef $self->{'base64'};
    undef $self->{'base_url'};
    undef $self->{'Samples_Recent_Live_url'};
    undef $self->{'Samples_Last_Live_url'};
    undef $self->{'Samples_url'};
    undef $self->{'Samples_Full_url'};
    undef $self->{'Stats_Energy_url'};
    undef $self->{'Appliances_url'};
    undef $self->{'Appliances_Specs_url'};
    undef $self->{'Appliances_Stats_url'};
    undef $self->{'Appliances_Status_url'};
    undef $self->{'Appliances_Events_url'};
    undef $self->{'Users_url'};
    undef $self->{'Cycles_url'};
    undef $self->{'Cycles_Full_url'};
    undef $self->{'Cycles_Groups_url'};
    undef $self->{'Edges_url'};
    undef $self->{'Sensors_url'};
    undef $self->{'Analytics_url'};
    undef $self->{'last_code'};
    undef $self->{'last_reason'};
	undef $self->{'last_exec_time'};
    undef $self->{'rateLimitRemaining'};
    undef $self->{'rateLimitReset'};
    undef $self->{'rateLimitLimit'};
    undef $self->{'contentLength'};
	
}

###################################################################################################
=head2 connect - open a secure connection to the Neurio server

 Opens a secure connection via HTTPS to the Neurio server which provides
 access to a set of API commands to access the sensor data.
 
 An optional location ID can be given.  This is only required if calls
 will be made to the 'Appliance' methods.  Calls to the 'Samples'
 methods do not require that a location ID be set.  If a location_id is not
 specified at connection, then it must be specified when using the 'Appliance'
 methods.
 
 A location ID can be acquired from the Neurio developpers web site

   $Neurio->connect($location_id);
 
   This method accepts the following parameter:
     - $location_id : unique location id - Optional 
 
 Returns 1 on success 
 Returns 0 on failure
 
=cut

sub connect {
    my ($self,$location_id) = @_;
	my $access_token        = '';
	
    if (defined $location_id) {
      $self->{'location_id'} = $location_id;
    } else {
      $self->{'location_id'} = '';
    }

    # Submit request for authentiaction token.
    my $response = $self->{'ua'}->post($self->{'base_url'}.'/oauth2/token',
          { basic_authentication => $self->{'base64'},
        	Content_Type         => 'application/x-www-form-urlencoded',
        	grant_type           => 'client_credentials', 
        	client_id            => $self->{'key'},
        	client_secret        => $self->{'secret'},
          }
        );
    
    if($response->is_success) {
      my $return = $response->content;
      $return =~ /\"access_token\":\"(.*)\"\,\"token_type\"/;
      $self->{'access_token'} = $1;
      return 1;
    } else {
      $self->printLOG("\nDevice::Neurio->connect(): Failed to connect.\n");
      if ($self->{'debug'}) {$self->printLOG($response->content."\n\n");}
      $self->{'last_code'}   = '0';
      $self->{'last_reason'} = 'Neurio->new(): Device::Neurio->connect(): Failed to connect';
      return 0;
    }
}

###################################################################################################
=head2 debug - Configure debug settings for a Neurio object

 Enables debug printouts and an optional file handle can be supplied
 where printouts will be re-directed.

    $my_Neurio = Device::Neurio->new($key,$secret,$sensor_id);

    $my_Neurio->connect($location_id);
    $my_Neurio->debug($debug,$fileHandle);

   This method accepts at least one of the following parameters:
     - $debug      : turn on debug messages - Optional
     - $fileHandle : filehandle for logging debug messages - Optional

 Returns nothing.
 
=cut
sub debug {
    my ($self,$debug,$fileHandle) = @_;
    
    if (defined $debug) {
      $self->{'debug'} = $debug;
    }
    
    if (defined $fileHandle) {
      $self->{'$fileHandle'} = $fileHandle;
    }
}

###################################################################################################
=head2 fetch_Samples_Recent_Live - Fetch recent sensor samples

 Get recent samples, one sample per second for up to the last 2 minutes.
 The values represent the sum of all phases.

   $Neurio->fetch_Samples_Recent_Live($last);
 
   This method accepts the following parameters:
      $last - time of last sample received specified using ISO8601 
              format (yyyy-mm-ddThh:mm:ssZ)  - Optional
      
      If no value is specified for $last, a default of 2 minutes is used.
 
 Returns an array of Perl data structures on success
 [
          {
            'generationEnergy' => 3716166644,
            'timestamp' => '2014-06-24T11:08:00.000Z',
            'consumptionEnergy' => 6762651207,
            'generationPower' => 564,
            'consumptionPower' => 821
          },
          ...
         ]
 Returns 0 on failure
 
=cut

sub fetch_Samples_Recent_Live {
    my ($self,$last) = @_;
    my $url = $self->{'Samples_Recent_Live_url'};;

    # if optional parameter is defined, add it
    if (defined $last) {
      $url = $self->{'Samples_Recent_Live_url'}."&last=$last";
    } 

    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Samples_Last_Live - Fetch the last live sensor sample

 Get the last sample recorded by the sensor.
 The values represent the sum of all phases.

   $Neurio->fetch_Samples_Last_Live();

   This method accepts no parameters
 
 Returns a Perl data structure on success:
 {
          'generationEnergy' => 3716027450,
          'timestamp' => '2014-06-24T11:03:43.000Z',
          'consumptionEnergy' => 6762445671,
          'generationPower' => 542,
          'consumptionPower' => 800
        };
 Returns 0 on failure
 
=cut

sub fetch_Samples_Last_Live {
    my $self = shift;
    my $url  = $self->{'Samples_Last_Live_url'};
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Samples - Fetch sensor samples from the Neurio server

 Get samples for a specified time interval.
 The values represent the sum of all phases.

 $Neurio->fetch_Samples($start,$granularity,$end,$frequency,$perPage,$page);

   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : if the granularity is specified as 'minutes', then the 
                      frequency must be a multiple of 5 - Optional
     - $perPage     : number of results per page - Optional
     - $page        : page number to return - Optional
 
 Returns an array of Perl data structures on success
     [
              {
                'generationEnergy' => 3568948578,
                'timestamp' => '2014-06-21T19:00:00.000Z',
                'consumptionEnergy' => 6487889194,
                'generationPower' => 98,
                'consumptionPower' => 240
              },
             ...
             ]
 Returns 0 on failure
 
=cut

sub fetch_Samples {
    my ($self,$start,$granularity,$end,$frequency,$perPage,$page) = @_;
    
    my $url = $self->{'Samples_url'};
    
    # if REQUIRED parameters are defined, add them
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $granularity) {
      $url = $url . "&granularity=$granularity";
    }
    
    # if optional parameters are defined, add them
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    if (defined $frequency) {
      $url = $url . "&frequency=$frequency";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Samples_Full - Fetches full samples for all phases

 Get full samples for a specified time interval. Sample data will include
 information broken down by channel.

 $Neurio->fetch_Samples_Full($start,$granularity,$end,$frequency,$perPage,$page);

   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : an integer - Optional
     - $perPage     : number of results per page - Optional
     - $page        : page number to return - Optional
 
 Returns an array of Perl data structures on success
 [
  {
    'timestamp' => '2014-06-16T19:20:21.000Z',
    'channelSamples' => [
                          {
                            'voltage' => '123.19',
                            'power' => 129,
                            'name' => '1',
                            'energyExported' => 27,
                            'channelType' => 'phase_a',
                            'energyImported' => 2682910899,
                            'reactivePower' => 41
                          },
                          {
                            'voltage' => '123.94',
                            'power' => 199,
                            'name' => '2',
                            'energyExported' => 6,
                            'channelType' => 'phase_b',
                            'energyImported' => 3296564362,
                            'reactivePower' => -45
                          },
                          {
                            'voltage' => '123.57',
                            'power' => 327,
                            'name' => '3',
                            'energyExported' => 10,
                            'channelType' => 'consumption',
                            'energyImported' => 5979475235,
                            'reactivePower' => -4
                          }
                        ]
  },
  ...
 ]
 Returns 0 on failure
 
=cut

sub fetch_Samples_Full {
    my ($self,$start,$granularity,$end,$frequency,$perPage,$page) = @_;
    
    my $url = $self->{'Samples_Full_url'};
    
    # if REQUIRED parameters are defined, add them
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $granularity) {
      $url = $url . "&granularity=$granularity";
    }

    # if optional parameters are defined, add them
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    if (defined $frequency) {
      $url = $url . "&frequency=$frequency";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Stats_Energy - Fetches energy statistics

 Get brief stats for energy consumed in a given time interval.
 The values represent the sum of all phases.

 To convert the energy returned into kWh, divide it by 3600000

   $Neurio->fetch_Stats_Energy($start,$granularity,$frequency,$end);

   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : minutes|hours|days|months - Required
     - $frequency   : if the granularity is specified as 'minutes', then the 
                      frequency must be a multiple of 5 - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
 
 Returns a Perl data structure containing all the raw data
 Returns 0 on failure
 
=cut

sub fetch_Stats_Energy {
    my ($self,$start,$granularity,$frequency,$end) = @_;

    my $url = $self->{'Stats_Energy_url'};

    # if REQUIRED parameter are defined, add them
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    
    # if optional parameter is defined, add it
    if (defined $frequency) {
      $url = $url . "&frequency=$frequency";
    }
    if (defined $granularity) {
      $url = $url . "&granularity=$granularity";
    }
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    
    return $self->__process_get($url);
}




###################################################################################################
=head2 fetch_Appliances - Fetch the appliances for a specific location

 Get the appliances added for a specified location. 
 
 The location_id is an optional parameter because it can be specified when 
 connecting.  If it is specified below, then this will over-ride the location 
 ID set when connecting, but for this function call only.

   $Neurio->fetch_Appliances($location_id);

   This method accepts the following parameters:
     - $location_id  : id of a location - Optional
 
 Returns an array of Perl data structures on success
 [
          {
            'locationId' => 'xxxxxxxxxxxxxxx',
            'name' => 'lighting_appliance',
            'id' => 'yyyyyyyyyyyyyyyyy',
            'label' => 'Range Light on Medium',
            'tags' => []
          },
          {
            'locationId' => 'xxxxxxxxxxxxxxx-3',
            'name' => 'refrigerator',
            'id' => 'zzzzzzzzzzzzzzzz',
            'label' => '',
            'tags' => []
          },
          ....
         ]
 Returns 0 on failure
 
=cut

sub fetch_Appliances {
    my ($self,$location_id) = @_;

    my $url = $self->{'Appliances_url'}."?";

    # if REQUIRED parameter is defined, add it
    if (defined $location_id) {
      $url = $url . "locationId=$location_id";
    } else {
      $url = $url . "locationId=".$self->{'location_id'};
    }

    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliance - Fetch information about a specific appliance

 Get the information for a given appliance.
 
 The applicance_id parameter is determined by using the fetch_Appliance method 
 which returns a list of appliances with their IDs

   $Neurio->fetch_Appliance($appliance_id);

   This method accepts the following parameters:
     - $appliance_id  : id of the appliance - Required
 
 Returns a Perl data structure on success:
 {
          'locationId' => 'xxxxxxxxxxxxx,
          'name' => 'lighting_appliance',
          'id' => 'yyyyyyyyyyyyyyy',
          'label' => 'Range Light on Medium',
          'tags' => []
        };
 Returns 0 on failure
 
=cut

sub fetch_Appliance {
    my ($self,$appliance_id) = @_;
    
    my $url = $self->{'Appliances_url'}."/";

    # if REQUIRED parameter are defined, add them
    if (defined $appliance_id) {
      $url = $url . $appliance_id;
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Specs - Fetch specs about all appliances

 Get all supported appliance types that Neurio can detect, along with their 
 specifications.
 
   $Neurio->fetch_Appliances_Specs();

   This method accepts no parameters:
 
 Returns a Perl data structure on success:
 {
          'locationId' => 'xxxxxxxxxxxxx,
          'name' => 'lighting_appliance',
          'id' => 'yyyyyyyyyyyyyyy',
          'label' => 'Range Light on Medium',
          'tags' => []
        };
 Returns 0 on failure
 
=cut

sub fetch_Appliances_Specs {
    my $self = shift;
    my $url  = $self->{'Appliances_Specs_url'};
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Status - Fetch specs about all appliances

 Query the appliance statuses for a specified location.
 
   $Neurio->fetch_Appliances_Status($location_id);

   This method accepts the following parameters:
      - $location_Id  : id of a location - Required
 
 Returns a Perl data structure on success:
 [
    {
        "appliance" : {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "television",
            "label" : "upstairs TV",
            "tags" : ["bedroom_television", "42 inch LED"],
            "locationId" : "0qX7nB-8Ry2bxIMTK0EmXw",
            "createdAt": "2014-10-16T18:21:11.038Z",
            "updatedAt": "2014-10-16T18:47:09.566Z",
        },
        "isTrained": true,
        "lastUsed": "2014-10-31T15:08:01.310Z"
    },
    ...
  ]
 Returns 0 on failure
 
=cut

sub fetch_Appliances_Status {
    my ($self,$location_id) = @_;
    my $url = $self->{'Appliances_Status_url'}."?locationId=$location_id";
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Stats_by_Location - Fetch appliance stats for a given location

 Get appliance usage data for a given location.
 
   $Neurio->fetch_Appliances_Stats_by_location($location_id,$start,$granularity,$end,$minPower,$perPage,$page);

   This method accepts the following parameters:
      - $location_Id  : id of a location - Required
      - $start        : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $granularity  : seconds|minutes|hours|days - Required
      - $end          : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $minPower     : minimum power - Optional
      - $perPage      : number of results per page - Optional
      - $page         : page number to return - Optional
 
 Returns an array of Perl data structures on success
[
    {
        "appliance": {
            "label": "",
            "name": "dryer",
            "locationId": "0qX7nB-8Ry2bxIMTK0EmXw",
            "tags": [],
            "createdAt": "2015-01-04T23:42:54.009Z",
            "updatedAt": "2015-01-30T19:19:10.278Z",
            "id": "4SmROBfiTA6huhV7Drrm1h"
        },
        "averagePower": 5162.4,
        "eventCount": 5,
        "lastEvent": {
            "appliance": {
                "label": "",
                "name": "dryer",
                "locationId": "0qX7nB-8Ry2bxIMTK0EmXw",
                "tags": [],
                "createdAt": "2015-01-04T23:42:54.009Z",
                "updatedAt": "2015-01-30T19:19:10.278Z",
                "id": "4SmROBfiTA6huhV7Drrm1h"
            },
            "status": "complete",
            "start": "2015-02-04T22:24:41.816Z",
            "end": "2015-02-04T22:31:06.792Z",
            "energy": 1308604,
            "averagePower": 5155,
            "guesses": {
                "air_conditioner": 0.5,
                "dryer": 0.5
            },
            "groupIds": ["2pMROafiTA6huhV7Drrm1g"],
            "lastCycle": {
                "groupId": "cd0r-kOrRvWFbIuuUnL5GQ",
                "start": "2015-02-04T22:29:25.798Z",
                "end": "2015-02-04T22:31:06.792Z",
                "energy": 482612,
                "averagePower": 5182,
                "createdAt": "2015-02-04T22:29:38.701Z",
                "updatedAt": "2015-02-04T23:28:08.014Z",
                "significant": true,
                "sensorId": "0x0000C47F510179FE",
                "id": "Xj_L10ryTgSdX8euqj_fHw"
            },
            "cycleCount": 2,
            "isConfirmed": true,
            "id": "-yvnL0vgTN2DUx2dVv4uTw"
        },
        "timeOn": 687944,
        "energy": 14443276,
        "usagePercentage": 16.34809,
        "guesses": {},
        "start": "2015-02-04T03:37:51.566Z",
        "end": "2015-02-11T23:41:06.554Z",
        "groupIds": ["2pMROafiTA6huhV7Drrm1g"],
        "id": "Y8StKV6nStaXaguxnmNKtg"
    },
    ...
]
 Returns 0 on failure
 
=cut

sub fetch_Appliances_Stats_by_Location {
    my ($self,$location_id,$start,$granularity,$end,$minPower,$perPage,$page) = @_;
    
    my $url = $self->{'Appliances_Stats_url'}."?";
    
    # if REQUIRED parameter are defined, add them
    if (defined $location_id) {
      $url = $url . "locationId=$location_id";
    }
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    if (defined $granularity) {
      $url = $url . "&granularity=$granularity";
    }
    
    # if optional parameters are defined, add them
    if (defined $minPower) {
      $url = $url . "&minPower=$minPower";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Stats_by_Appliance - Fetch usage data for a given appliance

 Get appliance usage data for a given appliance.
 
   $Neurio->fetch_Appliances_Stats_by_Appliance($appliance_id,$start,$granularity,$end,$minPower,$perPage,$page);

   This method accepts the following parameters:
      - $appliance_id : id of the appliance - Required
      - $start        : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $granularity  : days, weeks, or months - Required
      - $end          : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $minPower     : minimum Power - Optional
      - $perPage      : number of results per page - Optional
      - $page         : page number to return - Optional
 
 Returns an array of Perl data structures on success
[
    {
        "appliance": {
            "label": "",
            "name": "dryer",
            "locationId": "0qX7nB-8Ry2bxIMTK0EmXw",
            "tags": [],
            "createdAt": "2015-01-04T23:42:54.009Z",
            "updatedAt": "2015-01-30T19:19:10.278Z",
            "id": "4SmROBfiTA6huhV7Drrm1h"
        },
        "averagePower": 5162.4,
        "eventCount": 5,
        "lastEvent": {
            "appliance": {
                "label": "",
                "name": "dryer",
                "locationId": "0qX7nB-8Ry2bxIMTK0EmXw",
                "tags": [],
                "createdAt": "2015-01-04T23:42:54.009Z",
                "updatedAt": "2015-01-30T19:19:10.278Z",
                "id": "4SmROBfiTA6huhV7Drrm1h"
            },
            "status": "complete",
            "start": "2015-02-04T22:24:41.816Z",
            "end": "2015-02-04T22:31:06.792Z",
            "energy": 1308604,
            "averagePower": 5155,
            "guesses": {
                "air_conditioner": 0.5,
                "dryer": 0.5
            },
            "groupIds": ["2pMROafiTA6huhV7Drrm1g"],
            "lastCycle": {
                "groupId": "cd0r-kOrRvWFbIuuUnL5GQ",
                "start": "2015-02-04T22:29:25.798Z",
                "end": "2015-02-04T22:31:06.792Z",
                "energy": 482612,
                "averagePower": 5182,
                "createdAt": "2015-02-04T22:29:38.701Z",
                "updatedAt": "2015-02-04T23:28:08.014Z",
                "significant": true,
                "sensorId": "0x0000C47F510179FE",
                "id": "Xj_L10ryTgSdX8euqj_fHw"
            },
            "cycleCount": 2,
            "isConfirmed": true,
            "id": "-yvnL0vgTN2DUx2dVv4uTw"
        },
        "timeOn": 687944,
        "energy": 14443276,
        "usagePercentage": 16.34809,
        "guesses": {},
        "start": "2015-02-04T03:37:51.566Z",
        "end": "2015-02-11T23:41:06.554Z",
        "groupIds": ["2pMROafiTA6huhV7Drrm1g"],
        "id": "Y8StKV6nStaXaguxnmNKtg"
    },
    ...
]
 Returns 0 on failure
 
=cut

sub fetch_Appliances_Stats_by_Appliance {
    my ($self,$appliance_id,$start,$granularity,$end,$minPower,$perPage,$page) = @_;

    my $url = $self->{'Appliances_Stats_url'}."?";

    # if REQUIRED parameter are defined, add them
    if (defined $appliance_id) {
      $url = $url . "applianceId=$appliance_id";
    }
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    if (defined $granularity) {
      $url = $url . "&granularity=$granularity";
    }
    
    # if optional parameters are defined, add them
    if (defined $minPower) {
      $url = $url . "&minPower=$minPower";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Events_by_Location - Fetch events for a specific location

 Get appliance events by location Id. 
 An event is an interval when an appliance was in use.
 
 An applicance_id can be requested by using the NeurioTools::get_appliance_ID 
 method which returns an appliance ID for a given string name.
 

   $Neurio->fetch_Appliances_Events_by_Location($location_id, $start,$end,$perPage,$page);

   This method accepts the following parameters:
      - $location_Id  : id of a location - Required
      - $start        : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $end          : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $minpower     : Minimum power consumption - Optional
      - $perPage      : number of results per page - Optional
      - $page         : page number to return - Optional
 
 Returns an array of Perl data structures on success
  [
    {
        "id" : "1cRsH7KQTeONMzjSuRJ2aw",
        "createdAt" : "2014-04-21T22:28:32Z",
        "updatedAt" : "2014-04-21T22:45:32Z",
        "appliance" : {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "television",
            "label" : "upstairs TV",
            "tags" : ["bedroom_television", "42 inch LED"],
            "locationId" : "0qX7nB-8Ry2bxIMTK0EmXw"
        },
        "start" : "2014-04-21T05:26:10.785Z",
        "end" : "2014-04-21T05:36:00.547Z",
        "guesses" : {"dryer1" : 0.78, "dishwasher_2014" : 0.12},
        "energy" : 247896,
        "averagePower" : 122,
        "groupIds" : [ "2pMROafiTA6huhV7Drrm1g", "4SmROBfiTA6huhV7Drrm1h" ],
        "cycleCount" : 5,
        "isRunning" : false
    },
    ...
  ]
  Returns 0 on failure
 
=cut

sub fetch_Appliances_Events_by_Location {
    my ($self,$location_id,$start,$end,$minPower,$perPage,$page) = @_;
    
    my $url = $self->{'Appliances_Events_url'}."?";
    
    # if REQUIRED parameter are defined, add them
    if (defined $location_id) {
      $url = $url . "locationId=$location_id";
    }
    
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    
    # if optional parameters are defined, add them
    if (defined $minPower) {
      $url = $url . "&minPower=$minPower";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }

    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Events_by_Appliance - Fetch events for a specific appliance

 Get appliance events by appliance Id. 
 An event is an interval when an appliance was in use.
 
 An applicance_id can be requested by using the NeurioTools::get_appliance_ID 
 method which returns an appliance ID for a given string name.
 
   $Neurio->fetch_Appliances_Events_by_Appliance($appliance_id,$start,$end,$perPage,$page);

   This method accepts the following parameters:
      - $appliance_id : id of the appliance - Required
      - $start        : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $end          : yyyy-mm-ddThh:mm:ssZ - Required
                        specified using ISO8601 format
      - $minpower     : Minimum power consumption - Optional
      - $perPage      : number of results per page - Optional
      - $page         : page number to return - Optional
 
 Returns an array of Perl data structures on success
 [
    {
        "id" : "1cRsH7KQTeONMzjSuRJ2aw",
        "appliance" : {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "television",
            "label" : "upstairs TV",
            "tags" : ["bedroom_television", "42 inch LED"],
            "locationId" : "0qX7nB-8Ry2bxIMTK0EmXw"
        },
        "start" : "2014-04-21T05:26:10.785Z",
        "end" : "2014-04-21T05:36:00.547Z",
        "guesses" : {"dryer1" : 0.78, "dishwasher_2014" : 0.12},
        "energy" : 247896,
        "averagePower" : 122,
        "groupIds" : [ "2pMROafiTA6huhV7Drrm1g", "4SmROBfiTA6huhV7Drrm1h" ],
        "lastCycle": {
            "groupId" : "4SmROBfiTA6huhV7Drrm1h",
            "start" : "2014-04-21T05:29:00.547Z",
            "end" : "2014-04-21T05:36:00.147Z",
            "energy" : 41846,
            "averagePower" : 122,
            "createdAt" : "2014-04-21T05:29:02.547Z",
            "updatedAt" : "2014-04-21T05:36:05.147Z",
            "sensorId" : "0x0013A00000000000",
            "id" : "ALJGM7voQpux5fujXtM2Qw"
        },
        "cycleCount" : 5,
        "status" : "complete",
        "isConfirmed" : false,
        "precedingEventId": "1cRsH7KQTeONMzjSuRJ2er"
    },
    ...
 ]

 Returns 0 on failure
 
=cut

sub fetch_Appliances_Events_by_Appliance {
    my ($self,$appliance_id,$start,$end,$minPower,$perPage,$page) = @_;

    my $url = $self->{'Appliances_Events_url'}."?";

    # if REQUIRED parameter are defined, add them
    if (defined $appliance_id) {
      $url = $url . "applianceId=$appliance_id";
    }
    if (defined $start) {
      $url = $url . "&start=$start";
    }
    if (defined $end) {
      $url = $url . "&end=$end";
    }
    
    # if optional parameters are defined, add them
    if (defined $minPower) {
      $url = $url . "&minPower=$minPower";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Appliances_Events_Recent - Fetch events after a spceific time

 Get appliance events created or updated after a specific time.
 An event is an interval when an appliance was in use.
 
   This method accepts the following parameters:
      - $location_Id : id of a location - Required
      - $since       : yyyy-mm-ddThh:mm:ssZ - Required
                       specified using ISO8601 format
      - $minPower    : minimum average power - Optional
      - $perPage     : number of results per page - Optional
      - $page        : page number to return - Optional
 
 Returns an array of Perl data structures on success
  [
    {
        "id" : "1cRsH7KQTeONMzjSuRJ2aw",
        "appliance" : {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "television",
            "label" : "upstairs TV",
            "tags" : ["bedroom_television", "42 inch LED"],
            "locationId" : "0qX7nB-8Ry2bxIMTK0EmXw"
        },
        "start" : "2014-04-21T05:26:10.785Z",
        "end" : "2014-04-21T05:36:00.547Z",
        "guesses" : {"dryer1" : 0.78, "dishwasher_2014" : 0.12},
        "energy" : 247896,
        "averagePower" : 122,
        "groupIds" : [ "2pMROafiTA6huhV7Drrm1g", "4SmROBfiTA6huhV7Drrm1h" ],
        "lastCycle": {
            "groupId" : "4SmROBfiTA6huhV7Drrm1h",
            "start" : "2014-04-21T05:29:00.547Z",
            "end" : "2014-04-21T05:36:00.147Z",
            "energy" : 41846,
            "averagePower" : 122,
            "createdAt" : "2014-04-21T05:29:02.547Z",
            "updatedAt" : "2014-04-21T05:36:05.147Z",
            "sensorId" : "0x0013A00000000000",
            "id" : "ALJGM7voQpux5fujXtM2Qw"
        },
        "cycleCount" : 5,
        "status" : "complete",
        "isConfirmed" : false,
        "precedingEventId": "1cRsH7KQTeONMzjSuRJ2er"
    },
    ...
  ]
  Returns 0 on failure
 
=cut

sub fetch_Appliances_Events_Recent {
    my ($self,$location_Id,$since,$minPower,$perPage,$page) = @_;

    my $url = $self->{'Appliances_Events_url'}."?";

    # if REQUIRED parameter are defined, add them
    if (defined $location_Id) {
      $url = $url . "locationId=$location_Id";
    }
    if (defined $since) {
      $url = $url . "&since=$since";
    }
    
    # if optional parameters are defined, add them
    if (defined $minPower) {
      $url = $url . "&minPower=$minPower";
    }
    if (defined $perPage) {
      $url = $url . "&perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }

    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Location - Fetch information for a location

 Retrieves information about a particular location.
 
   $Neurio->fetch_Location($location_id);

   This method accepts the following parameters:
     - $location_id  : id of a location - Required
 
 Returns a Perl data structure on success
 {
    "name": "bob location",
    "timezone": "America/Vancouver",
    "sensors":
        [
            {
                "sensorId": "0x0000000000000001",
                "installCode": "5555",
                "sensorType": "neurio",
                "locationId": "222ROBfiTA6huhV7Drrrmg",
                "channels":
                    [
                        {
                             "sensorId": "0x0000000000000001",
                             "channel": 1,
                             "channelType": "phase_a",
                             "start": "2014-07-21T20:40:39.523Z",
                             "id": "2221OBfiTA6huhV7Drrrmg"
                        },
                         ...
                    ],
                "startTime": "2014-10-01T22:05:17.747Z",
                "id": "0x0000000000000001"
            },
            ...
        ],
    "energyRate": 0.1,
    "createdAt": "2014-10-01T22:05:22.406Z",
    "id": "2SMROBfiTA6huhV7Drrrmg"
}
 Returns 0 on failure
 
=cut

sub fetch_Location {
    my ($self,$location_id) = @_;
        
    # make sure $location_id is defined
    if (!defined $location_id) {
      $self->printLOG("\nNeurio->fetch_Location(): \$location_id is a required parameter\n\n");
      $self->{'last_code'}   = '0';
      $self->{'last_reason'} = 'Neurio->fetch_Location(): \$location_id is a required parameter';
      return 0;
    }
    my $url = $self->{'Location_url'}."/$location_id";
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_UserLocation - Fetch information for a user's location

 Retrieves information about a location for a particular user.
 
   $Neurio->fetch_UserLocation($user_id);

   This method accepts the following parameters:
     - $user_id  : id of a user - Required
 
 Returns a Perl data structure on success
 [
    {
        "name": "John",
        "timezone": "America/Vancouver",
        "sensors":
            [
                {
                    "sensorId": "0x0000000000000001",
                    "installCode": "5555",
                    "sensorType": "neurio",
                    "locationId": "222ROBfiTA6huhV7Drrrmg",
                    "channels":
                        [
                            {
                                 "sensorId": "0x0000000000000001",
                                 "channel": 1,
                                 "channelType": "phase_a",
                                 "start": "2014-07-21T20:40:39.523Z",
                                 "id": "2221OBfiTA6huhV7Drrrmg"
                            },
                             ...
                        ],
                    "startTime": "2014-10-01T22:05:17.747Z",
                    "id": "0x0000000000000001"
                },
                ...
            ],
        "energyRate": 0.1,
        "createdAt": "2014-10-01T22:05:22.406Z",
        "id": "2SMROBfiTA6huhV7Drrrmg"
    },
    ...
]
 Returns 0 on failure
 
=cut

sub fetch_UserLocation {
    my ($self,$user_id) = @_;
        
    # make sure $user_id is defined
    if (!defined $user_id) {
      $self->printLOG("\nNeurio->fetch_UserLocation(): \$user_id is a required parameter\n\n");
      $self->{'last_code'}   = '0';
      $self->{'last_reason'} = 'Neurio->fetch_UserLocation(): \$user_id is a required parameter';
      return 0;
    }
    my $url = $self->{'Location_url'}."/?$user_id";
    return $self->__process_get($url);
}




###################################################################################################
=head2 fetch_User - Fetch information about a particular user

 Retrieves information about a particular user.
 
   $Neurio->fetch_User($user_id);

   This method accepts the following parameters:
     - $user_id  : id of a user - Required
 
 Returns a Perl data structure on success
 {
    "id": 123,
    "name" : "Bruce Bane",
    "email" : "bruce@bane.com",
    "status" : "active",
    "createdAt" : "2014-04-21T22:28:32Z",
    "updatedAt" : "2014-04-21T22:45:32Z",
    "locations" : [
        {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "my home",
            "timezone" "America/Vancouver",
            "sensors" : [
                {
                    "id" : "0qX7nB-8Ry2bxIMTK0EmXw",
                    "name" : "sensor 1",
                    "type" : "powerblaster",
                    "channels" : [
                        {
                            "channel" : 1
                            "channelType" : "phase_a"
                        },
                        ...
                    ]
                },
                ...
            ]
        },
        ...
    ]
}
 Returns 0 on failure
 
=cut

sub fetch_User {
    my ($self,$user_id) = @_;
        
    # make sure $user_id is defined
    if (!defined $user_id) {
      $self->printLOG("\nNeurio->fetch_User(): \$user_id is a required parameter\n\n");
      $self->{'last_code'}   = '0';
      $self->{'last_reason'} = 'Neurio->fetch_User(): \$user_id is a required parameter';
      return 0;
    }
    my $url = $self->{'Users_url'}."/$user_id";
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_User_Current - Fetch information about the current user

 Retrieves information about the current user.
 
   $Neurio->fetch_User_Current();

   This method accepts no parameters:
 
 Returns a Perl data structure on success
 {
    "id": 123,
    "name" : "Bruce Bane",
    "email" : "bruce@bane.com",
    "status" : "active",
    "createdAt" : "2014-04-21T22:28:32Z",
    "updatedAt" : "2014-04-21T22:45:32Z",
    "locations" : [
        {
            "id" : "2SMROBfiTA6huhV7Drrm1g",
            "name" : "my home",
            "timezone" "America/Vancouver",
            "sensors" : [
                {
                    "id" : "0qX7nB-8Ry2bxIMTK0EmXw",
                    "name" : "sensor 1",
                    "type" : "powerblaster",
                    "channels" : [
                        {
                            "channel" : 1
                            "channelType" : "phase_a"
                        },
                        ...
                    ]
                },
                ...
            ]
        },
        ...
    ]
}
 Returns 0 on failure
 
=cut

sub fetch_User_Current {
    my ($self) = @_;
        
    my $url = $self->{'Users_url'}."/current";
    return $self->__process_get($url);
}






###################################################################################################
=head2 fetch_Sensors - Fetch information about all Neurio sensors 

 Retrieves information about all Neurio sensors.
 
   $Neurio->fetch_Sensors($perPage,$page);

   This method accepts the following parameters.
       - $perPage : number of results per page - Optional
       - $page    : page number to return - Optional
 
 Returns a Perl data structure on success
 [
      {
           "id" : "0x0013A00000000000",
           "sensorId" : "0x0013A00000000000",
           "email" : "example@example.com",
           "installCode" : "26huhV7Drrm1g",
           "sensorType" : "powerblaster",
           "locationId" : "hSMROBfiTA6huhV7Drrm1h",
           "startTime" : "2014-04-21T22:28:32Z",
           "endTime" : "2014-04-21T22:45:32Z",
           "channels" : [
               {
                    "id" : "4SMROBfiTA6huhV7Drrm1g",
                    "sensorId" : "2SMROBfiTA6huhV7Drrm1g",
                    "channel" : 1,
                    "channelType" : "consumption",
                    "name" : "channel1",
                    "start" : "2014-03-21T20:35:32Z",
                    "end" : "2014-03-21T20:38:32Z",
               },...
           ]
      },...
   ]
 Returns 0 on failure
 
=cut

sub fetch_Sensors {
    my ($self,$perPage,$page) = @_;
    
    my $url = $self->{'Sensors_url'};

    # if optional parameters are defined, add them
    if (defined $perPage) {
      $url = $url . "?perPage=$perPage";
    }
    if (defined $page) {
      $url = $url . "&page=$page";
    }
    
    return $self->__process_get($url);
}


###################################################################################################
=head2 fetch_Sensor - Fetch information about a specific Neurio sensor 

 Retrieves information about a specific Neurio sensor.
 
   $Neurio->fetch_Sensor($sensor_id);

   This method accepts the following parameters.
       - $sensor_id : ID of a sensor - Required
 
 Returns a Perl data structure on success
 {
       "id" : "0x0013A00000000000",
       "sensorId" : "0x0013A00000000000",
       "email" : "example@example.com",
       "installCode" : "26huhV7Drrm1g",
       "sensorType" : "powerblaster",
       "locationId" : "hSMROBfiTA6huhV7Drrm1h",
       "startTime" : "2014-04-21T22:28:32Z",
       "endTime" : "2014-04-21T22:45:32Z",
       "channels" : [
           {
                "id" : "4SMROBfiTA6huhV7Drrm1g",
                "sensorId" : "2SMROBfiTA6huhV7Drrm1g",
                "channel" : 1,
                "channelType" : "consumption",
                "name" : "channel1",
                "start" : "2014-03-21T20:35:32Z",
                "end" : "2014-03-21T20:38:32Z",
           },...
       ]
  }
 Returns 0 on failure
 
=cut

sub fetch_Sensor {
    my ($self,$sensor_id) = @_;

    my $url = $self->{'Sensors_url'}."/";

    # if REQUIRED parameter is defined, add it
    if (defined $sensor_id) {
      $url = $url . "$sensor_id";
    }
    
    return $self->__process_get($url);
}




###################################################################################################
=head2 get_version - return the version of the API being used

 Retrieves the version of the API being used.
 
   $Neurio->get_version();

   This method accepts no parameters:
 
 Returns a list containing the version and build of the API
 Returns 0 on failure
 
=cut

sub get_version {
    my $self             = shift;
    my $url              = $self->{'base_url'}."/status";
	my $response         = $self->__process_get($url);
	my ($version,$build) = split('\+build\.',$response->{'apiVersion'});
	
    return ($version,$build);
}


###################################################################################################
=head2 get_uptime - return the uptime of the Neurio Sensor being used

 Retrieves the uptime of the Neurio Sensor being used.
 
   $Neurio->get_uptime();

   This method accepts no parameters:
 
 Returns the uptime of the sensor
 Returns 0 on failure
 
=cut

sub get_uptime {
    my $self             = shift;
    my $url              = $self->{'base_url'}."/status";
	my $response         = $self->__process_get($url);
	
    return $response->{'uptime'};
}


###################################################################################################
=head2 dump_Object - shows the contents of the local Neurio object

 shows the contents of the local Neurio object in human readable form

   $Neurio->dump_Object();

   This method accepts no parameters
 
 Returns nothing
 
=cut

sub dump_Object {
    my $self  = shift;
    
    $self->printLOG("Key                     : ".substr($self->{'key'},                      0,120)."\n");
    $self->printLOG("SecretKey               : ".substr($self->{'secret'},                   0,120)."\n");
    $self->printLOG("Sensor_ID               : ".substr($self->{'sensor_id'},                0,120)."\n");
    $self->printLOG("Location_ID             : ".substr($self->{'location_id'},              0,120)."\n");
    $self->printLOG("Access_token            : ".substr($self->{'access_token'},             0,120)."\n");
    $self->printLOG("Base 64                 : ".substr($self->{'base64'},                   0,120)."\n");
    $self->printLOG("Base URL                : ".substr($self->{'base_url'},                 0,120)."\n");
    $self->printLOG("Samples_Recent_Live URL : ".substr($self->{'Samples_Recent_Live_url'},  0,120)."\n");
    $self->printLOG("Samples_Last_Live URL   : ".substr($self->{'Samples_Last_Live_url'},    0,120)."\n");
    $self->printLOG("Samples URL             : ".substr($self->{'Samples_url'},              0,120)."\n");
    $self->printLOG("Samples_Full URL        : ".substr($self->{'Samples_Full_url'},         0,120)."\n");
    $self->printLOG("Stats_Energy URL        : ".substr($self->{'Stats_Energy_url'},         0,120)."\n");
    $self->printLOG("Appliances URL          : ".substr($self->{'Appliances_url'},           0,120)."\n");
    $self->printLOG("Appliances_Stats URL    : ".substr($self->{'Appliances_Stats_url'},     0,120)."\n");
    $self->printLOG("Appliances_Events URL   : ".substr($self->{'Appliances_Events_url'},    0,120)."\n");
    $self->printLOG("Users URL               : ".substr($self->{'Users_url'},                0,120)."\n");
    $self->printLOG("Cycles URL              : ".substr($self->{'Cycles_url'},               0,120)."\n");
    $self->printLOG("Cycles Full URL         : ".substr($self->{'Cycles_Full_url'},          0,120)."\n");
    $self->printLOG("Cycles Group URL        : ".substr($self->{'Cycles_Groups_url'},        0,120)."\n");
    $self->printLOG("Edges URL               : ".substr($self->{'Edges_url'},                0,120)."\n");
    $self->printLOG("Sensors URL             : ".substr($self->{'Sensors_url'},              0,120)."\n");
    $self->printLOG("Analytics URL           : ".substr($self->{'Analytics_url'},            0,120)."\n");
    $self->printLOG("debug                   : ".substr($self->{'debug'},                    0,120)."\n");
    $self->printLOG("last_code               : ".substr($self->{'last_code'},                0,120)."\n");
    $self->printLOG("last_reason             : ".substr($self->{'last_reason'},              0,120)."\n");
    $self->printLOG("last_execution_time     : ".substr($self->{'last_exec_time'},           0,120)."\n");
    $self->printLOG("rateLimitRemaining      : ".substr($self->{'rateLimitRemaining'},       0,120)."\n");
    $self->printLOG("rateLimitReset          : ".substr($self->{'rateLimitReset'},           0,120)."\n");
    $self->printLOG("rateLimitLimit          : ".substr($self->{'rateLimitLimit'},           0,120)."\n");
    $self->printLOG("contentLength           : ".substr($self->{'contentLength'},            0,120)."\n");

    $self->printLOG("\n");
}

###################################################################################################
=head2 printLOG - prints to the screen and to a logfile if specified.

   $Neurio->printLOG($string);

   This method accepts the following parameters.
       - $string    : the string to print - Required
 
 Returns nothing.
 
=cut
sub printLOG{
  my $self   = shift;
  my $string = shift;
  
  print $string;
  
  if (defined $self->{'$fileHandle'}) {     # filehandle defined using $self->debug method
    my $FH = $self->{'$fileHandle'};
    print $FH $string;
  }
}


###################################################################################################
=head2 get_last_reason - returns the text generated by the most recent fetch

 Returns the HTTP Header reason for the most recent fetch command

   $Neurio->get_last_reason();

   This method accepts no parameters
 
 Returns the textual reason
 
=cut

sub get_last_reason {
    my $self  = shift;
    return $self->{'last_reason'};
}

###################################################################################################
=head2 get_last_code - returns the code generated by the most recent fetch

 Returns the HTTP Header code for the most recent fetch command

   $Neurio->get_last_code();

   This method accepts no parameters
 
 Returns the numeric code
 
=cut

sub get_last_code {
    my $self  = shift;
    return $self->{'last_code'};
}

###################################################################################################
=head2 get_last_exec_time - returns the execution time for the last fetch

 Returns the number of milliseconds it took for the last fetch call

   $Neurio->get_last_exec_time();

   This method accepts no parameters
 
 Returns the number of milliseconds
 
=cut

sub get_last_exec_time {
    my $self  = shift;
    return $self->{'last_exec_time'};
}





###################################################################################################
###################################################################################################

sub __process_get {
    my ($self,$url) = @_;
    my $time_before = gettimeofday;
    my $response    = $self->{'ua'}->get($url,"Authorization"=>"Bearer ".$self->{'access_token'});
    my $time_after  = gettimeofday;

	$self->printLOG("  GET from URL: $url\n");
    $self->{'last_exec_time'}     = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}          = $response->code;
    $self->{'rateLimitRemaining'} = $response->header('ratelimit-remaining');
    $self->{'rateLimitReset'}     = $response->header('ratelimit-reset');
    $self->{'rateLimitLimit'}     = $response->header('ratelimit-limit');
    $self->{'contentLength'}      = $response->header('content-length');

	if ($self->{'debug'}) {$self->printLOG("  Response:".($response->content)."\n");}
	if ($self->{'debug'}) {$self->printLOG("  Response code:".$response->code."\n\n");}
	if ($self->{'debug'}) {$self->printLOG(Dumper ($response));}

    if ($response->is_success()) {
      $self->{'last_reason'} = '';
      if ($response->content eq '') {   # work around for JSON module which does not handle blank content well
        return "";
      } else {
        return decode_json($response->content);
      }
    } else {
      $self->{'last_reason'} = $response->message;
      if ($self->{'debug'}) {$self->printLOG("\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n");}
      return 0;
    }
}

###################################################################################################
###################################################################################################

sub __process_put {
    my ($self,$url,$params) = @_;
    my $time_before         = gettimeofday;
	my $encoded             = encode_json($params);
    my $response            = $self->{'ua'}->put($url,"Authorization"=>"Bearer ".$self->{'access_token'}, Content_Type => 'application/json', content => $encoded);
    my $time_after          = gettimeofday;

	$self->printLOG("  PUT to URL: $url\n");

    $self->{'last_exec_time'} = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}      = $response->code;

	if ($self->{'debug'}) {$self->printLOG("  Response:".($response->content)."\n");}
	if ($self->{'debug'}) {$self->printLOG("  Response code:".$response->code."\n\n");}

    if ($response->is_success()) {
      $self->{'last_reason'} = '';
      if ($response->content eq '') {   # work around for JSON module which does not handle blank content well
        return "";
      } else {
        return decode_json($response->content);
      }
    } else {
      $self->{'last_reason'} = $response->message;
      if ($self->{'debug'}) {$self->printLOG("\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n");}
      return 0;
    }
}

###################################################################################################
###################################################################################################

sub __process_post {
    my ($self,$url,$params) = @_;
    my $time_before         = gettimeofday;
	my $encoded             = encode_json($params);
    my $response            = $self->{'ua'}->post($url,"Authorization"=>"Bearer ".$self->{'access_token'}, Content_Type => 'application/json', content => $encoded);
    my $time_after          = gettimeofday;

	$self->printLOG("  POSTed to URL: $url\n");

    $self->{'last_exec_time'} = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}      = $response->code;

	if ($self->{'debug'}) {$self->printLOG("  Response:".($response->content)."\n");}
	if ($self->{'debug'}) {$self->printLOG("  Response code:".$response->code."\n\n");}

    if ($response->is_success()) {
      $self->{'last_reason'} = '';
      if ($response->content eq '') {   # work around for JSON module which does not handle blank content well
        return "";
      } else {
        return decode_json($response->content);
      }
    } else {
      $self->{'last_reason'} = $response->message;
      if ($self->{'debug'}) {$self->printLOG("\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n");}
      return 0;
    }
}

###################################################################################################
###################################################################################################

sub __process_patch {
    my ($self,$url,$params) = @_;
    my $time_before         = gettimeofday;
	my $encoded             = encode_json($params);
	my $request             = HTTP::Request->new(PATCH => $url);
    $request->content($encoded);
    $request->header('Authorization' => "Bearer ".$self->{'access_token'});
    $request->header('Content_Type'  => "application/json");
	my $response            = $self->{'ua'}->request($request);
    my $time_after          = gettimeofday;

	$self->printLOG("  PATCHed URL: $url\n");

    $self->{'last_exec_time'} = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}      = $response->code;

	if ($self->{'debug'}) {$self->printLOG("  Response:".($response->content)."\n");}
	if ($self->{'debug'}) {$self->printLOG("  Response code:".$response->code."\n\n");}

    if ($response->is_success()) {
      $self->{'last_reason'} = '';
      if ($response->content eq '') {   # work around for JSON module which does not handle blank content well
        return "";
      } else {
        return decode_json($response->content);
      }
    } else {
      $self->{'last_reason'} = $response->message;
      if ($self->{'debug'}) {$self->printLOG("\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n");}
      return 0;
    }
}

###################################################################################################
###################################################################################################

sub __process_delete {
    my ($self,$url,$params) = @_;
    my $time_before         = gettimeofday;
    if (!defined $params) {
      $params = {};
    }
	my $encoded             = encode_json($params);
    my $response            = $self->{'ua'}->delete($url,"Authorization"=>"Bearer ".$self->{'access_token'}, Content_Type => 'application/json', content => $encoded);
    my $time_after          = gettimeofday;

	$self->printLOG("  DELETEd from URL: $url\n");

    $self->{'last_exec_time'} = eval{($time_after-$time_before)*1000};
    $self->{'last_code'}      = $response->code;

	if ($self->{'debug'}) {$self->printLOG("  Response:".($response->content)."\n");}
	if ($self->{'debug'}) {$self->printLOG("  Response code:".$response->code."\n");}
	
    if ($response->is_success()) {
      $self->{'last_reason'} = '';
      if ($response->content eq '') {   # work around for JSON module which does not handle blank content well
        return "";
      } else {
        return decode_json($response->content);
      }
    } else {
      $self->{'last_reason'} = $response->message;
      if ($self->{'debug'}) {$self->printLOG("\n".(caller(1))[3]."(): Failed with return code ".$self->get_last_code()." - ".$self->get_last_reason()."\n");}
      return 0;
    }
	
}

###################################################################################################
=head1 AUTHOR

Kedar Warriner, C<kedar at cpan.org>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-device-Neurio at rt.cpan.org>
 or through the web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-Neurio
 I will be notified, and then you'll automatically be notified of progress on 
 your bug as I make changes.

=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

  perldoc Device::Neurio

 You can also look for information at:

=over 5

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-Neurio>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-Neurio>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-Neurio>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-Neurio/>

=back

=head1 ACKNOWLEDGEMENTS

 Many thanks to:
  The guys at Energy Aware Technologies for creating the Neurio sensor and 
      developping the API.
  Everyone involved with CPAN.

=head1 LICENSE AND COPYRIGHT

 Copyright 2014 Kedar Warriner <kedar at cpan.org>.

 This program is free software; you can redistribute it and/or modify it
 under the terms of either: the GNU General Public License as published
 by the Free Software Foundation; or the Artistic License.

 See http://dev.perl.org/licenses/ for more information.

=cut

#******************************************************************************
1; # End of Device::Neurio - Return success to require/use statement
#******************************************************************************


