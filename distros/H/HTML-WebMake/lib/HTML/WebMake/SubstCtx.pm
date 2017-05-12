#

package HTML::WebMake::SubstCtx;

###########################################################################


use Carp;
use strict;

use HTML::WebMake::Main;

use vars	qw{
  	@ISA 
};




###########################################################################

sub new ($$$$$) {
  my $class = shift;
  $class = ref($class) || $class;
  my ($main, $filename, $outname, $dotdots, $fmt, $useurls) = @_;

  my $self = {
    'main'		=> $main,
    'level'		=> 0,
    'inf_loop'		=> 0,
    'filename'		=> $filename,
    'outname'		=> $outname,
    'dotdots'		=> $dotdots,
    'useurls'		=> $useurls,
    'format'		=> $fmt,
  };
  bless ($self, $class);

  $self;
}

# -------------------------------------------------------------------------

1;
