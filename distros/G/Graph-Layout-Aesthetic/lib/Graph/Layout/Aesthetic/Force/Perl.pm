package Graph::Layout::Aesthetic::Force::Perl;
use 5.006001;
use strict;
use warnings;

our $VERSION = '0.01';
use base qw(Graph::Layout::Aesthetic::Force);

1;
__END__

=head1 NAME

Graph::Layout::Aesthetic::Force::Perl - Write aesthetic forces using perl

=head1 SYNOPSIS

  package Something;
  use base qw(Graph::Layout::Aesthetic::Force::Perl);

  # If you need a private constructor, don't forget to chain it
  # sub new {
  #     my $force = shift->SUPER::new;
  #     # do something, maybe with $force->_private_data
  #     return $force;
  # }

  sub setup {
      my ($force, $aglo) = @_;
      # Do any needed preparations
      return $closure;
  }

  sub gradient {
      my ($force, $aglo, $gradient, $closure) = @_;
      # Calculate forces into $gradient
  }

  sub cleanup {
      my ($force, $aglo, $closure) = @_;
      # Maybe need some cleanup on $closure
  }

  # If you need a DESTROY, don't forget to chain it
  # sub DESTROY {
  #     my $force = shift;
  #     # do something, maybe with $force->_private_data
  #     $force->SUPER::DESTROY;
  # }

  # Override name if you don't like the default
  # sub name {
  #    return "Something";
  # }

  # Typically you then provide one instance of your force and register it
  __PACKAGE__->new->register;

=head1 DESCRIPTION

Graph::Layout::Aesthetic::Force::Perl is a base class for writing perl based
L<aesthetic forces|Graph::Layout::Aesthetic::Force>. This can be as simple as
just providing a gradient method.

=head1 EXAMPLE

This code duplicates what
L<Graph::Layout::Aesthetic::Force::MinEdgeLength|Graph::Layout::Aesthetic::Force::MinEdgeLength>
does (minimize edge lengths), but in pure perl.

    package Graph::Layout::Aesthetic::Force::Mel;
    use warnings;
    use strict;

    use base qw(Graph::Layout::Aesthetic::Force::Perl);

    sub gradient {
        my (undef, $state, $gradient) = @_;
        my @delta;

        my @coordinates = $state->all_coordinates;
        my $max_d = $state->nr_dimensions()-1;

        for ($state->topology->edges) {
            my $from = $coordinates[$_->[0]];
            my $to   = $coordinates[$_->[1]];
            my $dist = 0;
            $dist += ($delta[$_] = $to->[$_]-$from->[$_])**2 for 0..$max_d;
            $dist = sqrt($dist);
            next if $dist < 1e-8;

            $from = $gradient->[$_->[0]];
            $to   = $gradient->[$_->[1]];
            for(0..$max_d) {
                $from->[$_] += $delta[$_] *= $dist;
                $to->[$_]   -= $delta[$_];
            }
        }
    }

    __PACKAGE__->new->register;

=head1 METHODS

Graph::Layout::Aesthetic::Force::Perl inherits from
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force>, so all
methods of that class are available. As an extension writer you will probably
be most interested in L<register|Graph::Layout::Aesthetic::Force/register> and
L<_private_data|Graph::Layout::Aesthetic::Force/_private_data>.

The methods explained here aren't normally directly called by the user or
even the programmer of the force, but implicitly by using the
L<Graph::Layout::Aesthetic|Graph::Layout::Aesthetic> package. They are
documented here so the implementer of a force class (who can override the
defaults) can see when and with which arguments his methods get called

=over

=item X<new>$force = Graph::Layout::Aesthetic::Force::Perl->new

This is the default constructor provided by
Graph::Layout::Aesthetic::Force::Perl. It returns a perl object that's really
a wrapper around a C-structure (which is what a
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force> object must
be). So if you want to write your own constructor, you'll still need to call
this internally, and then you can use
L<_private_data|Graph::Layout::Aesthetic::Force/_private_data> to associate
extra state with the force.

=item X<setup>$closure = $force->setup($state)

This method gets called when a L<force|Graph::Layout::Aesthetic::Force> gets
associated with L<a layout state|Graph::Layout::Aesthetic> (it corresponds to
L<aesth_setup in Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force/aesth_setup>).
It is supposed to return some scalar that will then later be passed again to
any corresponding L<gradient|"gradient"> and L<cleanup|"cleanup"> method calls.
So the $closure value can be used to associate state with a force/state pair.

The default provided by Graph::Layout::Aesthetic::Force::Perl does nothing
and simply returns undef.

=item X<gradient>$force->gradient($state, $gradient, $closure)

This method gets called whenever a preferred gradient for a force is needed
while laying out a graph (it corresponds to
L<aesth_gradient in Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force/aesth_gradient>). It gets passed a starting $gradient, which is an array
reference with an element for each vertex. Each element in turn is an array
reference to coordinate forces. All of these have already been initialized to
zero at the start of the method call. The method is now responsible for filling
in these values. The direction of the force should be a direction in which an
infinitesimal step will improve the target aesthetic, and the size should
correspond with how fast it improves in that direction.

There is no default gradient method, you must provide one yourself in your
subclass.

=item X<cleanup>$force->cleanup($state, $closure)

This method gets called when $force gets disassociated from $state (it
corresponds to
L<aesth_cleanup in Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force/aesth_cleanup>).
A typical use would be to clean up things created during L<setup|"setup"> and
remembered in $closure.

Since perl has its own garbage collection and DESTROY can already associate 
a callback with data going away, usually you don't need to do anything 
here. Which is exactly what the default cleanup method does: nothing.

=item X<DESTROY>$force->DESTROY

Actually Graph::Layout::Aesthetic::Force::Perl (currently) has no DESTROY
method, but inherits the one from
L<Graph::Layout::Aesthetic::Force|Graph::Layout::Aesthetic::Force>. That one
however must be called if in the end the $force object was constructed with
the local L<new|"new"> method. So if you override DESTROY in your subclass,
you need to chain to that one (simply using $force->SUPER::DESTROY should be
good enough).

=back

=head1 EXPORT

None.

=head1 SEE ALSO

L<Graph::Layout::Aesthetic>,
L<Graph::Layout::Aesthetic::Force>

=head1 AUTHOR

Ton Hospel, E<lt>Graph-Layout-Aesthetic@ton.iguana.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ton Hospel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
