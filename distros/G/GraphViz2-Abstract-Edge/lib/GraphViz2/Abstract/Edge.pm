use strict;
use warnings;
use utf8;

package GraphViz2::Abstract::Edge;
BEGIN {
  $GraphViz2::Abstract::Edge::AUTHORITY = 'cpan:KENTNL';
}
{
  $GraphViz2::Abstract::Edge::VERSION = '0.002000';
}

# ABSTRACT: Deal with edges independent of a Graph

use GraphViz2::Abstract::Util::Constants;

our @CARP_NOT;


use Class::Tiny {
  URL            => NONE,
  arrowhead      => 'normal',
  arrowsize      => 0.0,
  arrowtail      => 'normal',
  color          => 'black',
  colorscheme    => EMPTY_STRING,
  comment        => EMPTY_STRING,
  constraint     => TRUE,
  decorate       => FALSE,
  dir            => UNKNOWN,
  edgeURL        => EMPTY_STRING,
  edgehref       => EMPTY_STRING,
  edgetarget     => NONE,
  edgetooltip    => EMPTY_STRING,
  fillcolor      => UNKNOWN,
  fontcolor      => 'black',
  fontname       => 'Times-Roman',
  fontsize       => 14.0,
  headURL        => EMPTY_STRING,
  head_lp        => UNKNOWN,
  headclip       => TRUE,
  headhref       => EMPTY_STRING,
  headlabel      => EMPTY_STRING,
  headport       => 'center',
  headtarget     => NONE,
  headtooltip    => EMPTY_STRING,
  href           => EMPTY_STRING,
  id             => EMPTY_STRING,
  label          => EMPTY_STRING,
  labelURL       => EMPTY_STRING,
  labelangle     => -25.0,
  labeldistance  => 1.0,
  labelfloat     => FALSE,
  labelfontcolor => 'black',
  labelfontname  => 'Times-Roman',
  labelfontsize  => 14.0,
  labelhref      => EMPTY_STRING,
  labeltarget    => NONE,
  labeltooltip   => EMPTY_STRING,
  layer          => EMPTY_STRING,
  len            => UNKNOWN,         # backend dependent
  lhead          => EMPTY_STRING,
  lp             => UNKNOWN,
  ltail          => EMPTY_STRING,
  minlen         => 1,
  nojustify      => FALSE,
  penwidth       => 1.0,
  pos            => UNKNOWN,
  samehead       => EMPTY_STRING,
  sametail       => EMPTY_STRING,
  showboxes      => 0,
  style          => EMPTY_STRING,
  tailURL        => EMPTY_STRING,
  tail_lp        => UNKNOWN,
  tailclip       => TRUE,
  tailhref       => EMPTY_STRING,
  taillabel      => EMPTY_STRING,
  tailport       => 'center',
  tailtarget     => NONE,
  tailtooltip    => EMPTY_STRING,
  target         => NONE,
  tooltip        => EMPTY_STRING,
  weight         => 1,
  xlabel         => EMPTY_STRING,
  xlp            => UNKNOWN,
};


use Scalar::Util qw(blessed);
use Scalar::Util qw(refaddr);

sub _is_equal {
  my ( $self, $a_ref, $b_ref ) = @_;

  return   if defined $a_ref     and not defined $b_ref;
  return   if not defined $a_ref and defined $b_ref;
  return 1 if not defined $a_ref and not defined $b_ref;

  ## A and B are both defined.

  return if not ref $a_ref and ref $b_ref;
  return if ref $a_ref and not $b_ref;

  if ( not ref $a_ref and not ref $b_ref ) {
    return $a_ref eq $b_ref;
  }

  ##  A and B are both refs.
  return refaddr $a_ref eq refaddr $b_ref;
}

sub _is_magic {
  my ( $self, $value ) = @_;
  return if not defined $value;
  return if not ref $value;
  my $addr = refaddr $value;
  return 1 if $addr eq refaddr UNKNOWN;
  return 1 if $addr eq refaddr NONE;
  return;
}

sub _foreach_attr {
  my ( $self, $callback ) = @_;
  if ( not blessed($self) ) {
    require Carp;
    local @CARP_NOT = 'GraphViz2::Abstract::Edge';
    Carp::croak('Can\'t call as_hash on a class');
  }
  my $class    = blessed($self);
  my @attrs    = Class::Tiny->get_all_attributes_for($class);
  my $defaults = Class::Tiny->get_all_attribute_defaults_for(__PACKAGE__);
  for my $attr (@attrs) {
    my $value       = $self->$attr();
    my $has_default = exists $defaults->{$attr};
    my $default;
    if ($has_default) {
      $default = $defaults->{$attr};
    }
    $callback->( $attr, $value, $has_default, $default );
  }
  return $self;
}


sub as_hash {
  my ($self) = @_;
  my %output;

  $self->_foreach_attr(
    sub {
      my ( $attr, $value, $has_default, $default ) = @_;
      if ( not $has_default ) {
        return if $self->_is_magic($value);
        $output{$attr} = $value;
        return;
      }
      return if $self->_is_equal( $value, $default );
      return if $self->_is_magic($value);
      $output{$attr} = $value;
    }
  );
  return \%output;
}


sub as_canon_hash {
  my ($self) = @_;
  my %output;
  $self->_foreach_attr(
    sub {
      my ( $attr, $value, $has_default, $default ) = @_;
      return if $self->_is_magic($value);
      $output{$attr} = $value;
    }
  );
  return \%output;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GraphViz2::Abstract::Edge - Deal with edges independent of a Graph

=head1 VERSION

version 0.002000

=head1 SYNOPSIS

    use GraphViz2::Abstract::Edge;

    my $edge = GraphViz2::Abstract::Edge->new(
            color =>  ... ,
            id    =>  ... ,
            label =>  ... ,
    );

    # Mutate $edge

    $edge->label("Asdft");

    my $fillcolor = $edge->fillcolor(); # Knows that the fill color is light grey despite never setting it.

    # Later:

    $graph->add_edge(from => a => to => b => %{ $edge->as_hash }); # Adds only the data that is not the same as GraphViz's defaults
    $graph->add_edge(from => a => to => b => %{ $edge->as_canon_hash }); # Adds all the data, including hardcoded defaults

=head1 DESCRIPTION

Working with GraphViz2, I found myself frequently needing shared styles for things, and I often had trouble knowing
which fields were and weren't valid for given things, for instance: C<Edge>s.

Its reasonably straight forward to ask the question "What is the attribute C<foo> applicable to" using the GraphViz website,
but much harder to know "What are all the attributes applicable to C<foo>".

Let alone work with them in a user friendly way from code.

=head2 Naming Rationale

I tried to choose a name that was not so likely to threaten GraphViz2 if GraphViz2 wanted to make a different
variation of what I'm doing, but as part of GraphViz2 itself.

As such, I plan on a few C<::Abstract> things, that aim to be stepping stones for dealing with complex data independent of C<GraphViz2>,
but in such a way that they make importing that data into C<GraphViz2> easy.

=head1 METHODS

=head2 C<as_hash>

This method returns all the values of all properties that B<DIFFER> from the defaults.

e.g.

    Edge->new( color => 'black' )->as_hash();

Will return an empty list, as the default color is normally black.

See also L<< how special constants work in|GraphViz2::Abstract::Util::Constants/CONSTANTS >>

=head2 C<as_canon_hash>

This method returns all the values of all properties, B<INCLUDING> defaults.

e.g.

    Edge->new( color => 'black' )->as_canon_hash();

Will return a very large list containing all the properties that we know the default values for.

See also L<< how special constants work in|GraphViz2::Abstract::Util::Constants/CONSTANTS >>

=head1 ATTRIBUTES

=head2 C<URL>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<arrowhead>

Default: C<'normal'>

=head2 C<arrowsize>

Default: C<0.0>

=head2 C<arrowtail>

Default: C<'normal'>

=head2 C<color>

Default: C<'black'>

=head2 C<colorscheme>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<comment>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<constraint>

Default: L<< C<true>|GraphViz2::Abstract::Util::Constants/TRUE >>

=head2 C<decorate>

Default: L<< C<false>|GraphViz2::Abstract::Util::Constants/FALSE >>

=head2 C<dir>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<edgeURL>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<edgehref>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<edgetarget>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<edgetooltip>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<fillcolor>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<fontcolor>

Default: C<'black'>

=head2 C<fontname>

Default: C<'Times-Roman'>

=head2 C<fontsize>

Default: C<14.0>

=head2 C<headURL>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<head_lp>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<headclip>

Default: L<< C<true>|GraphViz2::Abstract::Util::Constants/TRUE >>

=head2 C<headhref>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<headlabel>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<headport>

Default: C<'center'>

=head2 C<headtarget>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<headtooltip>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<href>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<id>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<label>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<labelURL>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<labelangle>

Default: C<-25.0>

=head2 C<labeldistance>

Default: C<1.0>

=head2 C<labelfloat>

Default: L<< C<false>|GraphViz2::Abstract::Util::Constants/FALSE >>

=head2 C<labelfontcolor>

Default: C<'black'>

=head2 C<labelfontname>

Default: C<'Times-Roman'>

=head2 C<labelfontsize>

Default: C<14.0>

=head2 C<labelhref>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<labeltarget>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<labeltooltip>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<layer>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<len>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

Reason: back-end dependent

=head2 C<lhead>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<lp>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<ltail>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<minlen>

Default: C<1>

=head2 C<nojustify>

Default: L<< C<false>|GraphViz2::Abstract::Util::Constants/FALSE >>

=head2 C<penwidth>

Default: C<1.0>

=head2 C<pos>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<samehead>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<sametail>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<showboxes>

Default: 0

=head2 C<style>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<tailURL>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<tail_lp>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head2 C<tailclip>

Default: L<< C<true>|GraphViz2::Abstract::Util::Constants/TRUE >>

=head2 C<tailhref>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<taillabel>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<tailport>

Default: C<'center'>

=head2 C<tailtarget>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<tailtooltip>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<target>

Default: L<< C<none>|GraphViz2::Abstract::Util::Constants/NONE >>

=head2 C<tooltip>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<weight>

Default: C<1>

=head2 C<xlabel>

Default: L<< C<"">|GraphViz2::Abstract::Util::Constants/EMPTY_STRING >>

=head2 C<xlp>

Default: L<< C<unknown>|GraphViz2::Abstract::Util::Constants/UNKNOWN >>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
