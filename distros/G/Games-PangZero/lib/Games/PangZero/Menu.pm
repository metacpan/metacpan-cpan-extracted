##########################################################################
package Games::PangZero::Menu;
##########################################################################

use SDL::Events;
use Games::PangZero::FpsIndicator;
use Games::PangZero::MenuItem;

@ISA  = qw(Games::PangZero::GameBase);
use vars qw(@syms);
@syms = qw(UNKNOWN FIRST BACKSPACE TAB CLEAR RETURN PAUSE ESCAPE SPACE EXCLAIM QUOTEDBL HASH DOLLAR AMPERSAND QUOTE LEFTPAREN RIGHTPAREN ASTERISK PLUS COMMA MINUS PERIOD SLASH 0 1 2 3 4 5 6 7 8 9 COLON SEMICOLON LESS EQUALS GREATER QUESTION AT LEFTBRACKET BACKSLASH RIGHTBRACKET CARET UNDERSCORE BACKQUOTE a b c d e f g h i j k l m n o p q r s t u v w x y z DELETE WORLD_0 WORLD_1 WORLD_2 WORLD_3 WORLD_4 WORLD_5 WORLD_6 WORLD_7 WORLD_8 WORLD_9 WORLD_10 WORLD_11 WORLD_12 WORLD_13 WORLD_14 WORLD_15 WORLD_16 WORLD_17 WORLD_18 WORLD_19 WORLD_20 WORLD_21 WORLD_22 WORLD_23 WORLD_24 WORLD_25 WORLD_26 WORLD_27 WORLD_28 WORLD_29 WORLD_30 WORLD_31 WORLD_32 WORLD_33 WORLD_34 WORLD_35 WORLD_36 WORLD_37 WORLD_38 WORLD_39 WORLD_40 WORLD_41 WORLD_42 WORLD_43 WORLD_44 WORLD_45 WORLD_46 WORLD_47 WORLD_48 WORLD_49 WORLD_50 WORLD_51 WORLD_52 WORLD_53 WORLD_54 WORLD_55 WORLD_56 WORLD_57 WORLD_58 WORLD_59 WORLD_60 WORLD_61 WORLD_62 WORLD_63 WORLD_64 WORLD_65 WORLD_66 WORLD_67 WORLD_68 WORLD_69 WORLD_70 WORLD_71 WORLD_72 WORLD_73 WORLD_74 WORLD_75 WORLD_76 WORLD_77 WORLD_78 WORLD_79 WORLD_80 WORLD_81 WORLD_82 WORLD_83 WORLD_84 WORLD_85 WORLD_86 WORLD_87 WORLD_88 WORLD_89 WORLD_90 WORLD_91 WORLD_92 WORLD_93 WORLD_94 WORLD_95 KP0 KP1 KP2 KP3 KP4 KP5 KP6 KP7 KP8 KP9 KP_PERIOD KP_DIVIDE KP_MULTIPLY KP_MINUS KP_PLUS KP_ENTER KP_EQUALS UP DOWN RIGHT LEFT INSERT HOME END PAGEUP PAGEDOWN F1 F2 F3 F4 F5 F6 F7 F8 F9 F10 F11 F12 F13 F14 F15 NUMLOCK CAPSLOCK SCROLLOCK RSHIFT LSHIFT RCTRL LCTRL RALT LALT RMETA LMETA LSUPER RSUPER MODE COMPOSE HELP PRINT SYSREQ BREAK MENU POWER EURO UNDO LAST );

sub Exit {
  my $self = shift;

  Games::PangZero::Config::SaveConfig();
  $self->SUPER::Exit();
}

sub SetGameSpeed {
  $Games::PangZero::GameSpeed = 1.0;
}

sub ShowTooltip {
  my $self = shift;
  my (@lines, $y, $yinc, $rect);

  @lines = @_;
  @lines = ("Pang Zero $Games::PangZero::VERSION (C) 2006 by UPi (upi\@sourceforge.net)",
    "Use cursor keys to navigate menu, Enter to select",
    "P pauses the game, Esc quits") unless scalar @lines;

  $Games::PangZero::ScoreFont->use();
  ($y, $yinc) = ($Games::PangZero::ScreenHeight + 35, 20);
  $rect       = SDL::Rect->new(0, $y, $Games::PangZero::PhysicalScreenWidth, $Games::PangZero::PhysicalScreenHeight - $y );
  SDL::Video::fill_rect( $Games::PangZero::Background, $rect, SDL::Color->new(0,0,0) );
  foreach (@lines) {
    SDLx::SFont::print_text(   $Games::PangZero::Background, 10, $y, $_ ) if $y + $yinc < $Games::PangZero::PhysicalScreenHeight;

    $y += $yinc;
  }
  $rect = SDL::Rect->new( 0, $Games::PangZero::ScreenHeight + 35, $Games::PangZero::PhysicalScreenWidth, $Games::PangZero::PhysicalScreenWidth - $y );
  SDL::Video::blit_surface($Games::PangZero::Background, $rect, $Games::PangZero::App, $rect);
  $Games::PangZero::MenuFont->use();
}

sub MenuAdvance {
  my $self = shift;

  my $advance = $self->CalculateAdvances();
  %Games::PangZero::Events = %Games::PangZero::MenuEvents = ();
  %Games::PangZero::GameEvents = ();
  Games::PangZero::HandleEvents('readbothaxes');
  while ($advance--) {
    $self->AdvanceGameObjects();
  }
  while (ref($Games::PangZero::GameObjects[$#Games::PangZero::GameObjects]) ne 'Games::PangZero::MenuItem') {
    unshift @Games::PangZero::GameObjects, (pop @Games::PangZero::GameObjects);
  }
  $self->DrawGame();
}

sub SetCurrentItemIndex {
  my ($self, $index) = @_;

  return if ($index < 0 or $index >= scalar @{$self->{menuItems}} or not $self->{menuItems}->[$index]->CanSelect());
  $self->{currentItemIndex} = $index;
  $self->{currentItem} = $self->{menuItems}->[$index];
  $self->{currentItem}->Select();
}

sub EnterSubMenu {
  my $self = shift;
  my ($recall, $menuItem);

  $recall->{oldItems} = $self->{menuItems};
  $recall->{oldCurrentItemIndex} = $self->{currentItemIndex};
  foreach $menuItem (@{$self->{menuItems}}) { $menuItem->Hide(); }
  $self->{menuItems} = [];

  return $recall;
}

sub LeaveSubMenu {
  my ($self, $recall) = @_;
  my ($menuItem);

  foreach $menuItem (@{$self->{menuItems}}) { $menuItem->HideAndDelete(); }
  $self->{menuItems} = $recall->{oldItems};
  foreach $menuItem (@{$self->{menuItems}}) { $menuItem->Show(); }
  $self->SetCurrentItemIndex($recall->{oldCurrentItemIndex});
  $self->{abortgame} = 0;
}

sub HandleUpDownKeys {
  my $self = shift;

  if ($Games::PangZero::MenuEvents{DOWN}) {
    $self->SetCurrentItemIndex( $self->{currentItemIndex} + 1 );
  }
  if ($Games::PangZero::MenuEvents{UP}) {
    $self->SetCurrentItemIndex( $self->{currentItemIndex} - 1 );
  }
}

sub KeyToText {
  my ($key) = @_;
  eval("SDLK_$_ eq $key") and return ucfirst(lc($_)) foreach @syms;
  print "No match for $key\n";
  return "???";
}

sub KeysToText {
  my $keys = shift;
  my ($retval);
  if ( $keys->[0] =~ /^[LRB](\d)+$/ ) {
    return "Joystick $1";
  }
  return join(' / ', KeyToText($keys->[0]), KeyToText($keys->[1]), KeyToText($keys->[2]) );
}

sub RunTutorial {
  my ($self, $ball)  = @_;
  my $recall         = $self->EnterSubMenu();
  my @oldGameObjects = @Games::PangZero::GameObjects;
  my %oldGuys        = %Guy::Guys;
  my %oldHarpoons    = %Harpoon::Harpoons;
  my $oldGame        = $Games::PangZero::Game;

  $Games::PangZero::ScoreFont->use();
  $Games::PangZero::Game = Games::PangZero::TutorialGame->new;
  $Games::PangZero::Game->SetChallenge($ball);
  $Games::PangZero::Game->Run();
  $Games::PangZero::MenuFont->use();
  $self->SetGameSpeed();

  foreach (@Games::PangZero::GameObjects) { $_->Clear(); }
  @Games::PangZero::GameObjects = @oldGameObjects;
  %Guy::Guys             = %oldGuys;
  %Harpoon::Harpoons     = %oldHarpoons;
  $Games::PangZero::Game        = $oldGame;
  $self->LeaveSubMenu($recall);
}

sub RunTutorialMenu {
  my $self = shift;
  my ($baseX, $menuItem);

  my $recall = $self->EnterSubMenu();
  $self->{title}->Hide();
  my $baseY = 50;

  my @tutorials = (
    ['n2', 'Normal Ball', 'There is nothing special about this ball. Just keep shooting it.'],
    ['b0', 'Bouncy Ball', 'This ball bounces higher than the normal ball.', 'Otherwise it behaves the same.'],
    ['h0', 'Hexa', 'The Hexa is weightless and travels in a straight line.', 'With practice you can shoot it just as easily as the normal ball.'],
    ['w1', 'Water Ball', 'The water ball pops each time it bounces.', 'This can create a tide of small balls fast.', 'Mop it up quickly.'],
    ['f1', 'Fragile Ball', 'The fragile ball shatters into little bits the moment it is hit.', 'Prepare for a shower of small balls.'],
    ['death', 'Death Ball', 'This ball cannot be killed with your harpoon.', 'Shooting will make it multiply. Too many death balls cause meltdown.', 'Evade it for 20 seconds to get rid of it.'],
    ['seeker', 'Seeker Ball', 'The seeker ball will chase you forever.', 'You have to keep moving and shooting to evade it.'],
    ['quake', 'Earthquake Ball', 'This ball is super heavy.', 'In fact the earth will quake each time it bounces.', 'Shoot it quickly, or it will send you flying.'],
    ['u0', 'Upside Down Ball', 'This crazy ball bounces on the top of the screen.', 'Maybe it came from an alternate universe,', 'where gravity is negative?'],
    ['super0, n1', 'Super Ball', 'The Super Ball is your friend. It will still kill you on touch.', 'The green super ball will pause the game for 8 seconds.', 'The gold super ball will kill every ball.'],
  );

  push @{$self->{menuItems}},
    Games::PangZero::MenuItem->new( 50, $baseY, "Back to main menu"),
    Games::PangZero::MenuItem->new( 50, $baseY += 40, "Run Demo" );

  $baseY = 110;
  $baseX = 50;
  foreach (@tutorials) {
    my @tutItem            = @{$_};
    my $challenge          = shift @tutItem;
    my $menuItem           = Games::PangZero::MenuItem->new( $baseX, $baseY += 40, @tutItem );
    $menuItem->{challenge} = $challenge;
    push @{$self->{menuItems}}, $menuItem;
    if ($baseY + 140 >= $Games::PangZero::ScreenHeight) {
      $baseY = 110;
      $baseX = 450;
    }
  }
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});
  $self->SetCurrentItemIndex(1);

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    $self->HandleUpDownKeys();

    if ($Games::PangZero::MenuEvents{LEFT} and $self->{currentItemIndex} > 1) {
      $self->SetCurrentItemIndex($self->{currentItemIndex} - 5);
    }
    if ($Games::PangZero::MenuEvents{RIGHT} and $self->{currentItemIndex} > 1) {
      $self->SetCurrentItemIndex($self->{currentItemIndex} + 5);
    }
    if ($Games::PangZero::MenuEvents{BUTTON}) {
      if (0 == $self->{currentItemIndex}) {
        last;
      } elsif (1 == $self->{currentItemIndex}) {
        $self->{result} = 'demo';
        last;
      } else {
        $self->RunTutorial($self->{currentItem}->{challenge});
      }
    }
  }

  $self->LeaveSubMenu($recall);
  $self->{title}->Show();
}

sub RunCredits {
  my ($self, $demo) = @_;
  my ($i, $ball, @balls);

  my $time           = $self->{anim};
  my $recall         = $self->EnterSubMenu();
  my @oldGameObjects = @Games::PangZero::GameObjects;
  foreach my $gameObject (@Games::PangZero::GameObjects) {
    $gameObject->Clear();
  }
  @Games::PangZero::GameObjects = ($self->{title});
  push @Games::PangZero::GameObjects, Games::PangZero::FpsIndicator->new();
  my ($y, $yinc) = (110, 36);
  push @{$self->{menuItems}}, (
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Written by: UPi <upi\@sourceforge.net>"),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Music by: SAdam" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Graphics by: UPi, DaniGM, EBlanca" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc * 1.5, "TESTERS" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Ulmar, Surba, Miki, Aisha, Descant" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc * 1.5, "http://apocalypse.rulez.org/pangzero" ),
  );
  foreach $i (@{$self->{menuItems}}) { $i->Center(); }

  for ($i = 0; $i < 20; ++$i) {
    $ball      = Games::PangZero::Ball::Spawn( $Games::PangZero::BallDesc{'credits1'}, 100, 1, 0 );
    $ball->{y} = $i * -5;
    push @balls, ($ball);
    $ball      = Games::PangZero::Ball::Spawn( $Games::PangZero::BallDesc{'credits2'}, $Games::PangZero::ScreenWidth - 132, -1, 0 );
    $ball->{y} = $i * -5;
    push @balls, ($ball);
  }
  push @Games::PangZero::GameObjects, @balls;
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    if ($demo) {
      last if %Games::PangZero::Events;
      last if $self->{anim} - $time > 20 * 100; # 30s
    }
  }

  @Games::PangZero::GameObjects = @oldGameObjects;
  foreach (@balls) { $_->Delete(); }
  $self->LeaveSubMenu($recall);
}

sub RunHighScore {
  my ($self, $difficultyLevel, $table, $auto) = @_;
  my ($time, $recall, $y, $yinc, $retval);

  die unless $table =~ /^(Cha|Pan)$/;
  $time            = 0;
  $recall          = $self->EnterSubMenu();
  ($y, $yinc)      = (110, 40);
  $difficultyLevel = $Games::PangZero::DifficultyLevels[$difficultyLevel];
  push @{$self->{menuItems}}, (
    Games::PangZero::MenuItem->new( 320, 50, ($table eq 'Cha' ? 'Challenge Game - ' : 'Panic Game - ') . $difficultyLevel->{name} ), #. " difficulty" ),
    Games::PangZero::MenuItem->new( 50, $y, "Highest Score" ),
    Games::PangZero::MenuItem->new( 480, $y, "Highest Level" ),
  );
  $self->{menuItems}->[0]->Center();
  $y += $yinc;
  foreach (@{$difficultyLevel->{"highScoreTable$table"}}) {
    push @{$self->{menuItems}}, ( Games::PangZero::MenuItem->new( 10, $y += $yinc, $_->[0] ) );
    push @{$self->{menuItems}}, ( Games::PangZero::MenuItem->new( 250, $y, $_->[1] ) );
  }
  $y = 110 + $yinc;
  foreach (@{$difficultyLevel->{"highLevelTable$table"}}) {
    push @{$self->{menuItems}}, ( Games::PangZero::MenuItem->new( 460, $y += $yinc, $_->[0] ) );
    push @{$self->{menuItems}}, ( Games::PangZero::MenuItem->new( 700, $y, $_->[1] ) );
  }
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});

  while (not $retval) {
    $self->MenuAdvance();
    if ($self->{abortgame}) {
      $retval = 'abortgame'; last;
    }
    if ($auto) {
      $retval = 'next'      if ++$time > 100 * 6;
      $retval = 'abortgame' if %Games::PangZero::Events;
    } else {
      if ($Games::PangZero::MenuEvents{LEFT} or $Games::PangZero::MenuEvents{UP}) {
        $retval = 'prev'; last;
      } elsif ($Games::PangZero::MenuEvents{RIGHT} or $Games::PangZero::MenuEvents{DOWN}) {
        $retval = 'next'; last;
      } elsif ($Games::PangZero::MenuEvents{BUTTON}) {
        $retval = 'abortgame';
      }
    }
  }
  $self->LeaveSubMenu($recall);
  return $retval;
}

sub RunHighScores {
  my ($self, $auto) = @_;
  my ($recall, $retval, $i, $table, @tables);

  if ($auto) {
    $self->ShowTooltip();
  } else {
    $self->ShowTooltip("Use arrow keys to navigate, Esc to go back");
  }
  $recall = $self->EnterSubMenu();
  $self->{title}->Hide();
  $table = 0;
  @tables = ( [0, 'Pan'], [0, 'Cha'], [1, 'Pan'], [1, 'Cha'], [2, 'Pan'], [2, 'Cha'], [3, 'Pan'], [3, 'Cha'], [4, 'Pan'] );

  while (1) {
    $retval = $self->RunHighScore( @{$tables[$table]}, $auto );
    if ($retval eq 'next') {
      ++$table;
      $table = 0 if $table == scalar @tables;
      last if $table == 0 and $auto;
    } elsif ($retval eq 'prev') {
      --$table;
      $table = $#tables if $table < 0;
    } else {
      last;
    }
  }

  $self->ShowTooltip();
  $self->{title}->Show();
  $self->LeaveSubMenu($recall);
}

sub UpdateBallMixerMenu {
  my $self = shift;

  $self->{menuItems}->[1]->SetParameter( $Games::PangZero::DeathBallsEnabled      ? 'on' : 'off' );
  $self->{menuItems}->[2]->SetParameter( $Games::PangZero::EarthquakeBallsEnabled ? 'on' : 'off' );
  $self->{menuItems}->[3]->SetParameter( $Games::PangZero::WaterBallsEnabled      ? 'on' : 'off' );
  $self->{menuItems}->[4]->SetParameter( $Games::PangZero::SeekerBallsEnabled     ? 'on' : 'off' );
}

sub RunBallMixerMenu {
  my $self = shift;
  my ($recall);

  $recall = $self->EnterSubMenu();
  my ($y, $yinc) = (110, 40);
  push @{$self->{menuItems}}, (
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Back to options menu"),
    Games::PangZero::MenuItem->new( 100, $y += $yinc + 20, "Death Balls: ", "Death balls multiply every time you shoot them.", "You can get rid of them by NOT shooting them for 20 seconds." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Earthquake Balls: ", "Earthquake balls shake the ground when they bounce.", "This sends you flying. Very dangerous." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Water Balls: ", "Water balls quickly dissolve, creating a flood of small balls." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Seeker Balls: ", "This ball picks a target, and chases him." ),
  );
  $self->UpdateBallMixerMenu();
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});
  $self->SetCurrentItemIndex(0);

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    $self->HandleUpDownKeys();

    if ($Games::PangZero::MenuEvents{BUTTON}) {
      last if $self->{currentItemIndex} == 0; # Back to main
      if ($self->{currentItemIndex} == 1) {
        $Games::PangZero::DeathBallsEnabled = 1 - $Games::PangZero::DeathBallsEnabled; $self->UpdateBallMixerMenu();
      } elsif ($self->{currentItemIndex} == 2) {
        $Games::PangZero::EarthquakeBallsEnabled = 1 - $Games::PangZero::EarthquakeBallsEnabled; $self->UpdateBallMixerMenu();
      } elsif ($self->{currentItemIndex} == 3) {
        $Games::PangZero::WaterBallsEnabled = 1 - $Games::PangZero::WaterBallsEnabled; $self->UpdateBallMixerMenu();
      } elsif ($self->{currentItemIndex} == 4) {
        $Games::PangZero::SeekerBallsEnabled = 1 - $Games::PangZero::SeekerBallsEnabled; $self->UpdateBallMixerMenu();
      }
    }
  }

  $self->LeaveSubMenu($recall);
}

sub UpdateOptionsMenu {
  my $self = shift;

  $self->{menuItems}->[1]->SetParameter( $Games::PangZero::Slippery     ? 'on' : 'off' );
  $self->{menuItems}->[3]->SetParameter( $Games::PangZero::SoundEnabled ? 'on' : 'off');
  $self->{menuItems}->[4]->SetParameter( $Games::PangZero::MusicEnabled ? 'on' : 'off');
  $self->{menuItems}->[5]->SetText('< ' . ('Windowed', 'Fullscreen', 'Widescreen')[$Games::PangZero::FullScreen]
    . ($self->{restart} ? ' (requires restart)' : '') . ' >');
  $self->{menuItems}->[6]->SetParameter( $Games::PangZero::ShowWebsite eq $Games::PangZero::VERSION ? 'no' : 'yes' );
}

sub RunOptionsMenu {
  my $self       = shift;
  my $recall     = $self->EnterSubMenu();
  my ($y, $yinc) = (80, 38);
  push @{$self->{menuItems}}, (
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Back to main menu"),
    Games::PangZero::MenuItem->new( 100, $y += $yinc + 20, "Slippery floor: ", "Turning this on creates and icy floor that you slide on", "This makes the game a lot harder!" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Ball Mixer...", "Turn the special balls on and off.", "This can make the game easier." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Sound: ", "Press Enter to turn sound effects on/off." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Music: ", "Press Enter to turn the background music on/off." ),
    Games::PangZero::MenuItem->new(  68, $y += $yinc, "Fullscreen", "Press Left/Right to set the screen mode.", "If you have a wide screen (e.g. 16:9), use the Widescreen option.", "This doesn't take effect until you quit and restart the game." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Show website at exit: ", "Should Pang Zero take you to our web site at exit?", "True enlightenment awaits you online!" ),
  );
  $self->UpdateOptionsMenu();
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});
  $self->SetCurrentItemIndex(0);

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    $self->HandleUpDownKeys();

    if ($Games::PangZero::MenuEvents{LEFT} and $self->{currentItemIndex} == 5) {
      if ($Games::PangZero::FullScreen > 0) { --$Games::PangZero::FullScreen; $self->{restart} = 1; }
      $self->UpdateOptionsMenu();
    }
    if ($Games::PangZero::MenuEvents{RIGHT} and $self->{currentItemIndex} == 5) {
      if ($Games::PangZero::FullScreen < 2) { ++$Games::PangZero::FullScreen; $self->{restart} = 1; }
      $self->UpdateOptionsMenu();
    }
    if ($Games::PangZero::MenuEvents{BUTTON}) {
      last if $self->{currentItemIndex} == 0; # Back to main
      if ($self->{currentItemIndex} == 2) {
        $self->RunBallMixerMenu();
      } elsif ($self->{currentItemIndex} == 1) {
        $Games::PangZero::Slippery = $Games::PangZero::Slippery ? 0 : 1; $self->UpdateOptionsMenu();
      } elsif ($self->{currentItemIndex} == 3) {
        $Games::PangZero::SoundEnabled = 1 - $Games::PangZero::SoundEnabled; $self->UpdateOptionsMenu();
      } elsif ($self->{currentItemIndex} == 4) {
        Games::PangZero::SetMusicEnabled(1 - $Games::PangZero::MusicEnabled); $self->UpdateOptionsMenu();
      } elsif ($self->{currentItemIndex} == 6) {
        $Games::PangZero::ShowWebsite = ($Games::PangZero::ShowWebsite eq $Games::PangZero::Version ? 0 : $Games::PangZero::VERSION); $self->UpdateOptionsMenu();
      }
    }
  }

  $self->LeaveSubMenu($recall);
}

sub UpdateControlsMenu {
  my $self = shift;

  $self->{menuItems}->[1]->SetText("< Number of Players: $Games::PangZero::NumGuys >");
  for (my $i = 1 ; $i <= 6; ++$i) {
    if ($i > $Games::PangZero::NumGuys) {
      $self->{menuItems}->[$i+1]->Hide();
      $self->{keysAsText}->[$i-1]->Hide();
    } else {
      $self->{menuItems}->[$i+1]->Show();
      $self->{keysAsText}->[$i-1]->Show();
    }
  }
}

sub RunControlsMenu {
  my $self = shift;
  my ($menuItem, @keysAsText, @yPositions);

  my $recall = $self->EnterSubMenu();
  $self->{title}->Hide();
  my $baseY = 50;

  push @{$self->{menuItems}},
    Games::PangZero::MenuItem->new( 50, $baseY, "Back to main menu"),
    Games::PangZero::MenuItem->new( 18, $baseY += 40, "<>", "Use left and right key to set the number of players here.", "The more the merrier!", "Don't forget to set their keys below." );
  for ( my $i = 1; $i <= 6; ++$i ) {
    $yPositions[$i] = $baseY + 20 + $i * 40;
    push @{$self->{menuItems}}, (Games::PangZero::MenuItem->new( 50, $yPositions[$i], "Player $i"));
    push @keysAsText, (Games::PangZero::MenuItem->new( 220, $yPositions[$i], KeysToText($Games::PangZero::Players[$i-1]->{keys})) );
  }
  push @Games::PangZero::GameObjects, (@keysAsText, @{$self->{menuItems}});
  $self->{keysAsText} = \@keysAsText;
  $self->UpdateControlsMenu();
  $self->SetCurrentItemIndex(1);

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    $self->HandleUpDownKeys();
    if ($Games::PangZero::MenuEvents{LEFT} and $self->{currentItemIndex} == 1) {
      --$Games::PangZero::NumGuys if $Games::PangZero::NumGuys > 1;
      $self->UpdateControlsMenu();
    }
    if ($Games::PangZero::MenuEvents{RIGHT} and $self->{currentItemIndex} == 1) {
      ++$Games::PangZero::NumGuys if $Games::PangZero::NumGuys < 6;
      $self->UpdateControlsMenu();
    }
    if ($Games::PangZero::MenuEvents{BUTTON}) {
      last if $self->{currentItemIndex} == 0; # Back to main
      next if $self->{currentItemIndex} == 1;
      my $player     = $Games::PangZero::Players[$self->{currentItemIndex} - 2];
      my $key        = 0;
      my $keysAsText = $keysAsText[$self->{currentItemIndex} - 2];
      $self->{currentItem}->Hide();
      $keysAsText->Hide();
      my @prompts     = ("Press 'LEFT' key or joystick button", "Press 'RIGHT' key", "Press 'FIRE' key");
      my $keyMenuItem = Games::PangZero::MenuItem->new( 100, $yPositions[$self->{currentItemIndex} - 1], $prompts[0] );
      push @Games::PangZero::GameObjects, ($keyMenuItem);
      $keyMenuItem->Select;
      while (1) {
        $self->MenuAdvance();
        if ($self->{abortgame}) {
          $self->{abortgame} = 0;
          goto endOfKeyEntry;
        }
        if (%Games::PangZero::Events) {
          my ($event) = %Games::PangZero::Events;
          if ($event =~ /^B(\d+)$/) {
            $player->{keys} = ["L$1", "R$1", "B$1"];
            last;
          }
          $player->{keys}->[$key] = $event;
          ++$key;
          last if $key >= 3;
          $keyMenuItem->SetText($prompts[$key]);
        }
      }

      $keyMenuItem->SetText('Select character');
      my $guy   = Games::PangZero::Guy->new($player);
      $guy->{x} = $keyMenuItem->{targetX} + $keyMenuItem->{w} + 10;
      $guy->{y} = $keyMenuItem->{targetY} - 10;
      $guy->DemoMode();
      splice @Games::PangZero::GameObjects, -2, 0, $guy;
      while (1) {
        $self->MenuAdvance();
        if ($self->{abortgame}) {
          $self->{abortgame} = 0;
          goto endOfKeyEntry;
        }
        if ($Games::PangZero::Events{$player->{keys}->[0]}) {
          --$player->{imagefileindex};
          $player->{imagefileindex} = $#Games::PangZero::GuyImageFiles if $player->{imagefileindex} < 0;
          Games::PangZero::Graphics::MakeGuySurface($player);
          $guy->{surface} = $player->{guySurface};
          $guy->CalculateAnimPhases();
        } elsif ($Games::PangZero::Events{$player->{keys}->[1]}) {
          ++$player->{imagefileindex};
          $player->{imagefileindex} = 0 if $player->{imagefileindex} > $#Games::PangZero::GuyImageFiles;
          Games::PangZero::Graphics::MakeGuySurface($player);
          $guy->{surface} = $player->{guySurface};
          $guy->CalculateAnimPhases();
        } elsif ($Games::PangZero::Events{$player->{keys}->[2]}) {
          last;
        }
      }

      $keyMenuItem->SetText('Select color');
      while (1) {
        $self->MenuAdvance();
        if ($self->{abortgame}) {
          $self->{abortgame} = 0;
          goto endOfKeyEntry;
        }
        if ($Games::PangZero::Events{$player->{keys}->[0]}) {
          --$player->{colorindex};
          $player->{colorindex} = $#Games::PangZero::GuyColors if $player->{colorindex} < 0;
          Games::PangZero::Graphics::MakeGuySurface($player);
          $guy->{surface} = $player->{guySurface};
        } elsif ($Games::PangZero::Events{$player->{keys}->[1]}) {
          ++$player->{colorindex};
          $player->{colorindex} = 0 if $player->{colorindex} > $#Games::PangZero::GuyColors;
          Games::PangZero::Graphics::MakeGuySurface($player);
          $guy->{surface} = $player->{guySurface};
        } elsif ($Games::PangZero::Events{$player->{keys}->[2]}) {
          last;
        }
      }

      endOfKeyEntry:
      $guy->Delete() if $guy;
      $self->{currentItem}->Show();
      $self->{currentItem}->Select;
      $keysAsText->SetText(KeysToText($player->{keys}));
      $keysAsText->Show;
      $keyMenuItem->HideAndDelete;
    }
  }

  foreach my $menuItem (@keysAsText) { $menuItem->HideAndDelete(); }
  $self->LeaveSubMenu($recall);
  $self->{title}->Show();
  delete $self->{keysAsText};
}

sub UpdateGameMenu {
  my $self = shift;

  $self->{menuItems}->[3]->SetText("< Difficulty: $Games::PangZero::DifficultyLevel->{name} >");
  $self->{menuItems}->[4]->SetText("< Weapon Duration: $Games::PangZero::WeaponDuration->{name} >");
}

sub RunGameMenu {
  my $self       = shift;
  my $recall     = $self->EnterSubMenu();
  my ($y, $yinc) = (110, 40);
  push @{$self->{menuItems}}, (
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Back to main menu", "Press Enter to return to the main menu"),
    Games::PangZero::MenuItem->new( 100, $y += $yinc + 20, "Start Panic Game", "In Panic Mode, the balls continuously fall from the sky.", "Can you keep up the pace?", "This game is for advanced players." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Start Challenge Game", "More and more difficult levels challenge your skill.", "This game is best for beginners." ),
    Games::PangZero::MenuItem->new(  68, $y += $yinc, "<>", "Press the Left and Right keys to set the game difficulty.", "The game speed and number of harpoons depend on this setting.", "The `Miki' level is for Deathball Specialists (Panic mode only)." ),
    Games::PangZero::MenuItem->new(  68, $y += $yinc, "<>", "Press the Left and Right keys to set the bonus weapon duration.", "This will determine how long you can use bonus weapons." ),
  );
  $self->UpdateGameMenu();
  push @Games::PangZero::GameObjects, (@{$self->{menuItems}});
  $self->SetCurrentItemIndex($Games::PangZero::LastGameMenuResult ? $Games::PangZero::LastGameMenuResult : 1);

  while (1) {
    $self->MenuAdvance();
    last if $self->{abortgame};
    $self->HandleUpDownKeys();

    if ($Games::PangZero::MenuEvents{LEFT} and $self->{currentItemIndex} == 3) {
      Games::PangZero::Config::SetDifficultyLevel($Games::PangZero::DifficultyLevelIndex - 1);
      $self->UpdateGameMenu();
    }
    if ($Games::PangZero::MenuEvents{RIGHT} and $self->{currentItemIndex} == 3) {
      Games::PangZero::Config::SetDifficultyLevel($Games::PangZero::DifficultyLevelIndex + 1);
      $self->UpdateGameMenu();
    }
    if ($Games::PangZero::MenuEvents{LEFT} and $self->{currentItemIndex} == 4) {
      Games::PangZero::Config::SetWeaponDuration($Games::PangZero::WeaponDurationIndex - 1);
      $self->UpdateGameMenu();
    }
    if ($Games::PangZero::MenuEvents{RIGHT} and $self->{currentItemIndex} == 4) {
      Games::PangZero::Config::SetWeaponDuration($Games::PangZero::WeaponDurationIndex + 1);
      $self->UpdateGameMenu();
    }
    if ($Games::PangZero::MenuEvents{BUTTON}) {
      last if $self->{currentItemIndex} == 0; # Back to main
      if ($self->{currentItemIndex} == 1) {
        $self->{result} = 'panic';
      } elsif ($self->{currentItemIndex} == 2) {
        if ($Games::PangZero::DifficultyLevel->{name} ne 'Miki') {
          $self->{result} = 'challenge';
        } else {
          $self->ShowTooltip("Miki difficulty level is for panic mode only.");
        }
      }
    }
    last if $self->{result};
  }

  $Games::PangZero::LastGameMenuResult = $self->{currentItemIndex};
  $self->LeaveSubMenu($recall);
}

sub OnMenuIdle {
  my $self = shift;

  ++$self->{idle};
  if    ($self->{idle} == 1) { $self->RunHighScores('auto'); }
  elsif ($self->{idle} == 2) { $self->RunCredits('demo'); }
  elsif ($self->{idle} == 3) { $self->{idle} = 0; return 'demo'; }
  return '';
}

sub Run {
  my $self = shift;
  my ($y, $yinc, $idle);

  $self->ResetGame();
  $Games::PangZero::ScoreFont->use();
  ($y, $yinc) = ($Games::PangZero::ScreenHeight + 15, 20);
  SDLx::SFont::print_text( $Games::PangZero::Background, 10, $y += $yinc, "Pang Zero $Games::PangZero::VERSION (C) 2006 by UPi (upi\@sourceforge.net)" ) if $y + $yinc * 2 < $Games::PangZero::PhysicalScreenHeight;

  SDLx::SFont::print_text( $Games::PangZero::Background, 10, $y += $yinc, "Use cursor keys to navigate menu, Enter to select" )           if $y + $yinc * 2 < $Games::PangZero::PhysicalScreenHeight;

  SDLx::SFont::print_text( $Games::PangZero::Background, 10, $y += $yinc, "P pauses the game, Esc quits" )                                if $y + $yinc * 2 < $Games::PangZero::PhysicalScreenHeight;

  SDL::Video::blit_surface($Games::PangZero::Background, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h), $Games::PangZero::App, SDL::Rect->new(0, 0, $Games::PangZero::App->w, $Games::PangZero::App->h));

  $Games::PangZero::MenuFont->use();
  push @Games::PangZero::GameObjects, (Games::PangZero::FpsIndicator->new());
  $self->SetGameSpeed();
  $Games::PangZero::GamePause = 0;

  ($y, $yinc) = (90, 40);

  $self->{menuItems} = [
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Start Game" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Options", "Various game settings" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Setup players", "Set the number of players, setup keys and joysticks" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Help", "How to play the game, demo of special balls" ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Credits", "You might be wondering: Who has created Pang Zero?", "Wonder no more." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "High Scores", "Hall of Fame." ),
    Games::PangZero::MenuItem->new( 100, $y += $yinc, "Exit Game", "Press Enter to exit the game" ),
  ];

  $self->{title}              = Games::PangZero::MenuItem->new( 300,  60, "PANG ZERO" );
  $self->{title}->{filled}    = 1;
  $self->{title}->{fillcolor} = SDL::Color->new(0, 128, 255);
  $self->{title}->Center();

  push @Games::PangZero::GameObjects, (
    Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc[8], -1, 1),
    Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc[0], -1, 0),
    Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc{super0}, -1, 1),
    Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc[2], -1, 0),
    Games::PangZero::Ball::Spawn($Games::PangZero::BallDesc[5], -1, 1),
    $self->{title},
    @{$self->{menuItems}},
  );

  $self->SetCurrentItemIndex( 0 );
  Games::PangZero::GameTimer::ResetTimer();

  while (1) {
    $self->MenuAdvance();
    $self->Exit() if $self->{abortgame};
    $self->HandleUpDownKeys();
    last if $self->{result};
    if ($Games::PangZero::MenuEvents{BUTTON}) {
      if ($self->{currentItemIndex} == 0) {
        $self->RunGameMenu();
      } elsif ($self->{currentItemIndex} == 1) {
        $self->RunOptionsMenu();
      } elsif ($self->{currentItemIndex} == 2) {
        $self->RunControlsMenu();
      } elsif ($self->{currentItemIndex} == 3) {
        $self->RunTutorialMenu;
      } elsif ($self->{currentItemIndex} == 4) {
        $self->RunCredits();
      } elsif ($self->{currentItemIndex} == 5) {
        $self->RunHighScores();
      }
      $self->Exit() if $self->{currentItemIndex} == 6;
    }
    if (%Games::PangZero::Events) {
      $idle = 0;
    } else {
      if (++$idle > 1000) {
        $self->{result} = $self->OnMenuIdle();
        $idle = 0;
      }
    }
  }

  $Games::PangZero::ScoreFont->use();
  return $self->{result};
}

1;
