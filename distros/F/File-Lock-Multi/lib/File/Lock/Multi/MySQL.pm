#!perl

package File::Lock::Multi::MySQL;

use strict;
use warnings (FATAL => 'all');
use File::Lock::Multi::Base::Iterative;
use base q(File::Lock::Multi::Base::Iterative);
use Carp qw(croak);


use DBD::mysql;

__PACKAGE__->mk_accessors(qw(format dbh _id _path));

return 1;

sub __Validators {
  my $class = shift;

  return(
    $class->SUPER::__Validators(
      format    => { default => "%s.%i" },
      dbh       => 1,
      @_
    )
  );
}

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  if(ref($self->dbh) eq 'CODE') {
    $self->dbh($self->dbh->());
  }
  return $self;
}

sub locked {
  my $self = shift;
  return $self->_path ? 1 : 0;
}

sub lock_non_block_for {
  my($self, $id) = @_;
  croak "lock_non_block_for called while already locked" if $self->locked;
  if(my $path = $self->obtain_lock_for($id)) {
    $self->_path($path);
    $self->_id($id);
    return $id;
  } else {
    return;
  }
}

sub obtain_lock_for {
  my($self, $id) = @_;
  return $self->lock_path($self->format_path($id));
}

sub lock_held_for {
  my($self, $id) = @_;
  return $self->is_used_lock($self->format_path($id));
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
  my($result) = ($self->dbh->selectrow_array(
    "SELECT RELEASE_LOCK(?)",
    { RaiseError => 1, PrintError => 0 },
    $self->_path
  ));
  $self->_path(undef);
  $self->_id(undef);
  return 1;
}

sub is_used_lock {
  my($self, $path) = @_;
  my($result) = ($self->dbh->selectrow_array(
    "SELECT IS_USED_LOCK(?)", { RaiseError => 1, PrintError => 0 }, $path
  ));

  if($result) {
    return $path;
  } else {
    return;
  }
}

sub lock_path {
  my($self, $path) = @_;
  my($result) = ($self->dbh->selectrow_array(
    "SELECT GET_LOCK(?,0)", { RaiseError => 1, PrintError => 0 }, $path
  ));

  if($result) {
    return $path;
  } else {
    return;
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

File::Lock::Multi::MySQL - Lock multiple strings in MySQL to emulate
taking out multiple locks on a single string.

=head1 DESCRIPTION

This module uses MySQL's C<GET_LOCK()> function on multiple strings to
emulate taking out multiple locks on a single string.

It is very important that database handles are not used to take out any
other locks, for your resource or for any other resource! From the MySQL
documentation:

"If you have a lock obtained with GET_LOCK(), it is released when you execute
RELEASE_LOCK(), execute a new GET_LOCK(), or your connection terminates
(either normally or abnormally)."

See the dbh option below for more details.

=head1 OPTIONS

In addition to the standard L<File::Lock::Multi> options, the following
additional options are available when calling C<new()>:

=over

=item format

A L<sprintf()|perlfunc/sprintf> format string used to come up with
the individual lockfile names. C<sprintf()> will be passed the file's path
and the lock number as the first and second parameters. (Default: "%s.%i").

=item dbh

Either a database handle, or a "factory" (code reference which returns a new
database handle each time it is invoked). Because each MySQL lock is unique
to a database handle, and each database handle may only have one lock, you
almost always need a fresh database handle to hold onto a lock. Example:

  my $lock = File::Lock::Multi::MySQL->new(
    file => "limited.resource", limit => 5,
    dbh => sub { DBI->connect("DBI:mysql:", $user, $password) }
  );

=back

=head1 LICENSE

Copyright 2010 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

L<File::Lock::Multi>, L<perlfunc/flock>

=cut


