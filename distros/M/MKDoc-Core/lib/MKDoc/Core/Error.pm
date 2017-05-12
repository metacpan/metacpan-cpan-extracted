=head1 NAME

MKDoc::Core::Error - Object validation error mechanism.


=head1 SUMMARY

When building web apps errors have to be handled in a certain way. It is not possible
to rely on Javascript, and die() unless it's eval triggers a 500 internal server error,
which is a tad brutal.

This class provides a mechanism for web error reporting. When validating a data object,
the object can create one or more L<MKDoc::Core::Error> objects. Those object are then
caught by a callback subroutine which is set by L<MKDoc::Core::Plugin> objects and then
stored as an array reference within L<MKDoc::Core::Plugin> object themselves.

This allows the template to access the error array to do proper user error reporting
in the event where there would be user input errors which prevent certain objects from
validating.

When a user is editing some kind of object, it is needed to report all the errors which
the user has made. Usually, objects implement a validate() method as follows:

  sub validate
  {
      my $self = shift;
      return $self->_validate_XXX() &
             $self->_validate_XXY() &
             $self->_validate_XXZ();
  }

With each _validate_XXX() method looking like this:

  sub _validate_silly_check
  {
      my $self = shift;
      $time % 0 && return 1;

      new MKDoc::Core::Error ( 'time_is_odd' ) :
      return 0;
  }


=head1 AUTHOR

Copyright 2003 - MKDoc Holdings Ltd.

Author: Jean-Michel Hiver

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.


=head1 SEE ALSO

  L<Petal> TAL for perl
  MKDoc: http://www.mkdoc.com/

Help us open-source MKDoc. Join the mkdoc-modules mailing list:

  mkdoc-modules@lists.webarch.co.uk

=cut
package MKDoc::Core::Error;
use strict;
use warnings;


# $CALLBACK ($coderef);
our $CALLBACK = undef;
our $AUTOLOAD;


sub new
{
    my $class = shift;
    my $self  = bless { id => shift() }, $class;
    $CALLBACK->($self) if (defined $CALLBACK);
    return $self;
}


sub is
{
    my $self = shift;
    return $self->{id} eq shift;
}


1;
