package GraphViz::Graph::Node;

use warnings;
use strict;
use 5.10.0; # state
use Carp;


#_{ Version
our $VERSION = $GraphViz::Graph::Version;
#_}
#_{ Methods
#_{ POD

=encoding utf8

=head1 METHODS

=cut

#_}
sub new { #_{
 #_{ POD
=head2 new
=cut
 #_}
  my $class = shift;
  my $opts  = shift;
  my $self = {};


# croak 'Options expected'       unless defined $opts;
# croak 'Options must be a HASH' unless ref $opts eq 'HASH';

# croak "Unrecognized opts " . join "/", keys %$opts if keys %$opts;

  state $id = 0;
  $self->{id} = sprintf('nd_%04d',  ++$id);
  $self->{shape} = 'none';

  bless $self, $class;

  $self->shape('none');
  return $self;

} #_}
sub label { #_{
 #_{ POD
=head2 label
=cut
 #_}

  my $self = shift;
  my $opts = shift;

  $self->{label} = GraphViz::Graph::Label->new($opts);

} #_}
sub shape { #_{
 #_{ POD
=head2 shape

Sets the shape of node. Possible values can be, among others:

=over 4

=item * C<'none'>

=item * C<'point'>

=item * C<'rect'>

=item * C<'square'>

=item * C<'star'>

=item * etc …

=back

=cut
 #_}

  my $self       = shift;
  my $shape_text = shift; # none, point, rect, square, star etc // TODO: record

  $self->{shape_text} = $shape_text;

  return $self;

} #_}
sub dot_text { #_{
 #_{ POD
=head2 dot_text

Returns the dot-text that represents the node on which it was called.

Called by L<GraphViz::Graph>'s C<write_dot()>.

=cut
 #_}

  my $self = shift;

  my $ret = "  $self->{id} [\n";
  $ret .= "    shape=" . $self->{shape_text} . "\n";

  if (exists $self->{label}) {
      $ret .= "    " . $self->{label}->dot_text();
  }
  $ret .= "  ];\n\n";
  return $ret;

} #_}
sub port { #_{
 #_{ POD
=head2 port

C<< $node->port() >> is needed to connect from or to ports with edges.

    my $nd_one   = $graph->node();
    my $nd_two   = $graph->node();

    $nd_two->label({html=>"<table>
      <tr><td port='port_f'>f</td><td>g</td></tr>
    </table>"});

    $graph->edge($nd_one, $nd_two->port('port_f')):

=cut

 #_}
 
 my $self    = shift;
 my $port_id = shift;

 return $self->{id} . ":$port_id";

} #_}

#_}

'tq84';
