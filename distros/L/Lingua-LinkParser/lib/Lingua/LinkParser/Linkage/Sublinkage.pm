package Lingua::LinkParser::Linkage::Sublinkage;

use strict;
use Lingua::LinkParser::Linkage::Sublinkage::Link;
use overload '""' => "new_as_string";
use vars qw($VERSION);

$VERSION = '1.17';

sub new {
  my $class = shift;
  my $index = shift;
  my $linkage = shift;
  my $self = {};
  bless $self, $class;
  $self->{index} = $index;
  $self->{linkage} = $linkage;
  return $self;
}

sub as_string {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  Lingua::LinkParser::linkage_print_diagram($self->{linkage});
}

sub new_as_string {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  my $return = '';
  my $i = 0;
  foreach my $word ($self->words) {
      my ($before,$after) = ('','');
      foreach my $link ($word->links) {
          my $position = $link->linkposition;
          my $text     = $link->linkword;
          my $type = $link->linklabel;
          if ($position < $i) {
              $before .= "$type:$position:$text ";
          } elsif ($position > $i) {
              $after.= "$type:$position:$text ";
          }
      }
      $return .= "(" . $before . " \"" . $word->text . "\" " .
              $after . ")" ;
      $i++;
  }
  "(" . $return . ")";
}

sub num_links {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  return Lingua::LinkParser::linkage_get_num_links($self->{linkage});
}

sub link {
  my $self = shift;
  my $index = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  my $link = Lingua::LinkParser::Linkage::Sublinkage::Link->new($index,$self->{index},$self->{linkage});
  return $link;
}

sub links {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  my @links;
  my $i;
  for $i (0 .. ($self->num_links - 1)) {
      push(@links, Lingua::LinkParser::Linkage::Sublinkage::Link->new($i,$self->{index},$self->{linkage}));                                                             }
  return @links;
}
sub get_word {
  my $self = shift;
  my $index = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  return Lingua::LinkParser::linkage_get_word($self->{linkage},$index);
}

sub num_words {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  return Lingua::LinkParser::linkage_get_num_words($self->{linkage});
}

sub words {
  my $self = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  my @words;
  for my $i (0 .. ($self->num_words - 1)) {
      push @words, Lingua::LinkParser::Linkage::Word->new($self,$i);
  }
  @words;
}

sub word {                                                                                 my $self  = shift;
  Lingua::LinkParser::linkage_set_current_sublinkage
          ($self->{linkage},$self->{index}-1);
  my $index = shift;
  Lingua::LinkParser::Linkage::Word->new($self,$index);
}

1;

