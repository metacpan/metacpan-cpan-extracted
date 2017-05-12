
# subclass of Thingy for testing

package Games::3D::Thingy::Test;

# (C) by Tels <http://bloodgate.com/>

use strict;

require Exporter;
require Games::3D::Thingy;
use vars qw/@ISA $VERSION $AUTOLOAD/;
@ISA = qw/Exporter Games::3D::Thingy/;

$VERSION = '0.01';

##############################################################################
# methods

sub _init
  {
  # create a new instance of a thingy
  my $self = shift;

  $self->{received} = { };		# counter
  }

sub signal
  {
  # receive signal $sig from input $input, where $input is the sender's ID (not
  # the link(s) relaying the signal). We ignore here the input. Links relay
  # their input to their outputs (maybe, delayed , inverted etc), while other
  # objects receive input, change state (or not) and then maybe output
  # something.
  my ($self,$input,$sig) = @_;

#  my $id = $input; $id = $input->{id} if ref($id);
#  print "# ",$self->name()," received signal $sig from $id\n";

  $self->{received}->{ $sig } ++;		# count it
  $self;
  }

1;

__END__

=pod

=head1 NAME

Games::3D::Thingy::Test - test class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHORS

(c) 2004 Tels <http://bloodgate.com/>

=head1 SEE ALSO

L<Games::3D>, L<Games::Irrlicht>.

=cut

