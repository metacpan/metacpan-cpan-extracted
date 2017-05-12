package Error::Dumb;

use strict;

=head1 NAME

Error::Dumb - simple error management for simple classes

=head1 SYNOPSIS

  use Some::Simple::Class;

  my $Obj = new Some::Simple::Class;
  $Obj->doSomething() or die $Obj->error():


  package Some::Simple::Class;

  use Error::Dumb;
  use vars qw(@ISA);
  # inherit from Error::Dumb
  @ISA = qw(Error::Dumb);

  sub doSomething {
    my $self = shift;
    return $self->_setError('oops, failed to do something');
  }

=head1 DESCRIPTION

Error::Dumb is a base class that is meant to be inherited by other classes.
All this class provides is an interface for setting and retrieving error messages; as documented below...

=head1 INTERFACE 

=head2 error

Accessor for private scalar ERROR.

=cut

use vars qw($VERSION);

$VERSION = do { my @r=(q$Revision: 1.2 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

sub error {
  my ($self) = @_;

  return $self->{ERROR};
}

=head2 err 

Alias to error()

=cut

sub err {
  my ($self) = @_;

  return $self->error();
}

=head2 _setError(ERRMSG)

Set private scalar ERROR to ERRMSG.

=cut

sub _setError {
  my ($self, $errmsg) = @_;

  $self->{ERROR} = $errmsg;

  return undef;
}

1;

__END__

=head1 AUTHOR

Ilia Lobsanov <ilia@lobsanov.com>

=head1 COPYRIGHT

  Copyright (c) 2001 Ilia Lobsanov, Nurey Networks Inc.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.  

=cut
