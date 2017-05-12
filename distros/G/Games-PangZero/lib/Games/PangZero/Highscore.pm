##########################################################################
# HIGH SCORE TABLE
##########################################################################
package Games::PangZero::Highscore;

use vars qw( @Games::PangZero::UnsavedHighScores );

foreach (@Games::PangZero::DifficultyLevels) {
  $_->{highScoreTablePan} = [ ['UPI', 250000], ['UPI', 200000], ['UPI', 150000], ['UPI', 100000], ['UPI', 50000] ];
  $_->{highScoreTablePan} = [ ['UPI', 2500], ['UPI', 2000], ['UPI', 1500], ['UPI', 1000], ['UPI', 500] ] if $_->{name} eq 'Miki';
  $_->{highLevelTablePan} = [ ['UPI', 50], ['UPI', 40], ['UPI', 30], ['UPI', 20], ['UPI', 10] ];
  $_->{highLevelTablePan} = [ ['UPI', 20], ['UPI', 16], ['UPI', 12], ['UPI', 8], ['UPI', 4] ] if $_->{name} eq 'Miki';
  $_->{highScoreTableCha} = [ ['UPI', 250000], ['UPI', 200000], ['UPI', 150000], ['UPI', 100000], ['UPI', 50000] ];
  $_->{highLevelTableCha} = [ ['UPI', 30], ['UPI', 25], ['UPI', 20], ['UPI', 15], ['UPI', 10] ];
}

sub AddHighScore {
  my ($player, $score, $level) = @_;
  
  unshift @Games::PangZero::UnsavedHighScores, [$player, $score, $level];
}

sub MergeUnsavedHighScores {
  my ($table) = @_;
  my ($unsavedHighScore, $player, $score, $level);
  
  die unless ($table =~ /^(Cha|Pan)$/);
  foreach $unsavedHighScore (@Games::PangZero::UnsavedHighScores) {
    ($player, $score, $level) = @{$unsavedHighScore};
    &MergeUnsavedHighScore( $Games::PangZero::DifficultyLevel->{"highScoreTable$table"}, $player, $score );
    &MergeUnsavedHighScore( $Games::PangZero::DifficultyLevel->{"highLevelTable$table"}, $player, $level );
  }
  
  splice @{$Games::PangZero::DifficultyLevel->{"highScoreTable$table"}}, 5;
  splice @{$Games::PangZero::DifficultyLevel->{"highLevelTable$table"}}, 5;
  @Games::PangZero::UnsavedHighScores = ();
  my $newHighScore = &InputPlayerNames($table);
  if ($newHighScore) {
    $Game->RunHighScore( $Games::PangZero::DifficultyLevelIndex, $table, 0 );
  }
}

sub MergeUnsavedHighScore {
  my ($highScoreList, $player, $score) = @_;
  my ($i);
  
  for ($i = 0; $i < scalar @{$highScoreList}; ++$i) {
    if ($highScoreList->[$i]->[1] < $score) {
      splice @{$highScoreList}, $i, 0, [$player, $score];
      return;
    }
  }
}

sub InputPlayerNames {
  my ($table) = @_;
  my ($highScoreEntry, $player, $score, $message, $retval);
  
  die unless ($table =~ /^(Cha|Pan)$/);
  $retval = 0;
  foreach $highScoreEntry (@{$Games::PangZero::DifficultyLevel->{"highScoreTable$table"}}, @{$Games::PangZero::DifficultyLevel->{"highLevelTable$table"}}) {
    $player = $highScoreEntry->[0];
    next unless ref $player;
    unless ($player->{highScoreName}) {
      $score                   = $highScoreEntry->[1];
      $message                 = $score < 1000 ? "Level $score" : "Score $score";
      $player->{highScoreName} = &InputPlayerName($player, $message);
    }
    $highScoreEntry->[0] = $player->{highScoreName};
    $retval              = 1;
  }
  foreach $player (@Games::PangZero::Players) {
    delete $player->{highScoreName};
  }
  return $retval;
}

sub InputPlayerName {
  my ($player, $message) = @_;
  my ($nameMenuItem, @menuItems, $x, $y, $yInc);
  
  SDL::Events::enable_unicode(1);
  $Games::PangZero::UnicodeMode = 1;
  my $name               = ($player->{name} or '') . '|';
  my $guy                = Games::PangZero::Guy->new($player);
  ($guy->{x}, $guy->{y}) = (150, 150);
  $guy->DemoMode();
  
  ($x, $y, $yInc) = (230, 80, 45);
  push @menuItems, (
    Games::PangZero::MenuItem->new( $x, $y += $yInc, "HIGH SCORE!!!"),
    Games::PangZero::MenuItem->new( $x, $y += $yInc, $message),
    Games::PangZero::MenuItem->new( $x, $y += $yInc, "Please enter your name:"),
    $nameMenuItem = Games::PangZero::MenuItem->new( $x, $y += $yInc, $name ),
  );
  push @Games::PangZero::GameObjects, ($guy, @menuItems);
  
  while (1) {
    $Games::PangZero::LastUnicodeKey = 0;
    $Game->MenuAdvance();
    last if $Game->{abortgame};
    if (%Events) {
      my ($key) = %Events;
      if ($key == SDLK_BACKSPACE) {
        substr($name, -2, 1, '');        # Remove next to last char
        $nameMenuItem->SetText($name);
      } elsif ($key == SDLK_RETURN) {
        last;
      } elsif ($LastUnicodeKey < 127 and $Games::PangZero::LastUnicodeKey >= 32 and length($name) < 9) {
        substr($name, -1, 0, chr($Games::PangZero::LastUnicodeKey));   # Insert before last char
        $nameMenuItem->SetText($name);
      }
    }
  }
  $name           =~ s/\|$//;
  $player->{name} = $name;
  $name           = "Anonymous" if $name =~ /^\s*$/;
  $guy->Delete();
  foreach (@menuItems) {
    $_->Delete();
  }
  SDL::Events::enable_unicode(0); $Games::PangZero::UnicodeMode = 0;
  return $name;
}

1;
