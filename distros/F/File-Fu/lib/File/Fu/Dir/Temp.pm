package File::Fu::Dir::Temp;
$VERSION = v0.0.8;

use warnings;
use strict;
use Carp;

=begin shutup_pod_cover

=head2 clone

=head2 XXX

=end shutup_pod_cover

=cut

use File::Fu::File::Temp;
  *_validate = \&File::Fu::File::Temp::_validate;
  *XXX = \&File::Fu::File::Temp::XXX;

=head1 NAME

File::Fu::Dir::Temp - temporary directories

=head1 SYNOPSIS

  use File::Fu;
  my $dir = File::Fu->temp_dir;

=cut

use base 'File::Fu::Dir';
use overload (
  '/=' => sub {croak("cannot mutate a temp dir");},
  '+=' => sub {croak("cannot mutate a temp dir");},
  '.=' => sub {croak("cannot mutate a temp dir");},
);

use Class::Accessor::Classy;
rs auto_delete => \(my $set_auto_delete);
rs dir_class => \(my $set_dir_class);
no  Class::Accessor::Classy;

=head2 new

  my $tmp = File::Fu::Dir::Temp->new($dir, 'foo');

=cut

{
my %argmap = (
  nocleanup => [UNLINK => 0],
);
sub new {
  my $proto = shift;
  if(ref($proto)) { # calls to subdir, etc are not in the Temp class
    return $proto->dir_class->new(@_);
  }
  my $class = $proto;
  #warn "args: @_";
  my ($dir, $send, $opt) = $class->_validate(\%argmap, @_);

  #warn "dir: $dir";
  #warn "opts: @$send";
  my $temp = File::Temp::tempdir(@$send);
  my $self = $class->SUPER::new($temp);
  $self->{$_} = $opt->{$_} for(keys(%$opt));
  $self->{_proc} = $$;
  $self->$set_dir_class(ref($dir));

  return($self);
}} # end subroutine new definition
########################################################################

=head2 chdir

  my $dir = $dir->chdir;

=cut

sub chdir {
  my $self = shift;

  my $dir = $self->SUPER::chdir;
  $dir->{temp_parent} = $self;
  return($dir);
} # chdir ##############################################################

=for nit head2 clone
Because clone doesn't call new :-/
  $not_temp = $temp->clone;

=cut

sub clone {
  my $self = shift;
  $self = $self->SUPER::clone;
  bless($self, $self->dir_class);
} # end subroutine clone definition
########################################################################

=head2 rename

Same as the base rename(), but promotes the temp dir to a regular Dir
object (prevents any cleanup actions.)

  $temp = $temp->rename($dest);

=cut

sub rename {
  my $self = shift;
  my $dir_class = $self->dir_class;
  $self = $self->SUPER::rename(@_);
  bless($self, $dir_class);
  return($self);
}

# TODO File::Fu->temp_dir->chdir causes immediate deletion?

=head2 nocleanup

Disable autocleanup.

  $dir->nocleanup;

=cut

# XXX I think this is named wrong -- should probably just delete the
# dependency on File::Temp because I can't override that END block
sub nocleanup {
  my $self = shift;
  $self->$set_auto_delete(0);
} # end subroutine nocleanup definition
########################################################################

=head2 DESTROY

Called automatically when the object goes out of scope.

  $dir->DESTROY;

=cut

sub DESTROY {
  my $self = shift;

  # ? should this have:
  return unless($self->auto_delete);

  # forked case
  return unless($$ == $self->{_proc});

  my $string = $self->stringify;
  #warn "DESTROY ($$/$self->{_proc}", $string;
  # XXX overload stops operating in DESTROY()?

  die("$string does not exist") unless(-d $string);
  $self->remove;
  $self->{auto_delete} = 0;
} # end subroutine DESTROY definition
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
