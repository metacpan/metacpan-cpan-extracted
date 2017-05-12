package Graph::PetriNet;

use 5.008000;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);

our $VERSION = '0.03';

use Class::Trait;

=pod

=head1 NAME

Graph::PetriNet - Perl extension for Petri Nets

=head1 SYNOPSIS

  # build your places objects (see DESCRIPTION)
  my %places = ('place1' => ....,
                'place2' => ....);
  # build your transition objects (see DESCRIPTION)
  my %transitions = ('trans1' => [ ... ],
                     'trans2' => [ ... ]);

  use Graph::PetriNet;
  my $pn = new Graph::PetriNet (places      => \%places,
                                transitions => \%transitions);

  # change a token setting at one place
  $pn->things ('place1')->tokens (42);

  # walk through the whole life time
  while ($pn->ignitables) {
     $pn->ignite;
     warn "tokens: ". $pn->things ('place1')->tokens;
  }

  # only ignite one particular transitions
  $pn->ignite ('trans1', 'trans2'); 

  my @places = $pn->places;
  my @trans  = $pn->transitions;


=head1 DESCRIPTION

This package implements a bipartite graph to represent and interpret a I<Petri net>
(L<http://en.wikipedia.org/wiki/Petri_net>). Accordingly, there are two kinds of nodes:

=over

=item *

L<Data nodes> carry the information to be processed and/or propagated. This package assumes that each
such node has a unique label (just a string). The label is used to refer to the node.

=item *

L<Transition nodes> carry the information how and when processing has to occur. Also transitions
have unique labels and also they are objects. Every transition node has a set of incoming data nodes
from which it can consume data. And it has a set of outgoing data nodes which will be fill with new
data after a transition.

=back

=head2 Processing Model

At any time the application can check which transitions are I<ignitable>. It can ask the petri net
to fire some (or all of them). It is the responsibility of the transition nodes to do what they are
supposed to do.

=head2 Node Semantics

As a default behavior (not overly useful, but here it is), transition nodes consume I<tokens> from
the data nodes (actually one per node and transition) and then pass one token to the downstream data
node.

To modify this behaviour, you simply implement your own data and transition nodes. To make this
reasonably easy their behaviour is defined as I<trait>: You can either take these traits as they
are, or import the trait with modifications, or develop a subtrait which you import into your
objects, or write the objects from scratch. For an example look at C<t/02_makefileish.t> which
implements a processing behaviour you would expect from I<make>.


B<NOTES>:

=over

=item *

The roles (traits) are currently written with L<Class::Trait>. Maybe in another time I reimplement
this with L<Moose> roles. Maybe.

=item *

This graph is not implemented on top of L<Graph>, so using it as superclass. There is already a
package L<Graph::Bipartite> (not recommended) which blocks the namespace, but there are no deep
reasons why this should not be possible.

=back


=head1 INTERFACE

=head2 Constructor

The constructor expects a hash with the following fields:

=over

=item C<transitions> (mandatory, hash reference)

A hash reference, whereby the keys are labels for the transitions and the values are the transitions
themselves. They can be anything but must be able to do the trait L<Graph::PetriNet::TransitAble>.

=item C<places> (mandatory, hash reference)

A hash reference, whereby the keys are labels for the places and the values are the places
themselves. They can be anything but must be able to do the trait L<Graph::PetriNet::PlaceAble>.

=item C<initialize> (optional, integer)

If non-zero, then the constructor will invoke the C<token> method on all places, setting them to
C<0>.

=back

Example:

  my $pn = new Graph::PetriNet (# here I want something special
                                places => { 'p1' => new My::Place (...),
                                            'p2' => new My::Place (...),
                                           },
                                # too lazy, happy with the default behavior
                                transitions => {
                                            't1' => [ bless ({}, 'Whatever'), [ 'p1' ], [ 'p2' ] ],
                                            't2' => [ bless ({}, 'Whatever'), [ 'p2' ], [ 'p2' ] ]
                                });

=cut

sub new {
    my $class = shift;
    my $self = bless { places => {}, transitions => {} }, $class;
    my %opts  = @_;
    foreach my $p (keys %{ $opts{places} }) {                                         # check for all places
	my $pl = $opts{places}->{$p};                                                 # what the place object is
	Class::Trait->apply($pl, 'Graph::PetriNet::PlaceAble')                        # that it has our trait
	    unless $pl->can ('tokens');
	$self->{places}->{$p} = $pl;                                                  # and register it with us
    }

    foreach my $t (keys %{$opts{transitions} }) {                                     # for all the transition infor
	my ($tr, $in, $out) = @{ $opts{transitions}->{$t} };                          # collect what we get
	Class::Trait->apply($tr, 'Graph::PetriNet::TransitionAble')                   # assert the trait
	    unless $tr->can ('ignitable');
	$tr->inputs ($in);                                                            # tug in input and
	$tr->outputs ($out);                                                          # output
	$self->{transitions}->{$t} = $tr;                                             # register
    }

    $self->reset if $opts{initialize};
    return $self;
}

=pod

=head2 Methods

=over

=item B<places>

I<@labels> = I<$pn>->places

Retrieve the labels of all places in the network.

=cut

sub places {
    my $self = shift;
    return keys %{ $self->{places} };
}

=pod

I<@labels> = I<$pn>->transitions

Retrieve the labels of all transitions in the network.

=cut

sub transitions {
    my $self = shift;
    return keys %{ $self->{transitions} };
}

=pod

=item B<things>

I<@things> = I<$pn>->things (I<$label>, ...)

Given some labels, this method returns the things with this label, or C<undef> if there is none.

=cut

sub things {
    my $self = shift;
    return map {    $self->{places}     ->{$_}
		 || $self->{transitions}->{$_}
		 || undef }
           @_;
}

=pod

=item B<reset>

I<$pn>->reset

Resets all places to have zero tokens.

=cut

sub reset {
    my $self = shift;
    map { $_->tokens (0) } values %{ $self->{places} };
}

=pod

=item B<ignitables>

I<@is> = I<$pn>->ignitables

This method returns a list of transitions which can be fired. It returns the labels, not the object.

=cut

sub ignitables {
    my $self = shift;
    return grep { $self->{transitions}->{$_}->ignitable } keys %{ $self->{transitions} };
}

=pod

=item B<ignite>

I<$pn>->ignite
I<$pn>->ignite (I<label>, ...)

This methods ignites those transitions which are handed in (as labels). If none is handed in, then
all ignitables with be ignited.

=cut

sub ignite {
    my $self = shift;
    my @is = @_ ? @_ : $self->ignitables;
    foreach my $tr (map { $self->{transitions}->{$_} } @is) {
	$tr->ignite;
    }
}

=pod

=back

=head1 SEE ALSO

L<http://en.wikipedia.org/wiki/Petri_net>, L<Graph::PetriNet::PlaceAble>, L<Graph::PetriNet::TransitionAble>

=head1 AUTHOR

Robert Barta, E<lt>drrho@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Robert Barta

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself, either Perl version 5.10.0 or, at your option, any later version of Perl 5 you may have
available.


=cut

"against all gods";

__END__

 =cut

sub add {
    my $self = shift;
    while (@_) {
	my ($i, $t, $o) = (shift, shift, shift);
# can roles Graph::PetriNet::Place	    die "xxx" grep { } @$i;
# can roles Graph::PetriNet::Place	    die "xxx" grep { } @$o;
# can roles Graph::PetriNet::Transition	    die "xxx" grep { } @$t;
	die "xxx" if $self->{transitions}->{ $t };
	my $tr = $self->{things}->{$t};
	$tr->in_places  (map { $self->{things}->{$_} } @$i);
	$tr->out_places (map { $self->{things}->{$_} } @$o);     # todo: use Graph later
	$self->{transitions}->{ $t } = $tr;
    }
# todo: add/replace
}

  =pod

