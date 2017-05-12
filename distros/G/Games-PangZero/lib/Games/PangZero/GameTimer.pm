##########################################################################
package Games::PangZero::GameTimer;
##########################################################################

use vars qw($FirstTick $LastTick $TotalAdvances $LastFpsTick $LastFps $Fps);

sub ResetTimer {
  $FirstTick      = SDL::get_ticks();
  $LastTick       = $LastFpsTick = $FirstTick;
  $TotalAdvances  = 0;
  $Fps            = $LastFps = 0;
}

sub GetAdvances {
  my ($ticks, $advance);

  $ticks          = SDL::get_ticks();
  $advance        = int(($ticks - $FirstTick) / 10) - $TotalAdvances;
  $TotalAdvances += $advance;
  
  # Calculate frames per second;
  ++$Fps if $advance > 0;
  if ($ticks - $LastFpsTick > 1000) {
    $LastFps     = $Fps;
    $LastFpsTick = $ticks;
    $Fps         = 0;
  }
  
  return $advance;
}

sub GetFramesPerSecond {
  return $LastFps;
}

1;
