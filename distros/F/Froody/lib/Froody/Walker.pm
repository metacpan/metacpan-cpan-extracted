=head1 NAME

Froody::Walker;

=head1 SYNOPSIS

  my $spec        = $froody_method->structure;
  my $method_name = $froody_method->name;
  
  # create a new walker that knows about the spec
  my $walker = Froody::Walker->new($spec, "method name");
  my $terse = Froody::Walker::Terse->new;
  my $xml = Froody::Walker::XML->new;
  $walker->from($terse)->to($xml);
  
  # walk $source turning it into xml
  my $xml = $walker->walk($data);

=head1 DESCRIPTION

Walker classes are constucted with a description of the structure it
will generate. That structure is a very specific grammar listing
paths into the object that can be built.

Setting L<from|/METHODS>  and L<to|/METHODS> designates the source and
targets for the transformation, respectively. We currently provide
two data structures C<Froody::Walker::Terse> and C<Froody::Walker::XML>
as transformation engines, which will both work bi-directionally.

=cut

package Froody::Walker;
use strict;
use warnings;

use base 'Class::Accessor::Chained::Fast';

__PACKAGE__->mk_accessors(qw{spec method});

use Froody::Logger;
use Froody::Error;

use Scalar::Util qw(weaken);

my $logger = get_logger("froody.walker");

=head2 METHODS

=over

=item $self->walk($spec, $data)

Walks the structure of data with the source C<Froody::Walker::Driver>,
returning a transformed version of the data as per the designation of
the target.

=cut

sub walk {
    my ($self, $source) = @_;

    $source = $self->from->init_source($source);

    return $self->to->init_target('') unless $self->toplevels; 

    my $result = $self->walk_node($source, ($self->toplevels)[0]);

    Froody::Error->throw('froody.xml', "walk_node did not return a response")
      unless defined($result);

    # hey, at this point, we have multiple top-level elements!
    return $result; # $result->{ $toplevel[0] };  # Terse specific. move to XMLToTerse
}

=item $self->walk_node($spec, $source, $xpath_key, [ $parent_target ])

Walks the data structure this object holds with the specification, starting at
the part of the spec indicated by $xpath_key. 

C<$parent_target> is used for accumulation of results at the current level.

=cut

sub walk_node {
    my ($self, $source, $xpath_key, $parent_target) = @_;
    $logger->debug("Walking path '$xpath_key' into source '@{[ $source || '' ]}'");
    my $target = $self->to->init_target($xpath_key, $parent_target)
      or Froody::Error->throw('froody.xml', "init_target failed to create a target");

    # get the part of the spec for where we are now looking at
    my $global_spec = $self->spec || {};
    my $spec = $global_spec->{ $xpath_key };

    $self->from->validate_source($source, $xpath_key);

    # get text node (simplest case)
    if (!$spec or $spec->{text}) {
      $logger->debug("getting text node");
      my $value = $self->from->read_text($source, $xpath_key);
      if (defined($value)) {
        $value = "$value";
        $logger->debug("  got '$value'");
        $target = $self->to->write_text($target, $xpath_key, $value);
        Froody::Error->throw('froody.xml', "write_text did not return a target")
          unless defined($target);
      }
      # if the spec is empty, assume a single text node.
      return $target unless $spec;
    }

    # the attributes are easy.  We just pass them each on.
    # TODO: Work out if we need to encode these
    
    # HANDLE all simple values.
    for my $attr (reverse @{ $spec->{attr} }) {
      $logger->debug("Getting attribute '$attr'");
      my $value = $self->from->read_attribute($source, $xpath_key, $attr);
      next unless defined($value);
      $value = "$value";
      $logger->debug("  got $value");
      $target = $self->to->write_attribute($target, $xpath_key, $attr, $value)
        or Froody::Error->throw('froody.xml',"write_attribute did not return a target");
    }

    for my $element (@{ $spec->{elts} }) {
      $logger->debug("getting element $element");
      my $local_xpath = $xpath_key ? "$xpath_key/$element" : $element;
      my @local_source = $self->from->child_sources($source, $xpath_key, $element )
        # if there's no source, we don't make a target - no empty hashes,
        # xml nodes, etc, etc.
        or next;
        
      #warn "Here in elts for $local_xpath";
      if (@local_source > 1 and !$global_spec->{$local_xpath}{multi}) {
         Froody::Error->throw('froody.xml', 
         "got multiple entries for path '$local_xpath', but the spec suggests there should be only one");
      }
      for my $this_source (@local_source) {
        Froody::Error->throw('froody.xml', "source for path '$local_xpath' is undefined")
          unless defined($this_source);
        $logger->debug("local source '$this_source'");
        my $local_target = $self->walk_node( $this_source, $local_xpath, $target );
        $target = $self->to->add_child_to_target( $target, $xpath_key, 
                                                 $element, $local_target )
          or Froody::Error->throw('froody.xml', "add_child_to_target did not return a target");
      }
    }
    $logger->debug("done walking path $xpath_key");
    return $target;
}

=item from (Froody::Walker::Driver)

Sets the source driver.

=cut

sub from {
  my $self = shift;
  
  if (@_) {
    $self->{from} = shift;
    $self->{from}{walker} = $self;
    weaken( $self->{from}{walker} );
    return $self
  }
  return $self->{from};
}

=item to (Froody::Walker::Driver)

Sets the target driver.

=cut

sub to {
  my $self = shift;
  
  if (@_) {
    $self->{to} = shift;
    $self->{to}{walker} = $self;
    weaken( $self->{to}{walker} );
    return $self;
  }
  return $self->{to};
}

=back

=head2 Utility methods

Small methods that get called a lot from subclasses.

=over

=item spec_for_xpath( path )

Returns the local method spec for the given xpath. Returns the
default method spec (text-only node) if there is no spac for that
path.

=cut

sub spec_for_xpath {
  my ($self, $xpath) = @_;
  my $spec = $self->spec->{$xpath} if $self->spec && $xpath;
  return $spec;
}

=item toplevels()

return a list of the top-level node names in the response XML.

=cut

sub toplevels {
  my $self = shift;
  
  # look for the toplevel in the spec.  If we've got more than one, panic!
  my @toplevel = grep m{^[^/]+$}, keys %{ $self->spec };

  if (@toplevel > 1) {
    warn Dumper($self->spec); use Data::Dumper;
    Froody::Error->throw("froody.xml", 
                         "invalid Response spec (multiple toplevel nodes!)")
  }
  
  $self->{spec}{''} = {
    elts => \@toplevel,
    attr => [],
    text => 0,
  };
  
  return @toplevel;
}

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Response::Terse>

=cut

1;
