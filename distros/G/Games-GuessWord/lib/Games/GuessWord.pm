package Games::GuessWord;
use vars qw($VERSION);
use strict;
use warnings;
$VERSION = '0.16';

=head1 NAME

Games::GuessWord - Guess the letters in a word (ie Hangman)

=head1 SYNOPSIS

  use Games::GuessWord;

  my $g = Games::GuessWord->new(file => "/path/to/wordlist");
  print   "Score: " . $g->score . "\n";
  print "Chances: " . $g->chances . "\n";
  print  "Answer: " . $g->answer . "\n";
  my @guesses = $g->guesses;
  $g->guess("t");
  # ...
  if ($g->won) {
    print "You won!\n";
    $g->new_word;
  }

=head1 DESCRIPTION

This module is a simple wrapper around a word guessing game. You have
to guess the word by guessing letters in the word, and is otherwise
known as Hangman.

=head1 METHODS

=head2 new

This is the constructor. You can either pass in a list of words or a
wordlist. A random word is picked:

  my $g = Games::GuessWord->new(words => ["sleepy", "grumpy"]);
  # or...
  my $g = Games::GuessWord->new(file => "t/words");

You can also set the number of chances each game has with the chances
parameter

  my $g = Games::GuessWord->new(file    => "t/words",
                                chances => 5);

=cut

sub new {
  my $class = shift;
  my %conf = @_;

  my $self = {};
  $self->{score} = 0;
  $self->{words} = $conf{words};
  $self->{file} = $conf{file};
  $self->{starting_chances} = $conf{chances} || 6;

  bless $self, $class;
  $self->new_word;

  return $self;
}


=head2 answer

This method returns the current word being guessed, with asterisks (*)
replacing letters that have not been guessed yet. For example, if
trying to guess "buffy" and the letters "b" and "f" have been
correctly guessed, this will return "b*ff*".

  print  "Answer: " . $g->answer . "\n";

=cut

sub answer {
  my $self = shift;
  my $secret = $self->{secret};
  my $guesses = join('', ($self->guesses));
  $secret =~ s/[^1$guesses]/*/g;
  return $secret;
}


=head2 chances

This method returns the number of chances left. You start off with six
chances by default and lose a chance everytime you get a guess wrong.

  print "Chances: " . $g->chances . "\n";

=cut

sub chances {
  my $self = shift;
  return $self->{chances};
}


=head2 guess

This methods guesses a letter in the word:

  $g->guess("t");

=cut

sub guess {
  my $self = shift;
  my $letter = shift;

  if ($self->chances == 0) {
    return undef;
  }

  push @{$self->{guesses}}, $letter;

  if ($self->secret =~ /$letter/) {
    $self->{score} += $self->chances + 1;
  } else {
    $self->{chances}--;
  }
}


=head2 guesses

This method returns the guesses taken so far this turn:

  my @guesses = $g->guesses;

=cut

sub guesses {
  my $self = shift;
  return @{$self->{guesses}};
}


=head2 new_word

This method throws the current turn away and picks a new word:

    $g->new_word;

=cut

sub new_word {
  my $self = shift;
  my $secret;
  if ($self->{words}) {
    $secret = $self->{words}->[int rand(@{$self->{words}})];
  } else {
    open(IN, $self->{file}) or die "Error reading file $self->{file}: $@";
    rand($.) < 1 && ($secret = $_) while <IN>;
    close IN;
    chomp $secret;
  }
  $secret = lc $secret;
  $self->{secret} = $secret;
  $self->{chances} = $self->{starting_chances};
  $self->{guesses} = [];

  $self->{score} = 0 if $self->lost;
  1;
}


=head2 secret

This method returns the secret word that the user is trying to guess:

  my $secret = $g->secret;

=cut

sub secret {
  my $self = shift;
  return $self->{secret};
}


=head2 score

This method returns the current score. You get a higher score if you
guess the word earlier on. The score persists over turns if you win:

  print   "Score: " . $g->score . "\n";

=cut

sub score {
  my $self = shift;
  return $self->{score};
}


=head2 won

Returns true if and only if they have won the game, i.e. if the
answer equals the secret word.

=cut

sub won {
  my $self = shift;
  return $self->answer eq $self->secret
}


=head2 lost

Returns true if and only if they have lost the game, i.e. if they
have no more chances left

=cut

sub lost {
  my $self = shift;
  return $self->chances == 0;
}

=head2 starting_chances

Sets the number of starting chances, i.e. the number of chances
the player gets for each game.  By default this is six.

=cut

sub starting_chances {
  my $self             = shift;
  my $starting_chances = shift;

  $self->{starting_chances} = $starting_chances;
}



=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working in a vacumn
- that it was a bit depressing to keep writing modules but never get
any feedback. So, if you use and like this module then please send me
an email and make my day.

All it takes is a few little bytes.

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2001-8, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
