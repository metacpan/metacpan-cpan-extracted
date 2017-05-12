
package Email::Blaster::Config;

use strict;
use warnings 'all';
use base 'Email::Blaster::ConfigNode';
use Carp 'confess';


#==============================================================================
sub new
{
  my ($class, $ref, $root) = @_;
  
  my $s = $class->SUPER::new( $ref );
  
  # Add our "libs" directories to @INC:
  map {
    $_ =~ s/\@ServerRoot@/$root/;
    push @INC, $_;
  } @{ $s->libs->lib };
  
  return $s;
}# end new()


#==============================================================================
sub _init
{
  my ($s) = @_;

  # Make sure we can load all of our handlers:
  local $SIG{__DIE__} = \&Carp::confess;
  map { $s->_load_class( $_ ) } @{ $s->handlers->server_startup->handler };
  map { $s->_load_class( $_ ) } @{ $s->handlers->server_shutdown->handler };
  map { $s->_load_class( $_ ) } @{ $s->handlers->init_transmission->handler };
  map { $s->_load_class( $_ ) } @{ $s->handlers->begin_transmission->handler };
  map { $s->_load_class( $_ ) } @{ $s->handlers->end_transmission->handler };
  map { $s->_load_class( $_ ) } @{ $s->handlers->message_bounced->handler };
}# end _init()


#==============================================================================
sub throttled
{
  my $s = shift;
  
  return wantarray ? @{ $s->{throttled}->throttle } : $s->{throttled}->throttle;
}# end throttled()


#==============================================================================
sub _load_class
{
  my ($s, $class) = @_;
  
  (my $file = "$class.pm") =~ s/::/\//g;
  eval { require $file unless $INC{$file}; 1 } or confess "Cannot load $class: $@";
}# end _load_class()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:

