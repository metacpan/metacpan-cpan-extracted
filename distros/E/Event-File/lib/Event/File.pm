#we need Event.pm
use Event;
use IO::File;
package Event::File;

=head1 NAME

Event::File is a wrapper module to write perl modules that deal with Files thru Event.
It tries to mimics Event.pm model.

=cut

use strict;
use vars qw($VERSION);
$VERSION = '0.1.1';

#we clone this from Event
sub _load_watcher {
  my $sub = shift;
  eval { require "Event/File/$sub.pm" };
  die if $@;

  croak ("Event/File/$sub.pm did not define Event::File::$sub::new")  
    unless defined &$sub;
  1;
}

#we clone AUTOLOAD style from Event.pm
sub AUTOLOAD {
  my $sub = ($Event::File::AUTOLOAD =~ /(\w+)$/)[0];    
  _load_watcher($sub) or croak $@ . ', Undefined subroutine &' . $sub;
  
  goto &$sub;
}


#The register routine
#this will turn Event::File::foo into  Event::File->foo() == Event::File::foo->new();
sub register {
  no strict 'refs';
  my $package = caller;
  
  my $name = $package;
  $name =~ s/Event::File:://;

  my $sub = \&{"$package\::new"};

  die "can't find $package\::new"
    if !$sub;
  *{"Event::File::".$name} = sub {
    shift;
    $sub->("Event::File::".$name, @_);
  };

  #no hooks
  #&Event::add_hooks if @_;
}


1;
__END__

=head1 Supported Events

Right now only Event::File->tail is supported.
For more information on it please refere to the Event::File::tail man page.

=head1 External Modules

This module makes use of 

=over

=item *

Event >= 0.80

=item *

IO::File

=back

=head1 SEE ALSO

Event(3), File::File::tail(3), cmc

=head1 AUTHOR

Raul Dias, <raul@dias.com.br>

=cut
