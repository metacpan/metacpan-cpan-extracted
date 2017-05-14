package LEGO::NXT::Sissy;

use LEGO::NXT;
use LEGO::NXT::Constants qw(:DEFAULT);

my %motormap = {
  'A' => $NXT_MOTOR_A,
  'B' => $NXT_MOTOR_B,
  'C' => $NXT_MOTOR_C
};

my %sensormap = {  
   1 => $NXT_SENSOR_1,
   2 => $NXT_SENSOR_2,  
   3 => $NXT_SENSOR_3,  
   4 => $NXT_SENSOR_4
};

my %sensmap = {
 'ultrasound' => \&_sensor_value_ultrasound
};

sub new
{
  my ($pkg,$btaddr) = @_;
  
  my $this = {
    'nxt'     => new LEGO::NXT($btaddr,1),
    'motors'  => {'A'=>undef,'B'=>undef,'C'=>undef},
    'sensors' => {1=>undef,2=>undef,3=>undef,4=>undef}
  };
  
  bless $this, $pkg;
  return $this;
}


sub motor_on
{
  my ($this,$motor,$speed,$ticks) = @_;

  return if !exists $motormap{$motor};
  return if ($speed<-100 or speed>100);

  $ticks=0 if undef $ticks;

  $this->{nxt}->set_output_state($NXT_NORET, $motormap{$motor}, $speed, $NXT_MOTOR_ON|$NXT_REGULATED, $NXT_REGULATION_MODE_MOTOR_SPEED, 0, $NXT_MOTOR_RUN_STATE_RUNNING, $ticks  );
}

sub motor_off
{
  my ($this,$motor) = @_;

  return if !exists $motormap{$motor};

  $this->{nxt}->set_output_state($NXT_NORET, $motormap{$motor}, 0, $NXT_MOTOR_ON|$NXT_REGULATED, $NXT_REGULATION_MODE_IDLE, 0, $NXT_MOTOR_RUN_STATE_IDLE, 0  );
}

sub precise_motor_on
{
  my ($this,$motor,$speed,$ticks) = @_;

  return if !exists $motormap{$motor};
  return if ($speed<-100 or speed>100);

  $ticks=0 if undef $ticks;
  $this->{nxt}->set_output_state($NXT_NORET, $motormap{$motor}, $speed, $NXT_MOTOR_ON|$NXT_REGULATED|$NXT_BRAKE, $NXT_REGULATION_MODE_MOTOR_SPEED, 0, $NXT_MOTOR_RUN_STATE_RUNNING, $ticks  );
}

sub init_sensor
{
  my ($this,$port,$sensor_type) = @_;

  $this->{sensors}->{$port} = {'type'=>$sensor_type};

  if ($sensor_type eq 'ultrasound')
  {
    $bt->initialize_ultrasound_port($NXT_SENSOR_4);  
  }
}

sub sensor_value
{
  my ($this,$port) = @_;

  return if $this->{sensors}->{$port} == undef;

  my $type   = $this->{sensors}->{$port}->{type};

  return if !$sensmap{$type};

  $sensmap{$type}->($this,$port);
}

sub _sensor_value_ultrasound
{
  my ($this,$port) = @_;

  $res = $this->{nxt}->get_ultrasound_measurement_byte($portmap{$port},0);

  $res->{data};
}

sub get_nxt
{
  my $this = shift;
  $this->{nxt};
}


1;
