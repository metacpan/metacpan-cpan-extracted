package Lingua::LinkParser::Linkage;
use strict;
use Lingua::LinkParser::Linkage::Sublinkage;
use Lingua::LinkParser::Linkage::Sublinkage::Link;
use Lingua::LinkParser::Linkage::Word;

# "as_string" prints a diagram, "new_as_string" prints a 
# single string to pattern match link grammar.

#use overload q("") => "as_string";
use overload q("") => "new_as_string";
use vars qw($VERSION);

$VERSION = '1.17';

sub new {
  unless (@_ == 4) { die 'usage: Lingua::LinkParser::Linkage->new ($index, $sent, $opts)' }
  my $class = shift;
  my $index = shift;
  my $sent = shift;
  my $opts = shift;
  my $self = bless {
    linkage => Lingua::LinkParser::linkage_create ($index-1,$sent,$opts),
  };
  return $self;
}

sub new_as_string {
  my $linkage = shift;
  my $return = '';
  my $i = 0;
  foreach my $word ($linkage->words) {
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

sub as_string {
    my $self = shift;
    Lingua::LinkParser::get_diagram('',$self);
}

sub sent { $_[0]->{sent} }

sub num_sublinkages {
    my $self = shift;
    Lingua::LinkParser::linkage_get_num_sublinkages($self->{linkage});
}

sub sublinkage {
    my $self = shift;
    my $index = shift;
    Lingua::LinkParser::Linkage::Sublinkage->new($index,$self->{linkage});
}

sub sublinkages {
    my $self = shift;
    my @sublinkages;
    my $i;
    for $i (0 .. ($self->num_sublinkages - 1)) {
      push(@sublinkages,Lingua::LinkParser::Linkage::Sublinkage->new($i,$self->{linkage}));
    }
    @sublinkages;
}

sub compute_union {
    my $self = shift;
    Lingua::LinkParser::linkage_compute_union($self->{linkage});
} 

sub num_words {
    my $self = shift;
    Lingua::LinkParser::linkage_get_num_words($self->{linkage});
}

sub get_word {
    my $self = shift;
    my $index = shift;
    Lingua::LinkParser::linkage_get_word($self->{linkage},$index);
}

sub get_words {
    my $self = shift;
    Lingua::LinkParser::call_linkage_get_words($self->{linkage});
}

sub violation_name {
     my $self = shift;
     Lingua::LinkParser::linkage_get_violation_name($self->{linkage});
}

sub constituent_tree {
    my $self = shift;
    my $tree = Lingua::LinkParser::linkage_constituent_tree($self->{linkage});
    ## build and return a data structure representing the constituent tree
    
    return _constituent_tree_process($tree);
}

sub _constituent_tree_process {
    my $cnode = shift;
    my $child = Lingua::LinkParser::linkage_constituent_node_get_child($cnode);
    my $next  = Lingua::LinkParser::linkage_constituent_node_get_next($cnode);
    my $label = Lingua::LinkParser::linkage_constituent_node_get_label($cnode);
    my $start = Lingua::LinkParser::linkage_constituent_node_get_start($cnode);
    my $end   = Lingua::LinkParser::linkage_constituent_node_get_end($cnode);
    
    my @tree;
    
    my $node = { label => $label, start => $start, end => $end };
    
    if ($child) {
        $node->{child} = _constituent_tree_process( $child );
    }
    
    push @tree, $node;

    if ($next) {
        push @tree, _constituent_tree_process( $next );
    }

    return \@tree; 
}

sub close {
      my $self = shift;
      $self->DESTROY();
}

sub DESTROY {
      my $self = shift;
      Lingua::LinkParser::linkage_delete($self->{linkage});
}

sub num_links {
        my $self = shift;
        Lingua::LinkParser::linkage_set_current_sublinkage($self->{linkage},($self->{index} || 0) - 1);
        Lingua::LinkParser::linkage_get_num_links($self->{linkage});
}

sub link {
        my $self = shift;
        my $index = shift;
        my $link = Lingua::LinkParser::Linkage::Sublinkage::Link->new($index,$self->{index},$self->{linkage});
      return $link;
}

sub links {
        my $self = shift;
        my @links;
        my $i;
        for $i (0 .. ($self->num_links - 1)) {
            push(@links, Lingua::LinkParser::Linkage::Sublinkage::Link->new($i,$self->{index},$self->{linkage}));
        }
        @links;
}

sub words {
      my $self = shift;
      my @words;
      $self->compute_union;
      for my $i (0 .. ($self->num_words - 1)) {
          push @words, Lingua::LinkParser::Linkage::Word->new($self,$i);
      }
      @words;
}

sub word {
      my $self  = shift;
      my $index = shift;
      $self->compute_union;
      Lingua::LinkParser::Linkage::Word->new($self,$index);
}

1;

