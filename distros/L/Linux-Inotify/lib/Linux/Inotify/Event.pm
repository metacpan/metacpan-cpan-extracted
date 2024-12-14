package Linux::Inotify::Event;

use strict;
use warnings;
use Linux::Inotify;

# ABSTRACT: Event class for Linux::Inotify
our $VERSION = '0.06'; # VERSION

sub new {
   my $class = shift;
   my $notifier = shift;
   my $raw_event = shift;
   my $self = { notifier => $notifier };
   (my $wd, $self->{mask}, $self->{cookie}, $self->{len}) =
      unpack 'iIII', $raw_event;
   $self->{watch} = $notifier->find($wd);
   $self->{name} = unpack 'Z*', substr($raw_event, 16, $self->{len});
   if ($self->{mask} & Linux::Inotify::DELETE_SELF) {
      $self->{watch}->invalidate();
   }
   return bless $self, $class;
}

sub fullname {
   my $self = shift;
   return $self->{watch}->{name} . '/' . $self->{name};
}

sub add_watch {
   my $self = shift;
   return $self->{watch}->clone($self->fullname());
}

my %reverse = (
   0x00000001 => 'access',
   0x00000002 => 'modify',
   0x00000004 => 'attrib',
   0x00000008 => 'close_write',
   0x00000010 => 'close_nowrite',
   0x00000020 => 'open',
   0x00000040 => 'moved_from',
   0x00000080 => 'moved_to',
   0x00000100 => 'create',
   0x00000200 => 'delete',
   0x00000400 => 'delete_self',
   0x00002000 => 'unmount',
   0x00004000 => 'q_overflow',
   0x00008000 => 'ignored',
);
my %reverse_copy = %reverse;
while(my ($key, $value) = each %reverse_copy) {
   $reverse{Linux::Inotify::ISDIR | $key} = "isdir | $value";
}

sub print {
   my $self = shift;
   printf "fd: %d, wd: %d, %21s, cookie: 0x%08x, len: %3d, name: '%s'\n",
      $self->{notifier}->{fd}, $self->{watch}->{wd}, $reverse{$self->{mask}},
      $self->{cookie}, $self->{len}, $self->fullname();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Linux::Inotify::Event - Event class for Linux::Inotify

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
