
require 5;
# Time-stamp: "2004-12-29 19:09:59 AST"
package IO::Null;
use strict;
use vars qw($VERSION @ISA);
#use Carp ();

use IO::Handle ();
@ISA = ('IO::Handle');

$VERSION = "1.01";

=head1 NAME

IO::Null -- class for null filehandles

=head1 SYNOPSIS

  use IO::Null;
  my $fh = IO::Null->new;
  print $fh "I have nothing to say\n";  # does nothing.
  # or:
  $fh->print("And I'm saying it.\n");   # ditto.
  # or:
  my $old = select($fh);
  print "and that is poetry / as I needed it --John Cage"; # nada!
  select($old); 

Or even:

  tie(*FOO, IO::Null);
  print FOO "Lalalalala!\n";  # does nothing.

=head1 DESCRIPTION

This is a class for null filehandles.

Calling a constructor of this class always succeeds, returning
a new null filehandle.

Writing to any object of this class is always a no-operation,
and returns true.

Reading from any object of this class is always no-operation,
and returns empty-string or empty-list, as appropriate.

=head1 WHY

You could say:

  open(NULL, '>/dev/null') || die "WHAAT?! $!";

and get a null FH that way.  But not everyone is using an OS that
has a C</dev/null>

=head1 IMPLEMENTATION

This is a subclass of IO::Handle.  Applicable methods with
subs that do nothing, and return an appropriate value.

=head1 SEE ALSO

L<IO::Handle>, L<perltie>, I<IO::Scalar>

=head1 CAVEATS

* This:

  use IO::Null;
  $^W = 1;  # turn on warnings
  tie(*FOO, IO::Null);
  print FOO "Lalalalala!\n";  # does nothing.
  untie(*FOO);

has been known to produce this odd warning:

  untie attempted while 3 inner references still exist.

and I've no idea why.

* Furthermore, this:

  use IO::Null;
  $^W = 1;
  *FOO = IO::Null->new;
  print FOO "Lalalalala!\n";  # does nothing.
  close(FOO);

emits these warnings:

  Filehandle main::FOO never opened.
  Close on unopened file <GLOB>.

...which are, in fact, true; the FH behind the FOO{IO} was never
opened on any real filehandle.  (I'd welcome anyone's (working)
suggestions on how to suppress these warnings.)

You get the same warnings with:

  use IO::Null;
  $^W = 1;
  my $fh = IO::Null->new;
  print $fh "Lalalalala!\n";  # does nothing.
  close $fh;

Note that this, however:

  use IO::Null;
  $^W = 1;
  my $fh = IO::Null->new;
  $fh->print("Lalalalala!\n");  # does nothing.
  $fh->close();

emits no warnings.

* I don't know if you can successfully untaint a null filehandle.

* This:

  $null_fh->fileno

will return a defined and nonzero number, but one you're not likely
to want to use for anything.  See the source.

* These docs are longer than the source itself.  Read the source!

=head1 COPYRIGHT

Copyright (c) 2000 Sean M. Burke. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Sean M. Burke C<sburke@cpan.org>

=cut

###########################################################################
# Doesn't support handle-untainting (yet)?
sub _TRUE  {  1 }
sub _FALSE { '' }

*CLOSE = *PRINT = *PRINTF = *WRITE =
*close = *print = *printf = *write =
*opened = *eof = *syswrite = *ungetc = *clearerr = *flush =
*binmode = \&_TRUE;

*GETC = *READ =
*getc = *read = *error = *getline = \&_FALSE;
 # is getline ever used?

sub readline {
  return() if wantarray;
  return '';
}
*READLINE = \&readline;

sub getlines { return(); } # empty-list
sub fileno { -1/($_[0] || 2) } # a presumably safe value!
sub DESTROY { 1 };

*new = *nem_from_fd = *fdopen = \&TIEHANDLE;

sub TIEHANDLE { # return the constructed object
  # Ignores parameters after $_[0]
  local(*GLOB);
   # Used to have my $x; bless \$x.
   # But you can't select($x) something that's not a globref, apparently.
  return bless \*GLOB, ref($_[0]) || $_[0];
}

# TODO:  have an AUTOLOAD that returns true?

###########################################################################
1;

__END__

