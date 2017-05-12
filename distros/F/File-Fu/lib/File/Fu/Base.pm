package File::Fu::Base;
$VERSION = v0.0.8;

use warnings;
use strict;
use Carp;

use File::stat ();

=head1 NAME

File::Fu::Base - nothing to see here

=head1 SYNOPSIS

=cut

use overload (
  '='  => sub {shift->clone(@_)},
  '""' => 'stringify',
  '%=' => 'append',
  '%'  => sub {shift->clonedo('append', @_)},
  # can't overload s/// or accomplish anything with prototypes
  '&'  => sub {shift->clonedo('map', @_)},
  '&=' => 'map',
  cmp  => sub {"$_[0]" cmp "$_[1]"},

  # invalid methods
  '-'      => sub {shift->error('-')},
  '*'      => sub {shift->error('*')},
  '~'      => sub {~ shift->stringify},
  nomethod => sub {shift->error($_[2])},
);

=head2 clone

  my $obj = $obj->clone;

=cut

sub clone {
  my $self = shift;
  my $clone = {%$self};
  bless($clone, ref($self));
  #carp("clone the ", overload::StrVal($self));
  foreach my $item (values(%$clone)) {
    my $ref = ref($item) or next;
    if($ref eq 'ARRAY') {
      #warn "clone [@$item]\n";
      $item = [@$item];
    }
    elsif($ref eq 'HASH') {
      $item = {%$item};
    }
    elsif(eval {$item->can('clone')}) {
      $item = $item->clone
    }
    else {
      croak("cannot deref $item");
    }
  }
  #carp("now ", overload::StrVal($clone));
  return($clone);
} # end subroutine clone definition
########################################################################

=head2 clonedo

  $clone = $self->clonedo($action, @args);

=cut

sub clonedo {
  my $self = shift;
  my ($action, $arg, $rev) = @_;
  #carp("clonedo $action", $rev ? ' backwards' : '');
  if($rev) {
    return($arg . $self->stringify) if($action eq 'append');
    croak("$action is invalid in that order");
  }

  # perl doesn't know how to stringify
  # TODO how can I tell when this is just a quoted string?
  #if($action eq 'append' and $arg =~ m/\n/) { return($self->stringify . $arg); }

  $self = $self->clone;
  $self->$action($arg);
  #carp("now ", overload::StrVal($self));
  return($self);
} # end subroutine clonedo definition
########################################################################

=head2 error

  $package->error($op);

=cut

sub error {
  my $self = shift;
  my ($op) = @_;
  croak("$op is not a valid op for a ", ref($self), " object");
} # end subroutine error definition
########################################################################

=head1 Filetests

=head2 r w x o R W X O e z s f d l p S b c t u g k T B M A C

See perldoc -f -x

=cut

foreach my $test (split(//, 'rwxoRWXOezsfdlpSbctugkTBMAC')) {
  my $subref = eval("sub {-$test shift}");
  $@ and croak("I broke this -- $@");
  no strict 'refs';
  *{"$test"} = $subref;
}

=head1 File::Spec stuff

This needs to be redone.

=cut

use File::Spec; # GRR

=head2 is_absolute

=cut

sub is_absolute {
  # XXX this is immutable, no?
  File::Spec->file_name_is_absolute($_[0]->stringify);
}

=head2 relative

Get a relative name.

  my $rel = $abs->relative;

Also, with optional relative-to directory:

  my $rel = $abs->relative($to);

=cut

sub relative {
  my $self = shift;
  my $base = shift;
  return $self->new(File::Spec->abs2rel($self->stringify,
    defined($base) ? "$base" : ()
  ));
}

=head2 relative_to

Same as relative(), but requires the $dir argument.

  my $rel = $abs->relative_to($dir);

=cut

sub relative_to {
  my $self = shift;
  my $base = shift or croak('relative_to() requires a $dir');
  return $self->relative($base);
}

=head2 resolve

Fully resolve any symlinks;

  my $path = $path->resolve;

=cut

sub resolve {
  my $self = shift;
  while(1) {
    return $self unless($self->l);
    my $to = $self->readlink;
    return $to  if($to->is_absolute);
    $self = $self->new($self->dirname . $to);
  }
} # end subroutine resolve definition
########################################################################

=head2 relative_symlink

Where $path and $linkname are both relative to the current directory.

  $path->relative_symlink($linkname);

=cut

sub relative_symlink {
  my $self = shift;
  my ($link) = @_;

  my $rel = $self->relative($self->new($link)->dirname);
  return($rel->symlink($link));
} # end subroutine relative_symlink definition
########################################################################

=head2 utime

Update the file timestamps.

  $file->utime($atime, $mtime);

Optionally, set both to the same time.

  $file->utime($time);

Also see touch().

=cut

sub utime {
  my $self = shift;
  @_ or croak("not enough arguments to utime()");
  my $at = shift;
  my $mt = @_ ? shift(@_) : $at;
  if($self->is_dir) {
    $self = $self->bare;
  }
  utime($at, $mt, $self) or croak("cannot utime '$self' $!");
} # end subroutine utime definition
########################################################################

=head2 chmod

  $path->chmod($mode);

=cut

sub chmod :method {
  my $self = shift;
  my ($mode) = @_;

  chmod($mode, "$self") or croak("cannot chmod '$self' $!");
} # end subroutine chmod definition
########################################################################

=head2 rename

Calls the builtin rename() on the $path and returns a new object with
that name.

  $path = $path->rename($newname);

=cut

sub rename :method {
  my $self = shift;
  my ($name) = @_;

  rename($self, $name) or
    croak("cannot rename '$self' to '$name' $!");
  return($self->new($name));
} # end subroutine rename definition
########################################################################

=head1 Stat Object

The stat() and lstat() methods both return a File::stat object.

=head2 stat

  my $st = $obj->stat;

=cut

sub stat {
  my $self = shift;
  my $st = File::stat::stat("$self") or
    croak("cannot stat '$self' $!");
  return($st);
} # end subroutine stat definition
########################################################################

=head2 lstat

Same as stat, but does not dereference symlinks.

  my $st = $obj->lstat;

=cut

sub lstat {
  my $self = shift;

  if($self->is_dir and $self->l) {
    $self = $self->bare;
  }
  my $st = File::stat::lstat("$self") or
    croak("cannot lstat '$self' $!");
  return($st);
} # end subroutine lstat definition
########################################################################

=head2 is_same

Returns true if the two paths are the same.  This is by string equality,
then (if both paths exist) by device+inode equality.

  $bool = $path->is_same($other);

=cut

sub is_same {
  my $self = shift;
  my ($other) = @_;
  unless(ref $other) {
    my $proto = ($self->is_file and $other =~ m#/$#) ?
      $self->dir_class : $self;
    $other =  $proto->new($other);
  }
  return(1) if($self eq $other);
  return(0) if($self->is_dir != $other->is_dir);
  my $n = 0;
  # TODO just check absolutely?
  # this currently probably misses non-existent files where the dirname
  # resolves to the same location.
  my ($s1, $s2) = map({eval {$_->stat}} $self, $other);
  return(0) unless($s1 and $s2);
  return(
    $s1->dev eq $s2->dev and
    $s1->ino eq $s2->ino
  );
} # end subroutine is_same definition
########################################################################

=head1 AUTHOR

Eric Wilhelm @ <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 BUGS

If you found this module on CPAN, please report any bugs or feature
requests through the web interface at L<http://rt.cpan.org>.  I will be
notified, and then you'll automatically be notified of progress on your
bug as I make changes.

If you pulled this development version from my /svn/, please contact me
directly.

=head1 COPYRIGHT

Copyright (C) 2008 Eric L. Wilhelm, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# vi:ts=2:sw=2:et:sta
1;
