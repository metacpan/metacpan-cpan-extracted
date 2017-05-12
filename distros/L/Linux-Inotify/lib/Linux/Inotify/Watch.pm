package Linux::Inotify::Watch;

use strict;
use warnings;
use Carp;

push our @CARP_NOT, 'Linux::Inotify';

sub new($$$$) {
   my $class = shift;
   my $self = {
      notifier => shift,
      name     => shift,
      mask     => shift,
      valid    => 1
   };
   use Linux::Inotify;
   $self->{wd} = Linux::Inotify::syscall_add_watch($self->{notifier}->{fd},
      $self->{name}, $self->{mask});
   croak "Linux::Inotify::Watch::new() failed: $!" if $self->{wd} == -1;
   return bless $self, $class;
}

sub clone($$) {
   my $source = shift;
   my $target = {
      notifier => $source->{notifier},
      name     => shift,
      mask     => $source->{mask},
      valid    => 1
   };
   use Linux::Inotify;
   $target->{wd} = Linux::Inotify::syscall_add_watch($target->{notifier}->{fd},
      $target->{name}, $target->{mask});
   croak "Linux::Inotify::Watch::new() failed: $!" if $target->{wd} == -1;
   return bless $target, ref($source);
}

sub invalidate($) {
   my $self = shift;
   $self->{valid} = 0;
}

sub remove($) {
   my $self = shift;
   if ($self->{valid}) {
      $self->invalidate;
      use Linux::Inotify;
      my $ret = Linux::Inotify::syscall_rm_watch($self->{notifier}->{fd},
	 $self->{wd});
      croak "Linux::Inotify::Watch::remove(wd = $self->{wd}) failed: $!" if
	 $ret == -1;
   }
}

1;

