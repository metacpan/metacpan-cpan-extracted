#!perl

package File::Lock::Multi::FlockFiles;

use strict;
use warnings (FATAL => 'all');
use File::Lock::Multi::Base::Iterative;
use base q(File::Lock::Multi::Base::Iterative);
use Fcntl qw(:flock);
use Carp qw(croak);

__PACKAGE__->mk_accessors(qw(format clean _id _fh _mine));

return 1;

sub __Validators {
  my $class = shift;

  return(
    $class->SUPER::__Validators(
      format    => { default => "%s.%i" },
      clean     => { regex => qr/^\d+$/, default => 1 },
      @_
    )
  );
}

sub locked {
  my $self = shift;
  return $self->_fh ? 1 : 0;
}

sub lock_non_block_for {
  my($self, $id) = @_;
  croak "lock_non_block_for called while already locked" if $self->locked;
  if(my($fh, $mine) = $self->obtain_lock_for($id)) {
    $self->_fh($fh);
    $self->_id($id);
    $self->_mine($mine);
    return $id;
  } else {
    return;
  }
}

sub obtain_lock_for {
  my($self, $id) = @_;
  my $path = $self->obtain_path($id);
  if(my($fh, $mine) = $self->lock_path($path)) {
    if(wantarray) {
      return($fh, $mine);
    } else {
      return $fh;
    }
  } else {
    return;
  }
}

sub obtain_path {
  my($self, $id) = @_;
  return $self->format_path($id);
}

sub format_path {
  my($self, $id) = @_;
  return sprintf($self->format, $self->file, $id);
}

sub path {
  my $self = shift;
  croak "can not obtain a path without an ID" unless defined $self->_id;
  return $self->format_path($self->_id);
}

sub _release {
  my $self = shift;
  $self->_clean if $self->clean;
  $self->_fh->close;
  $self->_fh(undef);
  $self->_id(undef);
  $self->_mine(undef);
  return 1;
}

sub _clean {
  my $self = shift;
  $self->__clean($self->path, $self->_mine);
}

sub __clean {
  my($self, $path, $mine) = @_;
  if($mine || $self->clean > 1) {
    unlink($path);
  }
}

sub lock_path {
  my($self, $path) = @_;
  LOCK_NB or die "LOCK_NB is not supported on this operating system";
  my($fh, $mine) = $self->filehandle_path($path);
  if(flock($fh, LOCK_EX | LOCK_NB)) {
    if(wantarray) {
      return($fh, $mine);
    } else {
      return $fh;
    }
  } else {
    $self->__clean($path, $mine) if $mine;
    return;
  }
}

sub filehandle_path {
  my($self, $path) = @_;
  my $mine = 0;

  unless(-e $path) {
    open(my $dummy, '>>', $path) or croak "create $path: $!";
    $mine = 1;
  }

  if(open(my $fh, '<', $path)) {
    if(wantarray) {
      return($fh, $mine);
    } else {
      return $fh;
    }
  } else {
    croak "open('<', '$path'): $!";
  }
}

sub DESTROY {
  my $self = shift;
  $self->release if $self->locked;
  $self->SUPER::DESTROY if $self->SUPER::can('DESTROY');
}

__END__

=pod

=head1 NAME

File::Lock::Multi::FlockFiles - flock() multiple files to emulate taking
out multiple locks on a single file.

=head1 DESCRIPTION

This module uses perl's C<flock()> call on multiple files to emulate
taking out multiple locks on a single file. For instance, if you ask
to lock the file "foo.txt" a maximum of 5 times,
C<File::Lock::Multi::FlockFiles> will pretend to do this by acquiring
locks on the files "foo.txt.1", "foo.txt.2", "foo.txt.3", etc.

By default, these files will be deleted when the locks are released
to keep it from making too much of a mess in your filesystem.

=head1 OPTIONS

In addition to the standard L<File::Lock::Multi> options, the following
additional options are available when calling C<new()>:

=over

=item clean

Clean up (unlink) our lockfiles when we're done with them.

If false, don't clean.

If set to "1", clean up lockfiles that we created.

If set to a value greater than "1", clean up lockfiles whether or
not we created them.

Default: 1

=item format

A L<sprintf()|perlfunc/sprintf> format string used to come up with
the individual lockfile names. C<sprintf()> will be passed the file's path
and the lock number as the first and second parameters. (Default: "%s.%i").

=back

=head1 LICENSE

Copyright 2009 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

L<File::Lock::Multi>, L<perlfunc/flock>

=cut


