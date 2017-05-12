use LEGO::NXT;
use Data::Dumper;
use Net::Bluetooth;
use strict;

my $addr = $ARGV[0];
my $port = 1;

die "No Bluetooth Address Specified!\n" if !$addr;

$| = 1;

my $res;
my $bt = new NXT($addr,$port);

$res = $bt->play_sound_file($Nxt::RET, 0,'! Attention.rso');
print Dumper($res);

$res  = $bt->get_battery_level($Nxt::RET);
print Dumper($res);

exit;

#Also try these!
#
#$res = $bt->play_tone($Nxt::RET,220*2,500);
#$bt->set_output_state($Nxt::NORET, 0x01, 100, $Nxt::MOTORON|$Nxt::Regulated, $Nxt::REGULATION_MODE_MOTOR_SPEED, 0, $Nxt::MOTOR_RUN_STATE_RUNNING, 0  );
#$bt->set_output_state($Nxt::NORET, 0x02,  75, $Nxt::MOTORON|$Nxt::Regulated, $Nxt::REGULATION_MODE_MOTOR_SPEED, 0, $Nxt::MOTOR_RUN_STATE_RUNNING, 0 );
#$res = $bt->get_output_state($Nxt::RET, 1);
#$res = $bt->get_input_values($Nxt::RET, 0);

