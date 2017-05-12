package Games::PangZero;

$Cheat   = 0;
$VERSION = '1.4.1';
$DataDir = '';  # Set it to a path to avoid autodetection (e.g. /opt/pangzero/data)

=comment

##########################################################################
#
# PANG ZERO
# Copyright (C) 2006 by UPi <upi at sourceforge.net>
#
##########################################################################

This program is free software; you can redistribute it and//or modify
it under the terms of the GNU General Public License version 2, as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


##########################################################################
# TODO:
##########################################################################
* P4 Bonus probability is balldesc based.
* P3 Tour mode..?
* P5 Graphics and help for machine gun and power wire
* P5 Demo of beating the game at 'normal' difficulty
* P4 Even more forgiving collision detection (?)
* P4 Smooth numbers in the scoreboard
* P3 RotoZoomer smooth parameter to eliminate warning..
* P3 Set DataDir with command line parameter.
* P2 Roll your own game
* P4 Reorg menu: MenuItem->Update(), MenuItem->Left(), MenuItem->Right(), ...

Next release:
* Sound effect for matrix effect...
* Handle possible HST corruption if game exits while merging scores


##########################################################################
# QUICK GUIDE FOR WOULD-BE DEVELOPERS
##########################################################################

'
This file contains the entire source code of Pang Zero. I know that this is
an odd design, but it works for me. You can split the file easily if you
want to.

The parts of the file are organized like this:

1. INITIALIZATION OF GLOBAL OBJECTS (configuration, balls, levels, etc)
2. HIGH SCORE TABLE
3. GAME OBJECT PACKAGES
4. UTILITY PACKAGES AND METHODS
5. GAMEBASE AND DESCENDENT PACKAGES (includes the menu)
6. "MAIN" PROGRAM LOOP
'
=cut

use SDL;
use SDL::Surface;
use SDL::Palette;
use SDL::PixelFormat;
use SDL::Video;
use SDL::Event;
use SDL::Events;
use SDL::Color;
use SDL::Config;
use SDL::Cursor;
use SDL::GFX::Rotozoom;
use SDL::Joystick;
use SDL::Mouse;
use SDL::Image;
use SDLx::App;
use SDLx::SFont;

use Carp;

# SDL objects

use vars qw (
  $App $VERSION $RotoZoomer $Background $ScoreFont $MenuFont $GlossyFont
  %BallSurfaces
  $BorderSurface $WhiteBorderSurface $RedBorderSurface $BonusSurface $LevelIndicatorSurface $LevelIndicatorSurface2
  $WhiteHarpoonSurface
  %Sounds $Mixer
);

# Pang Zero variables and objects

use vars qw (
  $DataDir $ScreenHeight $ScreenWidth $PhysicalScreenWidth $PhysicalScreenHeight $ScreenMargin
  $SoundEnabled $MusicEnabled $FullScreen $ShowWebsite
  $DeathBallsEnabled $EarthquakeBallsEnabled $WaterBallsEnabled $SeekerBallsEnabled $Slippery
  @DifficultyLevels $DifficultyLevelIndex $DifficultyLevel
  @WeaponDurations $WeaponDuration $WeaponDurationIndex
  @GameObjects %GameEvents $GameSpeed $GamePause $Game
  @Players @GuyImageFiles @GuyColors $NumGuys
  @BallDesc %BallDesc @ChallengeLevels @PanicLevels
  $UnicodeMode $LastUnicodeKey %Keys %Events %MenuEvents );


use Games::PangZero::Globals;
use Games::PangZero::GameObject;
use Games::PangZero::Ball;
use Games::PangZero::BonusDrop;
use Games::PangZero::GameBase;
use Games::PangZero::PlayableGameBase;
use Games::PangZero::ChallengeGame;
use Games::PangZero::Config;
use Games::PangZero::DeadGuy;
use Games::PangZero::DeathBall;
use Games::PangZero::PanicGame;
use Games::PangZero::DemoGame;
use Games::PangZero::PlaybackGame;
use Games::PangZero::DemoPlaybackGame;
use Games::PangZero::RecordGame;
use Games::PangZero::DemoRecordGame;
use Games::PangZero::EarthquakeBall;
use Games::PangZero::FpsIndicator;
use Games::PangZero::FragileBall;
use Games::PangZero::GamePause;
use Games::PangZero::GameTimer;
use Games::PangZero::Graphics;
use Games::PangZero::Guy;
use Games::PangZero::Harpoon;
use Games::PangZero::HalfCutter;
use Games::PangZero::Hexa;
use Games::PangZero::Highscore;
use Games::PangZero::Joystick;
use Games::PangZero::MachineGun;
use Games::PangZero::Meltdown;
use Games::PangZero::Menu;
use Games::PangZero::MenuItem;
use Games::PangZero::Music;
use Games::PangZero::Palette;
use Games::PangZero::Pop;
use Games::PangZero::PowerWire;
use Games::PangZero::SeekerBall;
use Games::PangZero::SlowEffect;
use Games::PangZero::SuperBall;
use Games::PangZero::TutorialGame;
use Games::PangZero::UpsideDownBall;
use Games::PangZero::WaterBall;
use Games::PangZero::XmasBall;

sub SaveScreenshot {
  my $i = 0;
  my $filename;
  do { $filename = sprintf("screenshot%03d.bmp", $i); ++$i } while (-f $filename);
  SDL::Video::save_BMP($App, $filename);
}

sub Pause {
  my $pausedSurface = SDL::Image::load("$DataDir/paused.png");
  my $event         = SDL::Event->new();

  SDL::Video::blit_surface($pausedSurface, SDL::Rect->new(0, 0, $pausedSurface->w, $pausedSurface->h),
                           $App, SDL::Rect->new(($PhysicalScreenWidth - $pausedSurface->w) / 2, $PhysicalScreenHeight / 2 - 100, 0, 0));
  $App->sync();
  $Keys   = ();
  $Events = ();
  while (1) { # Paused, wait for keypress
    SDL::Events::pump_events();
    SDL::Events::wait_event($event);
    last if $event->type() == SDL_KEYDOWN and $event->key_sym == SDLK_p;
    if ($event->type() == SDL_KEYDOWN and $event->key_sym == SDLK_ESCAPE) {
      $Game->{abortgame} = 1;
      last;
    }
    $Game->Exit() if $event->type() == SDL_QUIT;
  }
  SDL::Video::blit_surface($Background, SDL::Rect->new(0, 0, $App->w, $App->h), $App, SDL::Rect->new(0, 0, $App->w, $App->h));
  Games::PangZero::GameTimer::ResetTimer();
}

sub HandleEvents {
  my ($readBothJoystickAxes) = @_;
  my ($event, $type);

  $event = SDL::Event->new;
  while (1) {
    SDL::Events::pump_events();
    last unless SDL::Events::poll_event($event);
    $type = $event->type();

    if ($type == SDL_QUIT) {
      $Game->Exit();
    }
    elsif ($type == SDL_KEYDOWN) {
      my $keypressed = $event->key_sym;
      if ($keypressed == SDLK_ESCAPE) {
        $Game->{abortgame} = 1;
      } elsif ($keypressed == SDLK_F1) {
        SaveScreenshot();
      } elsif ($keypressed == SDLK_p and not $UnicodeMode) {
        Pause();
      } else {
        $Keys{$keypressed}   = 1;
        $Events{$keypressed} = 1;
        $MenuEvents{UP}      = 1 if $keypressed == SDLK_UP();
        $MenuEvents{DOWN}    = 1 if $keypressed == SDLK_DOWN();
        $MenuEvents{LEFT}    = 1 if $keypressed == SDLK_LEFT();
        $MenuEvents{RIGHT}   = 1 if $keypressed == SDLK_RIGHT();
        $MenuEvents{BUTTON}  = 1 if $keypressed == SDLK_RETURN();
        $LastUnicodeKey      = $event->key_unicode() if $UnicodeMode;
      }
    }
    elsif ($type == SDL_KEYUP) {
      my $keypressed     = $event->key_sym;
      $Keys{$keypressed} = 0;
    }
  }

  Games::PangZero::Joystick::ReadJoystick($readBothJoystickAxes);
}

sub DoMenu {
  my $oldScreenHeight = $ScreenHeight;
  my $oldScreenWidth  = $ScreenWidth;
  $ScreenWidth        = $PhysicalScreenWidth - $ScreenMargin * 2;
  $ScreenWidth        = int($ScreenWidth / 32) * 32;
  $Game               = Games::PangZero::Menu->new();
  my $retval          = $Game->Run();
  Games::PangZero::Config::SaveConfig();

  $ScreenWidth        = $oldScreenWidth;
  $ScreenHeight       = $oldScreenHeight;

  return $retval;
}

sub DoDemo {
  my $messages = $Game->{messages} = {
    1 => "Use harpoons to pop the balloons",
    160 => "Pop them, and they split in two",
    300 => "Pop them again and again",
    530 => "Popping the smallest ballons makes them disappear",
    630 => "The green Super Ball gives you a lot of free time",
    720 => "Use this time wisely!",
    1150 => "Making a lot of small balls is dangerous! Observe...",
    1600 => "Don't let the balloons touch you!",
    1708 => "Dying gives you some free time.",
    1900 => "So does shooting the flashing balloons.",
    2370 => "The yellow Super Ball destroys every balloon",
    2650 => "And now... THE SPECIAL BALL DEMO!",
    2950 => "The Bouncy Ball bounces twice as high as normal balls.",
    3620 => "See?",
    4222 => "The Hexa Ball is weightless and travels in a straight line.",
    4500 => "So does its offspring.",
    5210 => "The blue Water Ball splits every time it bounces.",
    5900 => "This can cause a tide of small balls!",
    6630 => "The Earthquake Ball will really shake you up.",
    7100 => "Its offspring is not as dangerous, but still annoying.",
    7800 => "Behold, the Death Ball. It cannot be killed!!!",
    8120 => "No, really, it can't! In fact, shooting it makes it multiply.",
    8220 => "If you avoid it for 20 secs, Deathballs will get bored and go away.",
    8320 => "Also, the yellow Super Ball will destroy the Deathballs for you.",
    8800 => "Shooting it too much will lead to the Deathball Meltdown.",
    9550 => "Last but not least: here's the Seeker Ball!",
    9900 => "This ball will stalk you forever.",
    10100 => "Whew! This concludes the Special Ball Demo. Have fun playing!",
  };
  my $record = 0 x 23 . 1 x 18 . 0 x 19 . 2 x 7 . 0 x 31 . 4 x 1 . 0 x 44 . 2 x 43 . 0 x 7 . 4 x 1 . 0 x 22 . 1 x 10 . 0 x 17 . 2 x 38 . 0 x 16 . 2 x 22 . 0 x 42 . 4 x 1 . 0 x 54 . 1 x 43 . 0 x 2 . 4 x 1 . 0 x 28 . 1 x 27 . 0 x 8 . 4 x 1 . 0 x 98 . 2 x 19 . 0 x 11 . 4 x 1 . 0 x 27 . 1 x 24 . 5 x 1 . 1 x 1 . 0 x 17 . 1 x 9 . 0 x 2 . 4 x 1 . 0 x 51 . 2 x 19 . 0 x 14 . 4 x 1 . 0 x 48 . 1 x 14 . 0 x 2 . 4 x 1 . 0 x 51 . 1 x 8 . 0 x 25 . 4 x 1 . 0 x 49 . 2 x 25 . 0 x 3 . 4 x 1 . 0 x 53 . 1 x 12 . 0 x 9 . 4 x 1 . 0 x 101 . 1 x 9 . 0 x 4 . 4 x 1 . 0 x 68 . 1 x 7 . 5 x 1 . 0 x 75 . 2 x 14 . 0 x 2 . 4 x 1 . 0 x 64 . 2 x 38 . 0 x 3 . 4 x 1 . 0 x 13 . 2 x 13 . 0 x 25 . 2 x 25 . 0 x 5 . 4 x 1 . 0 x 54 . 4 x 1 . 0 x 69 . 1 x 3 . 0 x 15 . 4 x 1 . 0 x 19 . 2 x 17 . 0 x 94 . 2 x 28 . 0 x 27 . 2 x 52 . 0 x 22 . 4 x 1 . 0 x 34 . 1 x 28 . 0 x 34 . 1 x 29 . 0 x 24 . 4 x 1 . 0 x 80 . 1 x 15 . 0 x 116 . 1 x 10 . 5 x 1 . 1 x 1 . 0 x 808 . 2 x 35 . 0 x 16 . 4 x 1 . 0 x 55 . 1 x 46 . 5 x 1 . 1 x 2 . 0 x 368 . 8 x 1 . 0 x 487 . 1 x 27 . 0 x 48 . 2 x 8 . 6 x 1 . 2 x 7 . 0 x 7 . 2 x 18 . 6 x 1 . 2 x 11 . 0 x 119 . 1 x 1 . 0 x 167 . 8 x 1 . 0 x 1177 . 2 x 24 . 0 x 121 . 2 x 22 . 0 x 2 . 4 x 1 . 0 x 31 . 2 x 15 . 0 x 9 . 2 x 4 . 6 x 1 . 2 x 5 . 0 x 8 . 2 x 10 . 0 x 69 . 8 x 1 . 0 x 338 . 1 x 87 . 0 x 152 . 2 x 52 . 0 x 112 . 1 x 27 . 0 x 2 . 4 x 1 . 0 x 71 . 1 x 41 . 0 x 4 . 4 x 1 . 0 x 65 . 2 x 24 . 0 x 209 . 8 x 1 . 0 x 579 . 1 x 3 . 0 x 13 . 2 x 3 . 0 x 14 . 4 x 1 . 0 x 58 . 2 x 28 . 0 x 9 . 4 x 1 . 0 x 93 . 2 x 37 . 0 x 26 . 2 x 11 . 0 x 22 . 2 x 9 . 6 x 1 . 2 x 6 . 6 x 1 . 2 x 7 . 6 x 1 . 2 x 5 . 6 x 1 . 2 x 7 . 6 x 1 . 2 x 16 . 6 x 1 . 2 x 9 . 6 x 1 . 2 x 20 . 1 x 7 . 0 x 21 . 2 x 13 . 1 x 3 . 5 x 1 . 1 x 8 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 35 . 0 x 6 . 5 x 1 . 1 x 6 . 0 x 11 . 2 x 12 . 6 x 1 . 2 x 8 . 6 x 1 . 1 x 6 . 5 x 1 . 1 x 3 . 0 x 3 . 4 x 1 . 1 x 3 . 0 x 3 . 5 x 1 . 1 x 4 . 0 x 15 . 1 x 2 . 5 x 1 . 1 x 4 . 0 x 4 . 5 x 1 . 1 x 7 . 5 x 1 . 1 x 4 . 0 x 5 . 1 x 6 . 0 x 2 . 4 x 1 . 1 x 4 . 0 x 4 . 4 x 1 . 0 x 3 . 1 x 4 . 0 x 3 . 4 x 1 . 0 x 10 . 2 x 14 . 6 x 1 . 2 x 2 . 1 x 5 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 5 . 5 x 1 . 1 x 2 . 0 x 3 . 4 x 1 . 1 x 3 . 0 x 3 . 4 x 1 . 1 x 3 . 0 x 2 . 1 x 2 . 5 x 1 . 1 x 4 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 7 . 5 x 1 . 1 x 7 . 0 x 2 . 2 x 4 . 6 x 1 . 2 x 4 . 0 x 2 . 2 x 2 . 6 x 1 . 2 x 6 . 6 x 1 . 2 x 7 . 1 x 5 . 5 x 1 . 1 x 1 . 0 x 5 . 2 x 6 . 6 x 1 . 2 x 2 . 0 x 4 . 1 x 3 . 5 x 1 . 1 x 1 . 0 x 8 . 2 x 4 . 6 x 1 . 2 x 1 . 0 x 3 . 1 x 4 . 0 x 7 . 2 x 6 . 6 x 1 . 2 x 8 . 6 x 1 . 2 x 6 . 6 x 1 . 2 x 3 . 0 x 3 . 1 x 3 . 0 x 10 . 2 x 7 . 0 x 2 . 1 x 1 . 5 x 1 . 1 x 5 . 0 x 2 . 4 x 1 . 1 x 2 . 0 x 4 . 4 x 1 . 0 x 2 . 1 x 2 . 0 x 3 . 1 x 1 . 5 x 1 . 1 x 5 . 5 x 1 . 1 x 3 . 0 x 4 . 5 x 1 . 1 x 1 . 0 x 4 . 4 x 1 . 1 x 2 . 0 x 4 . 4 x 1 . 1 x 1 . 0 x 6 . 4 x 1 . 1 x 1 . 0 x 5 . 1 x 1 . 5 x 1 . 1 x 2 . 0 x 3 . 1 x 1 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 7 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 6 . 5 x 1 . 1 x 7 . 0 x 12 . 2 x 7 . 0 x 2 . 4 x 1 . 2 x 2 . 0 x 4 . 4 x 1 . 0 x 135 . 8 x 1 . 0 x 252 . 1 x 57 . 0 x 199 . 2 x 37 . 0 x 3 . 1 x 1 . 5 x 1 . 1 x 29 . 0 x 21 . 1 x 30 . 0 x 37 . 4 x 1 . 0 x 77 . 1 x 17 . 0 x 4 . 2 x 126 . 3 x 1 . 1 x 52 . 5 x 1 . 1 x 64 . 0 x 39 . 8 x 1 . 0 x 140;
  my $rand = [2199.02,1.12,0.11,1.24,0.11,1.21,0.33,0.19,0.16,0.12,0.07,0.28,0.68];

  Games::PangZero::Config::SaveConfig();
  $Game = Games::PangZero::DemoPlaybackGame->new( 1, 3, $record, $rand, $messages );
  $Game->Run();
  Games::PangZero::Config::LoadConfig();
  $Game->RestoreGameSettings();
}

sub DoRecordDemo {
  my ($numguys, $difficulty) = ($NumGuys, $DifficultyLevelIndex);

  $NumGuys = 1;
  Games::PangZero::Config::SetDifficultyLevel(3);
  $Game = Games::PangZero::DemoRecordGame->new();
  $Game->Run();
  print "\n\$record = '", $Game->{record}, "';\n";
  print "\$rand = [", join( ', ', @{$Game->{rand}} ), "];\n\n";
  $NumGuys = $numguys;
  Games::PangZero::Config::SetDifficultyLevel($difficulty);
}


##########################################################################
# MAIN PROGRAM STARTS HERE
##########################################################################

sub Initialize {

  eval { SDL::init(SDL_INIT_EVERYTHING()); };
  die "Unable to initialize SDL: $@" if $@;

  Games::PangZero::Config::FindDataDir();
  Games::PangZero::Config::LoadConfig();
  print "Data directory is at '$DataDir'\n";
  my $sdlFlags;
  if (Games::PangZero::Config::IsMicrosoftWindows()) {
    $sdlFlags = SDL_ANYFORMAT;
  } else {
    $sdlFlags = SDL_HWSURFACE | SDL_HWACCEL | SDL_DOUBLEBUF | SDL_ANYFORMAT | SDL_FULLSCREEN;
  }

  ($PhysicalScreenWidth, $PhysicalScreenHeight) = Games::PangZero::Graphics::FindVideoMode();

  $App = SDLx::App->new(
    flags      => $sdlFlags,
    title      => "Pang Zero $VERSION",
    icon       => "$DataDir/icon.png",
    width      => $PhysicalScreenWidth,
    height     => $PhysicalScreenHeight,
    fullscreen => $FullScreen,
    delay      => 20
  );

  SDL::Mouse::show_cursor(0);

  $Background = SDL::Surface->new( Games::PangZero::Config::IsMicrosoftWindows() ? SDL_SWSURFACE() : SDL_HWSURFACE(), $App->w, $App->h, 16);
  $Background = SDL::Video::display_format($Background);
  $ScoreFont  = SDLx::SFont->new("$DataDir/brandybun3.png");
  $MenuFont   = SDLx::SFont->new("$DataDir/font2.png");
  $GlossyFont = SDLx::SFont->new("$DataDir/glossyfont.png");

  Games::PangZero::Graphics::LoadSurfaces();
  Games::PangZero::Music::LoadSounds();
  Games::PangZero::Joystick::InitJoystick();
}

sub MainLoop {
  my $menuResult = DoMenu();
  if ($menuResult eq 'demo') {
    DoDemo();
  }

  #$Game = Games::PangZero::DemoRecordGame->new();
  $Game                         = ($menuResult eq 'challenge')
                                ? Games::PangZero::ChallengeGame->new()
                                : Games::PangZero::PanicGame->new();
  @Games::PangZero::Highscore::UnsavedHighScores = ();
  $Game->Run();

  bless $Game, 'Menu';
  $Game->{abortgame} = 0;
  {
    my @gameObjects = @GameObjects;
    foreach (@gameObjects) {
      $_->Delete() if ref $_ eq 'Games::PangZero::Guy';
    }
  }

  SDL::Video::blit_surface($Background, SDL::Rect->new(0, 0, $App->w, $App->h), $App, SDL::Rect->new(0, 0, $App->w, $App->h));
  $Games::PangZero::MenuFont->use();
  Games::PangZero::Highscore::MergeUnsavedHighScores($menuResult eq 'challenge' ? 'Cha' : 'Pan');

  return;

  my ($filename, $i) = ('', 1);
  do { $filename     = sprintf("record%03d.txt", $i); ++$i } while (-f $filename);
  open RECORD, ">$filename";
  print RECORD "NumGuys = $NumGuys;\nDifficultyLevelIndex = $DifficultyLevelIndex;\nrecord = '$Game->{record}';\n",
    "DeathBallsEnabled = $DeathBallsEnabled;\nEarthquakeBallsEnabled = $EarthquakeBallsEnabled;\n",
    "WaterBallsEnabled = $WaterBallsEnabled;\nSeekerBallsEnabled = $SeekerBallsEnabled;\n",
    'rand = [', join(',', @{$Game->{rand}}), "];\n\n";
  close RECORD;

  $Game = Games::PangZero::DemoPlaybackGame->new($NumGuys, $DifficultyLevelIndex, $Game->{record}, $Game->{rand}, {});
  $Game->Run();
  $Game->RestoreGameSettings();
}

sub ShowErrorMessage {
  my ($message) = @_;

  return if $ENV{PANGZERO_TEST};

  $message = "Pang Zero $VERSION died:\n$message";
  if (Games::PangZero::Config::IsMicrosoftWindows()) {
    eval( '
      use Win32;
      Win32::MsgBox($message, MB_ICONEXCLAMATION, "Pang Zero error");
    ' );
    return;
  } elsif ($ENV{'DISPLAY'}) {
    $message =~ s/\"/\\"/g;
    my @tryCommands = (
      "kdialog --msgbox \"$message\"",
      "gmessage -center \"$message\"",
      "xmessage -center \"$message\"",
    );
    foreach (@tryCommands) {
      `$_`;
      return if $? == 0;
    }
  }
}

sub ShowWebPage {
  my ($url) = @_;

  return if $ENV{PANGZERO_TEST};

  if (Games::PangZero::Config::IsMicrosoftWindows()) {
    my $ws = "$DataDir/website.html";
    $ws =~ s/\//\\\\/g;
    exec 'cmd', '/c', $ws;
    exit;
  } elsif ($ENV{'DISPLAY'}) {
    my @tryCommands = (
      "gnome-open $url",
      "mozilla-firefox $url",
      "firefox $url",
      "mozilla $url",
      "konqueror $url",
    );
    foreach (@tryCommands) {
      `$_`;
      return if $? == 0;
    }
  } else {
    print "Visit $url for more info about Pang Zero $Games::PangZero::VERSION\n";
  }
}

1;
