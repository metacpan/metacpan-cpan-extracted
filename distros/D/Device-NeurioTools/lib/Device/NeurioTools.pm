package Device::NeurioTools;

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

our %EXPORT_TAGS = ( 'all' => [ qw( new 
    get_flat_cost get_flat_rate get_ISO8601_date get_ISO8601_time get_ISO8601_timezone 
    get_kwh_consumed get kwh_generated get_power_consumed get_TwoTier_cost 
    get_TwoTier_rate set_flat_rate set_ISO8601_timezone set_TwoTier_rate 
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

BEGIN
{
  if ($^O eq "MSWin32"){
    use Device::Neurio;
    use Time::Local;
    use DateTime::Format::ISO8601;
    use POSIX;
    use Data::Dumper;
  } else {
    use Device::Neurio;
    use Time::Local;
    use DateTime::Format::ISO8601;
    use POSIX;
    use Data::Dumper;
  }
}


=head1 NAME

Device::NeurioTools - More complex methods and tools for accessing data 
                      collected by a Neurio sensor module.

=head1 VERSION

Version 0.07

=cut

our $VERSION = '0.08';

###################################################################################################

=head1 SYNOPSIS

 This module allows access to more complex and detailed data derived from data 
 collected by a Neurio sensor.  This is done via an extended set of methods: 
   - new
   - connect
   - set_flat_rate
   - get_flat_rate
   - get_flat_cost
   - get_kwh
  
 Please note that in order to use this module you will require three parameters
 (key, secret, sensor_id) as well as an Energy Aware Neurio sensor installed in
 your house.

 The module is written entirely in Perl and has been developped on Raspbian Linux.


=head1 SAMPLE CODE

    use Device::Neurio;
    use Device::NeurioTools;

    $my_Neurio = Device::Neurio->new($key,$secret,$sensor_id);

    $my_Neurio->connect();

    $my_NeurioTools = Device::NeurioTools->new($my_Neurio,$debug);

    $my_NeurioTools->set_timezone();
    $my_NeurioTools->set_flat_rate(0.08);
    
    $start = "2014-06-24T00:00:00".$my_NeurioTools->get_timezone();
    $end   = "2014-06-24T23:59:59".$my_NeurioTools->get_timezone();
    $kwh   = $my_NeurioTools->get_kwh($start,"minutes",$end,"5");

    undef $my_NeurioTools;
    undef $my_Neurio;

=head2 EXPORT

All by default.


###################################################################################################

=head2 new - the constructor for a NeurioTools object

 Creates a new instance of NeurioTools which will be able to fetch data from 
 a unique Neurio sensor.

 my $Neurio = Device::NeurioTools->new($neurio, $debug);

   This method accepts the following parameters:
     - $neurio : a valid CONNECTED Neurio object
     - $debug  : enable or disable debug messages (disabled by default - optional)

 Returns 1 on success
 Returns 0 on failure
 
=cut

sub new {
    my $class = shift;
    my $self;

    $self->{'neurio'}         = shift;
    $self->{'debug'}          = shift;
	$self->{'flat_rate'}      = 0;
    $self->{'TwoTier_rate1'}  = 0;
    $self->{'TwoTier_cutoff'} = 0;
    $self->{'TwoTier_rate2'}  = 0;
	$self->{'timezone'}       = "+00:00";
    
    if (!defined $self->{'debug'}) {
      $self->{'debug'} = 0;
    }
    
    if (!defined $self->{'neurio'}) {
      $self->{'neurio'}->printLOG("NeurioTools->new(): a valid Neurio object is a REQUIRED parameter.\n");
      return 0;
    }
    bless $self, $class;
    return $self;
}


###################################################################################################

=head2 DESTROY - the destructor for a NeurioTools object

 Destroys a previously created NeuriTools object.
 
=cut
sub DESTROY {
    my $self = shift;

    print "\nDestroying ".ref($self)."...\n\n";

    undef $self->{'neurio'};
    undef $self->{'debug'};
	undef $self->{'flat_rate'};
    undef $self->{'TwoTier_rate1'};
    undef $self->{'TwoTier_cutoff'};
    undef $self->{'TwoTier_rate2'};
	undef $self->{'timezone'};
}


###################################################################################################

=head2 set_flat_rate - set the rate charged by your electicity provider

 Defines the rate charged by your electricity provider.

   $NeurioTools->set_flat_rate($rate);
 
   This method accepts the following parameters:
     - $rate      : rate charged per kwh - Required
 
 Returns 1 on success 
 Returns 0 on failure
 
=cut

sub set_flat_rate {
	my ($self,$rate) = @_;
	
    if (defined $rate) {
	  $self->{'flat_rate'} = $rate;
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_flat_rate(): $self->{'flat_rate'}\n");}
	  return 1;
    } else {
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_flat_rate(): No rate specified\n");}
      return 0;
    }
}


###################################################################################################

=head2 set_TwoTier_rate - set the two tier rates charged by your electicity provider

 Defines the two tier rates charged by your electricity provider.
 The two tiers are defined according to the power consumed.
 
 For example:
   - $0.05 for the first 20 kWh per day
   - $0.08 for the remaining kWh per day

   $NeurioTools->set_TwoTier_rate($rate1,$cutoff,$rate2);
 
   This method accepts the following parameters:
     - $rate1     : rate charged per kwh for usage up to the cutoff - Required
     - $cutoff    : power consumtion point in kWh at which the rate changes - Required
     - $rate2     : rate charged per kwh for usage abpve the cutoff - Required
 
 Returns 1 on success 
 Returns 0 on failure
 
=cut

sub set_TwoTier_rate {
    my ($self,$rate1,$cutoff,$rate2) = @_;
    
    if (defined $rate1 and defined $cutoff and defined $rate2) {
      $self->{'TwoTier_rate1'}  = $rate1;
      $self->{'TwoTier_cutoff'} = $cutoff;
      $self->{'TwoTier_rate2'}  = $rate2;
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_TwoTier_rate(): $self->{'TwoTier_rate1'}\n");}
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_TwoTier_rate(): $self->{'TwoTier_cutoff'}\n");}
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_TwoTier_rate(): $self->{'TwoTier_rate2'}\n");}
      return 1;
    } else {
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_TwoTier_rate(): No rate specified\n");}
      return 0;
    }
}


###################################################################################################

=head2 get_flat_rate - return the flat rate charged by your electicity provider

 Returns the value for the flat rate set using 'set_flat_rate()'

   $NeurioTools->get_flat_rate();
 
   This method accepts no parameters
 
 Returns rate 
 
=cut

sub get_flat_rate {
	my $self = shift;
    return $self->{'flat_rate'};
}


###################################################################################################

=head2 get_TwoTier_rate - return the cutoff and two tier rates charged by your electicity provider

 Returns the value for the cutoff and two tier rates set using 'set_TwoTier_rate()'

   $NeurioTools->get_TwoTier_rate();
 
   This method accepts no parameters
 
 Returns list containing cutoff and rates 
 
=cut

sub get_TwoTier_rate {
    my $self = shift;
    return ($self->{'TwoTier_rate1'},$self->{'TwoTier_cutoff'},$self->{'TwoTier_rate2'});
}


###################################################################################################

=head2 set_ISO8601_timezone - set the timezone offset for ISO8601

 Sets the timezone offset in ISO8601 format.  If no parameter is specified it 
 sets the system defined timezone offset.

   $NeurioTools->set_ISO8601_timezone($offset);
 
   This method accepts the following parameters:
     - $offset      : specified timezone offset in minutes - Optional
 
 Returns 1 on success 
 Returns 0 on failure
 
=cut

sub set_ISO8601_timezone {
	my ($self,$offset) = @_;
	my ($total,$hours,$mins,$tz);
	
    if (defined $offset) {
	  $total = $offset;
      $hours = sprintf("%+03d",$total / 60);
      $mins  = sprintf("%02d",$total % 60);
      $tz    = "$hours:$mins";
    } else {
      $tz    = strftime("%z", localtime(time()));
      substr($tz,3,0,":");
    }
    $self->{'timezone'} = $tz;
    if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->set_ISO8601_timezone(): $self->{'timezone'}\n");}
    
    return 1;
}


###################################################################################################

=head2 get_flat_cost - calculate the cost of consumed power for the specified period

 Calculates the cost of consumed power over the period specified.

   $NeurioTools->get_flat_cost($start,$granularity,$end,$frequency);
   
   This method requires that a 'flat rate' be set using the set_flat_rate() method
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
     - $frequency   : an integer - Optional
 
 Returns the cost on success 
 Returns 0 on failure
 
=cut

sub get_flat_cost {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $i=0;
    
    if ($self->{'flat_rate'} == 0 ) {
        if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->get_flat_cost(): Cannot calculate cost since rate is set to zero\n");}
        return 0;
    }
    
    my $kwh  = $self->get_kwh_consumed($start,$granularity,$end,$frequency);
    my $cost = $kwh*$self->{'flat_rate'};
    
    return $cost;
}


###################################################################################################

=head2 get_TwoTier_cost - calculate the cost of consumed power for the specified period

 Calculates the cost of consumed power over the period specified.

   $NeurioTools->get_TwoTier_cost($start,$granularity,$end,$frequency);
   
   This method requires that a 'TwoTier rate' be set using the set_TwoTier_rate() method
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
     - $frequency   : an integer - Optional
 
 Returns the cost on success 
 Returns 0 on failure
 
=cut

sub get_TwoTier_cost {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $i    = 0;
    my $cost = 0;
    
    if ($self->{'TwoTier_rate1'} == 0 or $self->{'TwoTier_cutoff'} == 0 or $self->{'TwoTier_rate2'} == 0) {
        if ($self->{'debug'}) {$self->{'neurio'}->printLOG("NeurioTools->get_TwoTier_cost(): Cannot calculate cost since a parameter is set to zero\n");}
        return 0;
    }
    
    my $kwh  = $self->get_kwh_consumed($start,$granularity,$end,$frequency);
    
    if ($kwh != 0) {
      if ($kwh <= $self->{'TwoTier_cutoff'}) {
        $cost = $kwh * $self->{'TwoTier_rate1'};
      } else {
        $cost = $self->{'TwoTier_cutoff'} * $self->{'TwoTier_rate1'};
        $cost = $cost + ($kwh - $self->{'TwoTier_cutoff'})*$self->{'TwoTier_rate2'};
      }
    }
    return $cost;
}


###################################################################################################

=head2 get_kwh_consumed - kwh of consumed power for the specified period

 Calculates the total kwh of consumed power over the period specified.

   $NeurioTools->get_kwh_consumed($start,$granularity,$end,$frequency);
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : an integer - Optional
 
 Returns the kwh on success 
 Returns 0 on failure
 
=cut

sub get_kwh_consumed {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $energy  = 0;
    my $samples = 0;
    my $kwh     = 0;
    
    my $data = $self->{'neurio'}->fetch_Stats_Energy($start,$granularity,$end,$frequency,"1","5000");
    if ($data != 0) {
      my $start_obj = DateTime::Format::ISO8601->parse_datetime($start);
      my $end_obj   = DateTime::Format::ISO8601->parse_datetime($end);
      my $dur_obj   = $end_obj->subtract_datetime($start_obj);
      my $duration  = eval($dur_obj->{'minutes'}*60+$dur_obj->{'seconds'});
    
      while (defined $data->[$samples]->{'consumptionEnergy'}) {
        $energy = $energy + $data->[$samples]->{'consumptionEnergy'};
        $samples++;
      }
      $kwh = $energy/(1000*3600);
    }
    
    return $kwh;
}


###################################################################################################

=head2 get_kwh_generated - kwh of generated power for the specified period

 Calculates the total kwh of generated power over the period specified.

   $NeurioTools->get_kwh_generated($start,$granularity,$end,$frequency);
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : an integer - Optional
 
 Returns the kwh on success 
 Returns 0 on failure
 
=cut

sub get_kwh_generated {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $samples = 0;
    my $power   = 0;
    my $kwh     = 0;
    
    my $data = $self->{'neurio'}->fetch_Samples($start,$granularity,$end,$frequency);
    if ($data != 0) {
      my $start_obj = DateTime::Format::ISO8601->parse_datetime($start);
      my $end_obj   = DateTime::Format::ISO8601->parse_datetime($end);
      my $dur_obj   = $end_obj->subtract_datetime($start_obj);
      my $duration  = eval($dur_obj->{'minutes'}*60+$dur_obj->{'seconds'});
    
      while (defined $data->[$samples]->{'generationPower'}) {
        $power = $power + $data->[$samples]->{'generationPower'};
        $samples++;
      }
      $kwh = $power/1000*$duration/60/60/$samples;
    }
    
    return $kwh;
}


###################################################################################################

=head2 get_energy_consumed - energy consumed for the specified period

 Calculates the total energy consumed over the period specified.

   $NeurioTools->get_energy_consumed($start,$granularity,$end,$frequency);
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : an integer - Optional
 
 Returns the energy on success 
 Returns 0 on failure
 
=cut

sub get_energy_consumed {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $samples = 0;
    my $energy  = 0;
    my $kwh     = 0;
    
    my $data = $self->{'neurio'}->fetch_Samples($start,$granularity,$end,$frequency);
    if ($data != 0) {
      my $start_obj = DateTime::Format::ISO8601->parse_datetime($start);
      my $end_obj   = DateTime::Format::ISO8601->parse_datetime($end);
      my $dur_obj   = $end_obj->subtract_datetime($start_obj);
      my $duration  = eval($dur_obj->{'minutes'}*60+$dur_obj->{'seconds'});
    
      while (defined $data->[$samples]->{'consumptionEnergy'}) {
        $energy = $energy + $data->[$samples]->{'consumptionEnergy'};
        $samples++;
      }
      return $energy;
    }
}


###################################################################################################

=head2 get_number_of_appliances - return the number of appliances

 Returns the number of appliances defined in the system.

   $NeurioTools->get_appliance_ID();
 
   This method accepts no parameters:
 
 Returns the number of appliances on success 
 Returns 0 on failure
 
=cut

sub get_number_of_appliances {
    my ($self) = @_;
    my $count  = 0;
    my $data   = $self->{'neurio'}->fetch_Appliances();
    
    if ((defined $data) && ($data !=0)) {
      foreach my $appliance (@{$data}) {
        $count++;
      }
    } else {
      $self->{'neurio'}->printLOG("  get_number_of_appliances: Failed to Fetch Appliance ID\n");
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG(Dumper($data));}
    }
    return $count;
}

###################################################################################################

=head2 get_appliance_ID - return the id for the appliance specified

 Returns the appliance ID for the name and label specified.

   $NeurioTools->get_appliance_ID($name,$label);
 
   This method accepts the following parameters:
     - $name  : textual name of appliance - Required
     - $label : textual label of appliance - Optional
 
 Returns the appliance ID on success 
 Returns 0 on failure
 
=cut

sub get_appliance_ID {
    my ($self,$name) = @_;
    my $data         = $self->{'neurio'}->fetch_Appliances();
    my $appliance;
    
    if ((defined $data) && ($data !=0)) {
      foreach $appliance (@{$data}) {
        if ($appliance->{'name'} eq $name) {
          $self->{'neurio'}->printLOG("  appliance_ID: ".$appliance->{'id'}."\n");
          return $appliance->{'id'};
        }
      }
    } else {
      $self->{'neurio'}->printLOG("  get_appliance_ID: Failed to Fetch Appliance ID\n");
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG(Dumper($data));}
    }
    $self->{'neurio'}->printLOG("  get_appliance_ID: No Appliance ID found for $name\n");
    return 0;
}

###################################################################################################

=head2 get_cycle_ID - return the id for the most recent cycle

 Returns the ID for the most recent cycle.

   $NeurioTools->get_cycle_ID();
 
   This method accepts no parameters
 
 Returns the cycle ID on success 
 Returns 0 on failure
 
=cut

sub get_cycle_ID {
    my $self = shift;
    my $cycle;
    my $data = $self->{'neurio'}->fetch_Cycles_by_Sensor();

    if ((defined $data) && ($data !=0)) {
      $self->{'neurio'}->printLOG("  cycle_ID: ".$data->[0]->{'id'}."\n");
      return $data->[0]->{'id'};
    } else {
      $self->{'neurio'}->printLOG("  get_cycle_ID: Failed to Fetch Cycle ID\n");
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG(Dumper($data));}
      return 0;
    }
}

###################################################################################################

=head2 get_cycle_group_ID - return the id for the most recent cycle group

 Returns the ID for the most recent cycle group.

   $NeurioTools->get_cycle_group_ID();
 
   This method accepts no parameters
 
 Returns the cycle group ID on success 
 Returns 0 on failure
 
=cut

sub get_cycle_group_ID {
    my $self = shift;
    my $data = $self->{'neurio'}->fetch_Cycle_Groups_by_Sensor();

    if ((defined $data)  && ($data !=0)){
      $self->{'neurio'}->printLOG("  cycle_Group_ID: ".$data->[0]->{'id'}."\n");
      return $data->[0]->{'id'};
    } else {
      $self->{'neurio'}->printLOG("  get_cycle_group_ID: Failed to Fetch Cycle Group ID\n");
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG(Dumper($data));}
      return 0;
    }
    }

###################################################################################################

=head2 get_edges_ID - return an edges id

 Returns and edges ID.

   $NeurioTools->get_edges_ID();
 
   This method accepts no parameters
 
 Returns the edges ID on success 
 Returns 0 on failure
 
=cut

sub get_edge_ID {
    my $self = shift;
    my $data = $self->{'neurio'}->fetch_Cycles_by_Sensor();

    if ((defined $data->[0]->{'upEdge'}) && ($data != 0)) {
      $self->{'neurio'}->printLOG("  edges_ID: ".$data->[0]->{'upEdge'}->{'id'}."\n");
      return $data->[0]->{'upEdge'}->{'id'};
    } elsif ((defined $data->[0]->{'downEdge'}) && ($data != 0)) {
      $self->{'neurio'}->printLOG("  edges_ID: ".$data->[0]->{'downEdge'}."\n");
      return $data->[0]->{'downEdge'};
    } else {
      $self->{'neurio'}->printLOG("  get_edge_ID: Failed to Fetch Edge\n");
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG(Dumper($data));}
      return 0;
    }
}

###################################################################################################

=head2 get_power_consumed - power consumed for the specified period

 Calculates the total power  consumed over the period specified.

   $NeurioTools->get_energy_consumed($start,$granularity,$end,$frequency);
 
   This method accepts the following parameters:
     - $start       : yyyy-mm-ddThh:mm:ssZ - Required
                      specified using ISO8601 format
     - $granularity : seconds|minutes|hours|days - Required
     - $end         : yyyy-mm-ddThh:mm:ssZ - Optional
                      specified using ISO8601 format
     - $frequency   : an integer - Optional
 
 Returns the energy on success 
 Returns 0 on failure
 
=cut

sub get_power_consumed {
    my ($self,$start,$granularity,$end,$frequency) = @_;
    my $samples = 0;
    my $power   = 0;
    
    my $data = $self->{'neurio'}->fetch_Samples($start,$granularity,$end,$frequency);
    if ($data != 0) {
      my $start_obj = DateTime::Format::ISO8601->parse_datetime($start);
      my $end_obj   = DateTime::Format::ISO8601->parse_datetime($end);
      my $dur_obj   = $end_obj->subtract_datetime($start_obj);
      my $duration  = eval($dur_obj->{'minutes'}*60+$dur_obj->{'seconds'});
    
      while (defined $data->[$samples]->{'consumptionPower'}) {
        $power = $power + $data->[$samples]->{'consumptionPower'};
        $samples++;
      }
      return $power;
    }
}


###################################################################################################

=head2 get_ISO8601_time - convert linux time to the time part of ISO8601

 Returns the time part in ISO8601 format of the specified linux time.

   $NeurioTools->get_ISO8601_time($time);
 
   This method accepts the following parameters:
     - $time       : linux time - Required
 
 Returns time part of ISO8601 format on success 
 Returns 0 on failure
 
=cut

sub get_ISO8601_time {
    my ($self,$time) = @_;
    my $ISO8601_time;
    
    if (!defined $time) {
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("\$$time is a required parameter\n");}
      return 0;
    } else {
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
      $ISO8601_time = sprintf("%02d:%02d:%02d",$hour,$min,$sec);
    } 
    return $ISO8601_time;
}


###################################################################################################

=head2 get_ISO8601_date - convert linux time to the date part of ISO8601

 Returns the date part in ISO8601 fomrat of the specified linux time.

   $NeurioTools->get_ISO8601_date($time);
 
   This method accepts the following parameters:
     - $time       : linux time - Required
 
 Returns date part of ISO8601 format on success 
 Returns 0 on failure
 
=cut

sub get_ISO8601_date {
    my ($self,$time) = @_;
    my $ISO8601_date;
    
    if (!defined $time) {
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("\$$time is a required parameter\n");}
      return 0;
    } else {
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
      $ISO8601_date = sprintf("%04d\-%02d\-%02d",$year+1900,$mon+1,$mday);
    }
    return $ISO8601_date;
}


###################################################################################################

=head2 get_ISO8601_timezone - return the ISOS8601 timezone offset

 Returns the timezone part in ISO8601 format for the current location
 from the value specified with set_ISO8601_timezone

   $NeurioTools->get_ISO8601_timezone();
 
   This method accepts no parameters
 
 Returns timezone offset 
 
=cut

sub get_ISO8601_timezone {
	my $self = shift;
    return $self->{'timezone'};
}


###################################################################################################

=head2 get_ISO8601 - return the entire ISOS8601 formatted date/time/timezone

 Returns the entire ISO8601 formatted date/time/timezone based on the time
 parameter passed

   $NeurioTools->get_ISO8601($time);
 
   This method accepts the following parameters:
     - $time       : linux time - Required
 
 Returns entire ISO8601 string on success 
 Returns 0 on failure
 
=cut

sub get_ISO8601 {
    my ($self,$time) = @_;
    my $ISO8601;
    
    if (!defined $time) {
      if ($self->{'debug'}) {$self->{'neurio'}->printLOG("\$$time is a required parameter\n");}
      return 0;
    } else {
      my $tz = $self->get_ISO8601_timezone();
      my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)=localtime($time);
      $ISO8601 = sprintf("%04d\-%02d\-%02dT%02d:%02d:%02d".$tz,$year+1900,$mon+1,$mday,$hour,$min,$sec);
    }
    return $ISO8601;
}


###################################################################################################

=head1 AUTHOR

Kedar Warriner, C<kedar at cpan.org>

=head1 BUGS

 Please report any bugs or feature requests to C<bug-device-NeurioTools at rt.cpan.org>
 or through the web interface at http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Device-NeurioTools
 I will be notified, and then you'll automatically be notified of progress on 
 your bug as I make changes.


=head1 SUPPORT

 You can find documentation for this module with the perldoc command.

  perldoc Device::NeurioTools


 You can also look for information at:

=over 5

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-NeurioTools>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-NeurioTools>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-NeurioTools>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-NeurioTools/>

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

#************************************************************************
1; # End of Device::NeurioTools - Return success to require/use statement
#************************************************************************

