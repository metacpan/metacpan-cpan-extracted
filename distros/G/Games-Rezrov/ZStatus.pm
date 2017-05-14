package Games::Rezrov::ZStatus;
# all info required to refresh the status line; see spec 8.2

use Games::Rezrov::MethodMaker ([],
			 qw(
			    score
			    moves
			    hours
			    minutes
			    time_game
			    score_game
			    location
			   ));

use Games::Rezrov::Inliner;

1;

my $INLINE_CODE = '
sub update () {
  # refresh information required for status line.
  my $self = shift;
  
  # get the current location:
  my $object_id = get_global(0);
  # 8.2.2.1
  
  my $zobj = new Games::Rezrov::ZObject($object_id);
  # FIX ME: use cache
  $self->location(${$zobj->print(Games::Rezrov::StoryFile::ztext())});
#  die "loc = $location";

  my $g1 = get_global(1);
  my $g2 = get_global(2);
  if ($self->time_game()) {
    $self->hours($g1);
    $self->minutes($g2);
  } else {
    $self->score(SIGNED_WORD($g1));
    $self->moves($g2);
  }
}
';

Games::Rezrov::Inliner::inline(\$INLINE_CODE);
#print $INLINE_CODE;
#die;
eval $INLINE_CODE;
undef $INLINE_CODE;

sub new {
  my $self = [];
  bless $self, shift;
  
  $self->hours(0);
  $self->minutes(0);
  $self->moves(0);
  $self->score(0);
  $self->time_game(0);
  $self->score_game(0);
  
  if (Games::Rezrov::StoryFile::header()->is_time_game()) {
    $self->time_game(1);
  } else {
    $self->score_game(1);
  }
  return $self;
}

sub get_global {
  return Games::Rezrov::StoryFile::get_global_var($_[0]);
}


1;
