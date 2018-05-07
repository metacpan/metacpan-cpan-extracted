#!/usr/bin/perl -w

use strict;
use Lab::Instrument::TRMC2;
use Time::HiRes qw/sleep/;
use Time::HiRes qw/tv_interval/;
use Time::HiRes qw/gettimeofday/;
use Lab::Measurement;


# Where do you want to go today?
my @T=(0.025,0.035,0.040,0.050,0.060,0.070,0.080,0.090,0.100,0.200,0.300,0.400,0.500,0.600,0.700);

# Sweep rates for different temperature ranges
my $T_sweep_slow=0.001;         #K/min
my $T_sweep_medium=0.002;       #K/min
my $T_sweep_fast=0.005;         #K/min
my $T_sweep=$T_sweep_slow;      #K/min
my $T_sweep_rate_switch_slow=0.080; #K
my $T_sweep_rate_switch_medium=0.300;   #K

# Thermalization times for different temperature ranges
my $T_wait_sp_hot=900;          #sec
my $T_wait_sp_cold=1200;        #sec
my $T_wait_sp=$T_wait_sp_hot;       #sec
my $T_wait_sp_cold_switch=0.080;    #K

# Thermometer channel numbers
my $T_channel_sample=3;
my $T_channel_mc=5;


my $TRMC= new Lab::Instrument::TRMC2(0,0);


# initialize the temperature part

printf "Init TRMC2... ";
$TRMC->TRMC2init;
printf "done.\n";

$TRMC->TRMC2_Start_Sweep(0);            # dont sweep for now
$TRMC->TRMC2_Set_T(.3e-4);          # set temperature to 0.03mK ??? what is set here ???

my @allmeas=$TRMC->TRMC2_AllMEAS();     # read out all channels?
printf "ALLMEAS=@allmeas\n";


# Loop over all temperatures where measurements should be done

for my $T_set (@T){

  # Sweep the setpoint slowly to the target temperature

  $TRMC->TRMC2_Start_Sweep(0);
  my $T_now=$TRMC->TRMC2_get_T($T_channel_sample);  # get the current temperature
  my $T_setpoint=$TRMC->TRMC2_set_SetPoint($T_now); # set the setpoint to the current temperature
 
  if ($T_set<=$T_sweep_rate_switch_slow){$T_sweep=$T_sweep_slow}
    elsif($T_set<=$T_sweep_rate_switch_medium){$T_sweep=$T_sweep_medium}
    else{$T_sweep=$T_sweep_fast};       # set the appropriate sweep rate for temperature
    
    
  $TRMC->TRMC2_Set_T_Sweep($T_set,$T_sweep,5);  # Set Point, Rate K/min, waiting time at the end
  $TRMC->TRMC2_Set_T_Sweep($T_set,$T_sweep,5);  # 2x for safety --- huh? why?

  $TRMC->TRMC2_Start_Sweep(1);
  
  my $T_sweeptime=abs($T_now-$T_set)/($T_sweep)*60; # predicted sweep time in seconds
  my $Time_T_start_sweep=[gettimeofday()];
  printf "Starting temperature sweep\n Tnow=$T_now\tTset=$T_set\n";
  
  while(1){
    # this loop is 1) waiting for the sweep to finish and 2) giving diagnostic output
    
    my $t_T=tv_interval($Time_T_start_sweep);   # time difference since sweep start
    $T_now=$TRMC->TRMC2_get_T($T_channel_sample);
    my $T_sp_now=$TRMC->TRMC2_get_SetPoint();
    
    printf "Tset=$T_set\tTset,now=$T_sp_now\tTnow=$T_now\n";
    printf ("t_T=%d sec\tt_sweep=%d\tt_wait=%d sec\t DeltaT/T=%.3f\n", $t_T, \
      $T_sweeptime, $T_wait_sp,abs($T_now-$T_set)/($T_set+1e-20));
      
    if  ( $t_T>=$T_sweeptime ) { last }; #and $T_sp_now==$T_set
    sleep(1);
  };
  
  # Let the sample thermalize at target temperature
  
  printf "Start waiting for sample thermalization\n";

  my $t_start_wait=[gettimeofday()];
  
  if ($T_set<=$T_wait_sp_cold_switch){ $T_wait_sp=$T_wait_sp_cold;printf "Using cold waiting time $T_wait_sp\n"; }
    else{ $T_wait_sp=$T_wait_sp_hot; printf "Using hot waiting time $T_wait_sp\n"; };
    
  while(1){
    my $t_T=tv_interval($t_start_wait);
    if ($t_T>=$T_wait_sp) { last }; # end loop after waiting correct time
    
    printf ("t_T=%d sec\tt_wait=%d sec\n",$t_T,$T_wait_sp); # debug output
    sleep(1);
  };

  $T_now=$TRMC->TRMC2_get_T($T_channel_sample);
  printf "T setpoint reached: Tnow= $T_now\tTset=$T_set\n";

  # Now do the measurement for the temperature

  ##############################################################################
  # MEASUREMENT
  ##############################################################################


  ##############################################################################
  # END MEASUREMENT
  ##############################################################################
  

};


# End of the whole script: return to base temperature

printf "Switching heater off\n";
$TRMC->TRMC2_Heater_Control_On(0);

