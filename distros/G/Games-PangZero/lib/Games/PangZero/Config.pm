##########################################################################
# CONFIG SAVE/LOAD
##########################################################################

package Games::PangZero::Config;

use File::ShareDir qw(dist_dir);

sub IsMicrosoftWindows {
  return $^O eq 'MSWin32';
}


sub TestDataDir {
  return -f "$Games::PangZero::DataDir/glossyfont.png";   # Should be a file from the latest version.
}

sub FindDataDir {
  return if $Games::PangZero::DataDir and TestDataDir();
  my @guesses = ('.', dist_dir('Games-PangZero'));
  foreach my $guess (@guesses) {
    $Games::PangZero::DataDir = $guess;
    return if TestDataDir();
    $Games::PangZero::DataDir = "$guess/data";
    return if TestDataDir();
  }
  die "Couldn't find the data directory. Please set it manually.";
}

sub GetConfigFilename {
  if ( IsMicrosoftWindows() ) {
    if ($ENV{USERPROFILE}) {
      return "$ENV{USERPROFILE}\\pangzero.cfg";
    }
    return "$Games::PangZero::DataDir/pangzero.cfg";
  }
  if ($ENV{HOME}) {
    return "$ENV{HOME}/.pangzerorc";
  }
  if (-w $Games::PangZero::DataDir) {
    return "$Games::PangZero::DataDir/pangzero.cfg";
  }
  return "/tmp/pangzero.cfg";
}

sub GetConfigVars {
  my ($i, $j);
  my @result = qw(
    Games::PangZero::NumGuys
    Games::PangZero::DifficultyLevelIndex
    Games::PangZero::WeaponDurationIndex
    Games::PangZero::Slippery
    Games::PangZero::MusicEnabled
    Games::PangZero::SoundEnabled
    Games::PangZero::FullScreen
    Games::PangZero::ShowWebsite
    Games::PangZero::DeathBallsEnabled
    Games::PangZero::EarthquakeBallsEnabled
    Games::PangZero::WaterBallsEnabled
    Games::PangZero::SeekerBallsEnabled
  );
  for ($i=0; $i < scalar @Games::PangZero::Players; ++$i) {
    for ($j=0; $j < 3; ++$j) {
      push @result, ("Games::PangZero::Players[$i]->{keys}->[$j]");
    }
    push @result, ("Games::PangZero::Players[$i]->{colorindex}");
    push @result, ("Games::PangZero::Players[$i]->{imagefileindex}");
  }
  my ($difficulty, $gameMode);
  for ($difficulty=0; $difficulty < scalar @Games::PangZero::DifficultyLevels; ++$difficulty) {
    foreach $gameMode ('highScoreTablePan', 'highLevelTablePan', 'highScoreTableCha', 'highLevelTableCha') {
      next if ($Games::PangZero::DifficultyLevels[$difficulty]->{name} eq 'Miki' and $gameMode eq 'highScoreTableCha');
      for ($i=0; $i < 5; ++$i) {
        push @result, "Games::PangZero::DifficultyLevels[$difficulty]->{$gameMode}->[$i]->[0]", # Name of high score
                      "Games::PangZero::DifficultyLevels[$difficulty]->{$gameMode}->[$i]->[1]", # High score
      }
    }
  }
  return @result;
}

sub SaveConfig {
  my ($filename, $varname, $value);
  $filename = GetConfigFilename();

  open CONFIG, "> $filename" or return;
  foreach $varname (GetConfigVars()) {
    eval("\$value = \$$varname"); die $@ if $@;
    print CONFIG "\$$varname = $value\n";
  }
  close CONFIG;
}

sub LoadConfig {
  my ($filename, $text, $varname);

  $text     = '';
  $filename = GetConfigFilename();
  if (open CONFIG, "$filename") {
    read CONFIG, $text, 16384;
    close CONFIG;
  }

  foreach $varname (GetConfigVars()) {
    my $pattern = $varname;
    $pattern    =~ s/\[/\\[/g;
    if ($text =~ /$pattern = (.+?)$/m) {
      $val = $1;
      if($val =~ /^SDLK_\w+$/) {
        eval( "\$$varname = SDL::Events::$val()" );
      }
      elsif($val =~ /^[\d\.]+$/) {
        eval( "\$$varname = $val" );
      }
      else {
        eval( "\$$varname = '$val'" );
      }
    }
  }

  SetDifficultyLevel($Games::PangZero::DifficultyLevelIndex);
  SetWeaponDuration($Games::PangZero::WeaponDurationIndex);
}

sub SetDifficultyLevel {
  my $difficultyLevelIndex = shift;
  if ($difficultyLevelIndex < 0 or $difficultyLevelIndex > $#Games::PangZero::DifficultyLevels) {
    $difficultyLevelIndex = $Games::PangZero::DifficultyLevelIndex;
  }
  $Games::PangZero::DifficultyLevelIndex = $difficultyLevelIndex;
  $Games::PangZero::DifficultyLevel      = $Games::PangZero::DifficultyLevels[$difficultyLevelIndex];
}

sub SetWeaponDuration {
  my $weaponDurationIndex = shift;
  if ($weaponDurationIndex < 0 or $weaponDurationIndex > $#Games::PangZero::WeaponDurations) {
    $weaponDurationIndex = $Games::PangZero::WeaponDurationIndex;
  }
  $Games::PangZero::WeaponDurationIndex = $weaponDurationIndex;
  $Games::PangZero::WeaponDuration      = $Games::PangZero::WeaponDurations[$Games::PangZero::WeaponDurationIndex];
}

1;
