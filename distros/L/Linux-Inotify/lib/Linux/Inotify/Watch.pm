package Linux::Inotify::Watch;

use strict;
use warnings;
use Carp;

# ABSTRACT: Watch class for Linux::Inotify
our $VERSION = '0.06'; # VERSION

our @CARP_NOT = ('Linux::Inotify');

sub new {
   my $class = shift;
   my $self = {
      notifier => shift,
      name     => shift,
      mask     => shift,
      valid    => 1
   };
   require Linux::Inotify;
   $self->{wd} = Linux::Inotify::syscall_add_watch($self->{notifier}->{fd},
      $self->{name}, $self->{mask});
   croak "Linux::Inotify::Watch::new() failed: $!" if $self->{wd} == -1;
   return bless $self, $class;
}

sub clone {
   my $source = shift;
   my $target = {
      notifier => $source->{notifier},
      name     => shift,
      mask     => $source->{mask},
      valid    => 1
   };
   require Linux::Inotify;
   $target->{wd} = Linux::Inotify::syscall_add_watch($target->{notifier}->{fd},
      $target->{name}, $target->{mask});
   croak "Linux::Inotify::Watch::new() failed: $!" if $target->{wd} == -1;
   return bless $target, ref($source);
}

sub invalidate {
   my $self = shift;
   $self->{valid} = 0;
}

sub remove {
   my $self = shift;
   if ($self->{valid}) {
      $self->invalidate;
      require Linux::Inotify;
      my $ret = Linux::Inotify::syscall_rm_watch($self->{notifier}->{fd},
         $self->{wd});
      croak "Linux::Inotify::Watch::remove(wd = $self->{wd}) failed: $!" if
         $ret == -1;
   }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Inotify::Watch - Watch class for Linux::Inotify

=head1 VERSION

version 0.06

=head1 AUTHOR

Original author: Torsten Werner

Current maintainer: Graham Ollis E<lt>plicease@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018-2022 by Torsten Werner <twerner@debian.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
