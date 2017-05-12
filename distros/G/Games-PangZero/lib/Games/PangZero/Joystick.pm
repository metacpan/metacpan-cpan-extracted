##########################################################################
package Games::PangZero::Joystick;
##########################################################################

use vars qw(@Games::PangZero::Joysticks @Games::PangZero::JoystickButtons);

sub InitJoystick {
  my ($numJoysticks, $joystick, $numButtons, $i);

  $numJoysticks = SDL::Joystick::num_joysticks();
  for ($i = 0; $i < $numJoysticks; $i++) {
    print STDERR "Found joystick " , $i+1 , ": " , SDL::Joystick::name($i), "\n";
    $joystick   = SDL::Joystick->new($i);
    next unless $joystick;
    $numButtons = SDL::Joystick::num_buttons($joystick);
    next unless $numButtons;
    push @Games::PangZero::Joysticks, $joystick;
    push @Games::PangZero::JoystickButtons, $numButtons;
    print STDERR "Joystick opened, $numButtons buttons.\n";
  }
}

sub ReadJoystick {
  my ($readBothAxes) = @_;
  my ($i, $button, $buttonPressed);

  $i = 0;
  foreach my $joystick (@Games::PangZero::Joysticks) {
    my $axis = SDL::Joystick::get_axis($joystick, 0);
    if ($axis <= -10000) {
      $Games::PangZero::Events{"L$i"} = $Games::PangZero::MenuEvents{LEFT} = 1 unless $Games::PangZero::Keys{"L$i"};
      $Games::PangZero::Keys{"L$i"} = 1;
      $Games::PangZero::Keys{"R$i"} = 0;
    } elsif ($axis >= 10000) {
      $Games::PangZero::Events{"R$i"} = $Games::PangZero::MenuEvents{RIGHT} = 1 unless $Games::PangZero::Keys{"R$i"};
      $Games::PangZero::Keys{"R$i"} = 1;
      $Games::PangZero::Keys{"L$i"} = 0;
    } else {
      $Games::PangZero::Keys{"L$i"} = 0;
      $Games::PangZero::Keys{"R$i"} = 0;
    }

    if ($readBothAxes) {
      $axis = SDL::Joystick::get_axis($joystick, 1);
      if ($axis <= -10000) {
        $Games::PangZero::Events{"U$i"} = $Games::PangZero::MenuEvents{UP} = 1 unless $Games::PangZero::Keys{"U$i"};
        $Games::PangZero::Keys{"U$i"} = 1;
        $Games::PangZero::Keys{"D$i"} = 0;
      } elsif ($axis >= 10000) {
        $Games::PangZero::Events{"D$i"} = $Games::PangZero::MenuEvents{DOWN} = 1 unless $Games::PangZero::Keys{"D$i"};
        $Games::PangZero::Keys{"D$i"} = 1;
        $Games::PangZero::Keys{"U$i"} = 0;
      } else {
        $Games::PangZero::Keys{"D$i"} = 0;
        $Games::PangZero::Keys{"U$i"} = 0;
      }
    }

    $buttonPressed = 0;
    for ($button = 0; $button < $Games::PangZero::JoystickButtons[$i]; $button++) {
      if (SDL::Joystick::get_button($joystick, $button)) {
        $buttonPressed = 1;
        last;
      }
    }
    if ($buttonPressed and not $Games::PangZero::Keys{"B$i"}) {
        $Games::PangZero::Events{"B$i"} = $Games::PangZero::MenuEvents{BUTTON} = 1;
    }
    $Games::PangZero::Keys{"B$i"} = $buttonPressed;
    $i++;
  }
}

1;
