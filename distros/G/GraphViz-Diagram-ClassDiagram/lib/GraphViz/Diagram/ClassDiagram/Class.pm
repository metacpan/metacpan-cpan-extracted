package GraphViz::Diagram::ClassDiagram::Class;
#_{ use
use warnings;
use strict;

use Carp;
use GraphViz::Diagram::ClassDiagram;
#_}
use GraphViz::Diagram::ClassDiagram;
use GraphViz::Diagram::ClassDiagram::Method;
use GraphViz::Diagram::ClassDiagram::Node_;
use GraphViz::Diagram::ClassDiagram::Attribute;

our $VERSION = $GraphViz::Diagram::ClassDiagram::VERSION;
our @ISA = qw(GraphViz::Diagram::ClassDiagram::Node_);
#_{ POD: Name
=head1 NAME

C<GraphViz::Diagram::ClassDiagram::Class>: A class that represents classes.

=encoding utf8
=head1 SYNOPSIS

     my $graph = GraphViz::Diagram::ClassDiagram->new(…);

     my $class = $graph->class("ClassName");
     …

=cut
#_}
#_{ POD: Methods
=head1 METHODS

=cut
#_}
sub new { #_{
#_{ POD
=head2 new

    C<new> should not be directly called by the user. Instead, he should
    call C<< $graph->class(…) >>

=cut
#_}


  my $class          = shift;
  my $class_name     = shift;
  my $class_diagram  = shift; # The class diagram on which this class should be drawn

# my $opts           = shift // {};

  croak "Class - new, class=$class instead GraphViz::Diagram::ClassDiagram::Class"             unless     $class eq 'GraphViz::Diagram::ClassDiagram::Class';
  croak "Class - new, class_name=$class_name instead of a string"                     if     ref $class_name;
  croak "Class - new, class_diagram=$class_diagram instead of GraphViz::Diagram::ClassDiagram" unless ref $class_diagram eq 'GraphViz::Diagram::ClassDiagram';

  my $self = $class->GraphViz::Diagram::ClassDiagram::Node_::new($class_name, $class_diagram);

  $self->{class_elements} = [];

  return $self;

} #_}
sub file { #_{
#_{ POD
=head2 file

=cut
#_}
  my $self    = shift;
  my $file    = shift;

  $self->{file} = $file;
  return $self;
} #_}
sub comment { #_{
#_{ POD
=head2 comment

=cut
#_}
  my $self    = shift;
  my $comment = shift;

  push @{$self->{comments}}, $comment;
  return $self;
} #_}
sub method { #_{
#_{ POD
=head2 method

=cut
#_}

  my $self  = shift;
  my $ident = shift;
  my $opts  = shift;

  my $method = GraphViz::Diagram::ClassDiagram::Method->new($self, $ident, $opts);

  push @{$self->{class_elements}}, $method;

  return $method;

} #_}
sub attribute { #_{
#_{ POD
=head2 attribute

=cut
#_}

  my $self  = shift;
  my $ident = shift;
  my $opts  = shift;

  my $method = GraphViz::Diagram::ClassDiagram::Attribute->new($self, $ident, $opts);

  croak "Class - attribute: $method is not a GraphViz::Diagram::ClassDiagram::Attribute" unless ref $method eq 'GraphViz::Diagram::ClassDiagram::Attribute';

  push @{$self->{class_elements}}, $method;

  return $method;

} #_}
sub inherits_from { #_{
#_{ POD
=head2 new

     my $class_base = $class_diagram->class("CBase");
     my $class_derv = $class_diagram->class("CDerived");

     $class_derv -> inherits_from($class_base);

     # Multiple base classes
     $class_xyz -> inherits_from($class_abc, $class_def, $class_ghi);

=cut
#_}
  
  my $self = shift;

  for my $base_class (@_) {
    croak "GraphViz::Diagram::ClassDiagram::Class - inherits_from base_class $base_class is not a GraphViz::Diagram::ClassDiagram::Class" unless $base_class->isa('GraphViz::Diagram::ClassDiagram::Class');
    $self->{class_diagram}->inheritance($base_class, $self);
  }

} #_}
sub render { #_{
#_{ POD
=head2 render

Renders the html for the Class. Should not be called by the user, it's called
by L<GraphViz::Diagram::ClassDiagram/create>.

=cut
#_}
  my $self  = shift;

  my $colspan_max= colspan_();

  my $border_below = " $colspan_max border='4' sides='b'";
  my $border_etc = '';
  
  if (! $self->{file} and ! @{$self->{comments}}) {
    $border_etc = $border_below;
  }
  else {
    $border_etc = " border='0' $colspan_max";
  }
  my $tr_class_name = "<tr><td$border_etc align='left'><b>$self->{name}</b></td></tr>";
  my $tr_file='';
  my $tr_comments='';
  my $tr_class_elems='';

  if ($self->{file}) { #_{
    if (! $self->{file} and ! @{$self->{comments}}) {
      $border_etc = $border_below
    }
    else {
      $border_etc = " border='0' $colspan_max";
    }
    $tr_comments .= "<tr><td$border_etc align='left'><font face='courier' point-size='10'>$self->{file}</font></td></tr>";
  } #_}

  my $color_comment = GraphViz::Diagram::ClassDiagram::color_comment();
  my $comment_cnt = 0;
  for my $comment (@{$self->{comments}}) { #_{
    $comment_cnt ++;
    if ($comment_cnt == @{$self->{comments}}) {
       $border_etc = $border_below;
    }
    else {
       $border_etc = " border='0' $colspan_max";
    }
    $tr_comments .= "<tr><td$border_etc align='left'><font color='$color_comment'>$comment</font></td></tr>";
  } #_}

  my $first_row = 1;
  for my $class_elem (@{$self->{class_elements}}) { #_{
    $tr_class_elems .= $class_elem->tr($first_row) . "\n";
    $first_row = 0;
  } #_}

  $self->label({html=>
      "<table cellspacing='0' border='1'>
         $tr_class_name
         $tr_file
         $tr_comments
         $tr_class_elems
       </table>"
     });

} #_}
sub connector_for_links { #_{
#_{ POD
=head2 connector_for_links

Returns an L<GraphViz::Graph::Node> that can be used in L<GraphViz::Graph> C<< -> C<edge() >>.

=cut
#_}
  
  my $self = shift;

# croak "class_node is not defined. Was render' alread called?" unless $self->{class_node};

  return $self;#->{class_node};
 
} #_}
sub colspan_ { #_{
#_{ POD
=head2 colspan_

A private static method. Returns the necessary C<colspan='n'> for C<< <td> >>'s that are to span the entire table.

=cut
#_}

  return "colspan='2'";

} #_}


'tq84';
