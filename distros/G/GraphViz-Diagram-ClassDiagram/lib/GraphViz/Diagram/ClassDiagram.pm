#_{ Encoding and name
=encoding utf8
=head1 NAME

C<GraphViz::Diagram::ClassDiagram> - Create class diagrams with graphviz.

C<GraphViz::Diagram::ClassDiagram> builds on L<GraphViz::Graph>.

=cut
package GraphViz::Diagram::ClassDiagram;

use strict;
use warnings;
use utf8;
#_}
#_{ Version
=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @ISA = qw(GraphViz::Graph);
#_}
#_{ Synopsis
=head1 SYNOPSIS

    use GraphViz::Diagram::ClassDiagram;
   
=cut
#_}
#_{ use …
use Carp;
use GraphViz::Diagram::ClassDiagram::Class;
use GraphViz::Diagram::ClassDiagram::GlobalVar;
use GraphViz::Graph;
#_}
#_{ Methods
#_{ POD
=head1 METHODS

=cut
#_}
sub new { #_{

=head2 new

    my $class_diagram = GraphViz::Diagram::ClassDiagram->new('File.pdf');

Start drawing a class diagram.

=cut

  my $class          = shift;
  my $output_file    = shift;
  my $opts           = shift // {};

  # TODO: same functionality already used in GraphViz::Diagram::GitRepository
  my ($file_base_name, $suffix) = $output_file =~ m!(.*)\.([^.]+)$!;

  my $self           = GraphViz::Graph->new($file_base_name);
  $self -> {suffix } = $suffix;
  $self -> {nodes_ } = [];
  $self -> {links  } = [];

  bless $self, $class;
  return $self;

} #_}
sub title { #_{

=head2 title

    $class_diagram -> title("Foo classes");

Start drawing a class diagram.

=cut

  # TODO: same functionality already used in GraphViz::Diagram::GitRepository

  my $self   = shift;
  my $title  = shift;

  my $title_label = $self->label({html => "<font point-size='30'>$title</font>"});
  $title_label->loc('t');

} #_}
sub class { #_{

=head2 class

    my $CFoo = $class_diagram -> class("CFoo");

Add a L<GraphViz::Diagram::ClassDiagram::Class> to the class diagram

=cut

  my $self       = shift;
  my $class_name = shift;

  my $class      = GraphViz::Diagram::ClassDiagram::Class->new($class_name, $self);

  push @{$self->{nodes_ }}, $class;

  return $class;

} #_}
sub global_var { #_{
#_{ POD
=head2 global_var

    my $g_foo = $classes -> global_var('foo');

Add a L<GraphViz::Diagram::ClassDiagram::GlobalVar> to the class diagram.j

=cut
#_}
  
  my $self            = shift;
  my $global_var_name = shift;

  my $global_var      = GraphViz::Diagram::ClassDiagram::GlobalVar->new($global_var_name, $self);

  push @{$self->{nodes_ }}, $global_var;

  return $global_var;

} #_}
sub link { #_{
=head2 link

    $class_diagram->link($class_one     , $class_two);
    $class_diagram->link($class_one     , $attribute_three);
    $class_diagram->link($attribute_four, $class_five);

Connect classes, attributes and methodes one to another.

=cut

  my $self = shift;
  my $from = shift;
  my $to   = shift;

  my $link_description = {from => $from, to => $to};

  push @{$self->{links}}, $link_description;

  return $link_description;

} #_}
sub inheritance { #_{
#_{ POD
=head2 inheritance

     my $class_base = $class_diagram->class("CBase");
     my $class_derv = $class_diagram->class("CDerived");
     # …
     $class_diagram->inheritance($class_base, $class_derv);

It's probably better to use L<< $class_derv->inherits_from($clas_base) >>.


=cut
#_}

  my $self       = shift;
  my $class_base = shift;
  my $class_derv = shift;

  croak "ClassDiagram - derives_from, class_base ($class_base) is not a GraphViz::Diagram::ClassDiagram::Class" unless ref $class_base eq 'GraphViz::Diagram::ClassDiagram::Class';
  croak "ClassDiagram - derives_from, class_derv ($class_base) is not a GraphViz::Diagram::ClassDiagram::Class" unless ref $class_base eq 'GraphViz::Diagram::ClassDiagram::Class';

  my $link_description = $self->link($class_base, $class_derv);
  $link_description -> {inheritance} = 1;

} #_}
sub create { #_{
#_{
=head2 create
    $class_diagram -> create();

Writes the class diagram:

=over

=item * L<renders|GraphViz::Diagram::ClassDiagram::Class/render> L<classes|GraphViz::Diagram::ClassDiagram::Class>

=item * Draw L<edges|GraphViz::Graph::Edge> between classes

back

=cut
#_}
  my $self    = shift;

  for my $class (@{$self->{nodes_ }}) {
    $class->render();
  }
  for my $link_description (@{$self->{links}}) {

    my $edge = $self->edge(
      $link_description->{from}->connector_for_links(),
      $link_description->{to  }->connector_for_links
    );

    if ($link_description->{inheritance}) {
      $edge->arrow_end('invempty');
    }
  }

  $self->SUPER::create($self->{suffix});

} #_}
sub color_comment { #_{

=head2 color_comment
    my $color_comment = GraphViz::Diagram::ClassDiagram::color_comment()

Static method. Returns the color for comments.

Compare with L<GraphViz::Diagram::ClassDiagram::Attribute/ident_color>

=cut

  return '#22c050';

} #_}

#_}
#_{ Source Code
=head1 Source code

The source code is on L<github|https://github.com/ReneNyffenegger/perl-GraphViz-Diagram-ClassDiagram>.

=cut
#_}

'tq84';
