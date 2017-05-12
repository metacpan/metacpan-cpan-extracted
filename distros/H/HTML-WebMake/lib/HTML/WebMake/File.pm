#

package HTML::WebMake::File;


use Carp;
use strict;
use HTML::WebMake::Content;
use HTML::WebMake::Out;
use HTML::WebMake::Contents;
use HTML::WebMake::Media;

use vars	qw{
  	@ISA
};




###########################################################################

sub new ($$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $filename) = @_;

  if (!defined $filename) {
    carp "no filename defined";
  }

  my $self = {
    'main'		=> $main,
    'filename'		=> $filename,
    'deps'		=> [ $filename ],
  };

  bless ($self, $class);
  $self;
}

# -------------------------------------------------------------------------

sub get_deps {
  my ($self) = @_;

  $self->{deps};
}

sub add_dep {
  my ($self,$file) = @_;

  push (@{$self->{deps}}, $file);
}

###########################################################################

1;
