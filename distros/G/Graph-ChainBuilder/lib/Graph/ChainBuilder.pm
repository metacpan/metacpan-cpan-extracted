package Graph::ChainBuilder;
$VERSION = v0.0.2;

use warnings;
use strict;
use Carp;

=head1 NAME

Graph::ChainBuilder - build directed 2-regular cyclic graphs

=head1 SYNOPSIS

This object collects data into a set of ordered chains, allowing you to
organize e.g. edges AB,CD,AD,CB into the circular sequence AB,BC,CD,DA
while keeping track of the directionality of the input data.

  my $graph = Graph::ChainBuilder->new;

  while(whatever) {
    ...
    $graph->add($p0, $p1, $data);
  }

An edge is defined by the strings $p0 and $p1.  The $data is whatever
you want to associate with an edge.

  foreach my $loop ($graph->loops) {
    foreach my $edge (@$loop) {
      ...
      $edge->data;
    }
  }

=head1 Limitations

This code will identify multiple independent loops in an arbitrary set
of unordered edges, but assumes that all loops are closed and that no
stray edges exist.  The result is undefined if your input contains
duplicate or dangling edges.

=cut

use Class::Accessor::Classy;
with 'new';
lo 'loops';
no  Class::Accessor::Classy;

=head2 new

  my $graph = Graph::ChainBuilder->new;

=cut

sub new {
  my $self = shift->SUPER::new();
  $self->{ep}    = {};
  $self->{loops} = [];
  return($self);
} # end subroutine new definition
########################################################################

=head2 add

Adds an edge to the graph.  The nodes $p0 and $p1 will be connected (if
possible) to the existing loops.

  $graph->add($p0, $p1, $data);

Attempting to add an edge with a point which has already been connected
will throw an error.

=cut

sub add {
  my $self = shift;
  my ($p0, $p1, $data) = @_;

  my $edge = Graph::ChainBuilder::edge->new($p0, $p1, 0, $data);

  my $ep = $self->{ep};
  if(my $where = delete($ep->{$p0})) {
    my ($chain, $end) = @$where;
    # warn "insert $p0|$p1 on $chain $end";
    $edge->reverse unless($end);
    splice(@$chain, $end ? scalar(@$chain) : 0, 0, $edge);
    if(my $and = delete($ep->{$p1})) {
      # warn "unravelling needed at $p1";
      # {local $ep->{$p1} = $and; warn join("\n", $self->stringify, '');}
      if($and->[0] eq $chain) { # closed!
        push(@{$self->{loops}}, $chain);
      }
      else {
        $self->_unravel([$chain, $end], $and);
      }
    }
    else {
      $ep->{$p1} = [$chain, $end];
    }
  }
  elsif($where = delete($ep->{$p1})) {
    my ($chain, $end) = @$where;
    # warn "insert $p1|$p0 on $chain $end";
    $edge->reverse if($end);
    splice(@$chain, $end ? scalar(@$chain) : 0, 0, $edge);
    $ep->{$p0} = [$chain, $end];
  }
  else {
    # start a new chain
    my $chain = [$edge];
    $ep->{$p0} = [$chain, 0];
    $ep->{$p1} = [$chain, 1];
  }
} # end subroutine add definition
########################################################################

=begin nothing

=head2 open_ends

=head2 stringify

=end nothing

=cut

sub open_ends {
  my $self = shift;

  my %once = map({$_ => $_} map {$_->[0]} values %{$self->{ep}});
  return(values %once);
}
sub stringify {
  my $self = shift;

  return map({join(" ", map({join("|", $_->p0, $_->p1)} @$_))} 
    $self->open_ends);
}

# recursively check/close connected subchains
sub _unravel {
  my $self = shift;
  my ($where, $and) = @_;

  my $ep = $self->{ep};

  my $chain = $where->[0];
  my $end   = $where->[1];

  my $subchain = $and->[0];

  if($end == $and->[1]) { # reverse direction
    @$subchain = reverse(@$subchain);
    $_->reverse for(@$subchain);
  }

  splice(@$chain, $end ? scalar(@$chain) : 0, 0, @$subchain);

  # the opposite end of that chain is now this end of this chain
  my $which_node = 'p' . $end;
  my $last = $subchain->[$end ? $#$subchain : 0]->$which_node;
  $ep->{$last} or die "that's unexpected";
  $ep->{$last} = $where;
} # end subroutine _unravel definition
########################################################################

{
package Graph::ChainBuilder::edge;

=head2 new

  my $e = Graph::ChainBuilder::edge->new($p0, $p1, $rev, $data);

=cut

sub new { my $class = shift; bless([@_], $class); }
sub p0       {shift->[0]};
sub p1       {shift->[1]};
sub reversed {shift->[2]};
sub data     {shift->[3]};

sub reverse { my $e = shift; $e->[2] ^= 1; @$e[0,1] = @$e[1,0]; }
}
########################################################################


=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2009 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
