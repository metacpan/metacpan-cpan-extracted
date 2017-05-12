##########################################################################
#
# Error::Unhandled - a Module for letting Errors do their own handling
#
# Author: Toby Everett
# Revision: 1.02
# Last Change: Fixed Makefile.pl bug
##########################################################################
# Copyright 1995 Graham Barr, 1999 Toby Everett.  All rights reserved.
#
# This file is distributed under the Artistic License. See
# http://www.ActiveState.com/corporate/artistic_license.htm or
# the license that comes with your perl distribution.
#
# For comments, questions, bugs or general interest, feel free to
# contact Toby Everett at teverett@alascom.att.com
#
# Graham Barr was responsible for the prototype throw method which I copied
# and extended to implement this throw method.
##########################################################################

use Error 0.12;

package Error::Unhandled;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

@ISA = qw(Error);

$VERSION = '1.02';

sub throw {
  my $self = shift;
  local $Error::Depth = $Error::Depth + 1;

  # if we are not rethrow-ing then create the object to throw
  $self = $self->new(@_) unless ref($self);

  my $i = 0;
  my $handled = 0;
  while(my $subname = (caller($i++))[3]) {
    if ($subname eq '(eval)' && (caller($i))[3] eq 'Error::subs::try') {
      $handled = 1;
      last;
    }
  }
  unless ($handled) {
    if (exists $self->{unhandled}) {
      ref($self->{unhandled}) eq 'CODE' and $self->{unhandled}->($self);
    } else {
      $self->unhandled;
    }
  }
  die $Error::THROWN = $self;
}

sub unhandled {
}

1;

__END__

=head1 NAME

Error::Unhandled - a Module for letting Errors do their own handling

=head1 SYNOPSIS

  use Error qw(:try);
  use Error::Unhandled;

  try {
    &foo;
  } otherwise {
    my $E = shift;
    print "I caught:\n".$E->stringify."\n\n";
  };

  &foo;

  sub foo {
    throw Error::Unhandled(unhandled => sub {print "No one handled this.\n"; exit});
  }

=head1 DESCRIPTION

While doing ASP programming, I wanted to use an object oriented exception handling system.  Graham
Barr pointed me at C<Error.pm>, which handled almost everything I needed.  It was missing,
however, a way for exceptions to define their own default error handling behavior.  This can be
very useful when ASP programming - someone using your object can decide to implement their own
error handling routines, but if they don't the user will at least get a semi-informative message
in their browser.  After trying several different approaches, I ended up with a subclass of
C<Error> titled C<Error::Unhandled>.

The B<only> difference in behavior between C<Error::Unhandled> and C<Error> is what happens when
C<throw> is called.  The implementation of C<throw> in C<Error::Unhandled> uses C<caller> to
search the call stack, looking for C<Error::subs::try>.  If it finds one, it throws the exception
as per normal behavior.  If it doesn't find one, it calls C<$self-E<gt>unhandled>.  Before doing
that, however, it checks to see if the element C<unhandled> is defined in its hash.  If it is and
it is a reference to a subroutine, it calls that instead.  Note that if the element C<unhandled>
is present and is not a reference to a subroutine, C<throw> will not call C<$self-E<gt>unhandled>.
Finally, after all of that returns, C<throw> will throw the exception as per normal behavior.  If
you don't want it to throw the exception, call C<exit> or C<die> within your C<unhandled>
subroutine.

It is, of course, also possible (and recommended in many situations) to sub class
C<Error::Unhandled> and provide a class-defined implementation of C<unhandled>.  Also note that
both the instance-defined and class-defined C<unhandled> methods receive C<$self> as their first
parameter.

=head2 Installation instructions

This module requires C<Error>, available from CPAN.

=head1 AUTHOR

Toby Everett, teverett@alascom.att.com

=cut
