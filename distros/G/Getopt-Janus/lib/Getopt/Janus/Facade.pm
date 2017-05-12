
require 5;
package Getopt::Janus::Facade;
use strict;
require Getopt::Janus; # for its _require sub

use vars qw(@GUI_classes @CLI_classes);
push @GUI_classes, 'Getopt::Janus::Tk';
push @CLI_classes, 'Getopt::Janus::CLI';

sub new {
  my $class = shift;
  die "$class subclasses " . __PACKAGE__ . "?!?!"
   unless $class eq __PACKAGE__;
  
  my @errors;
  
 Load:
  {
    my $trial_classes;
    $trial_classes = @ARGV ? \@CLI_classes : \@GUI_classes;
  
    foreach my $trial_class (@$trial_classes) {
      return $trial_class->new if Getopt::Janus::_require($trial_class);
      push @errors, $@;
      $errors[-1] =~ s/\n*$/\n/s;
    }
    if(! @ARGV) {
      # We had no args but couldn't load a GUI class.  Just emit
      # a help message and quit.
      @ARGV = '-h';
      redo Load;
    }
  }

  # Otherwise we couldn't manage anything:
  die join '',
    __PACKAGE__, " couldn't load any interface classes:\n",
    @errors, "Aborting";
  ;
}

1;
__END__

