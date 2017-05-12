package Devel::UseFromCommandLineOnly;

use strict;
#use warnings;

use Carp qw(croak confess);

use vars qw($VERSION);
$VERSION = "1.00";

=head1 NAME

Devel::UseFromCommandLineOnly - use a module from the command line only

=head1 SYNOPSIS

   package Foo;
   use base qw(Devel::UseFromCommandLineOnly);

   # it's okay to use from the command line
   # these examples will work
   perl -MFoo -E 'say "This will work!"'
   perl -MFoo -E 'say "This will work!"'
   echo 'use Foo; use 5.010; say "This will work!' | perl

   # but not from a file or module
   # these examples will die
   echo "use Foo;" > /tmp/foo.pl; perl /tmp/foo.pl
   echo "package Bar; use Foo;" > /tmp/Bar.pm; perl -I/tmp -MBar

=head1 DESCRIPTION

This module prevents you from loading any subclass of it from anywhere but
the command line.

This is most useful for writing development tools that monkeypatch other people's
code. These hacks are fine to enable from the command line during development,
but you wouldn't want to allow anyone to perminatly install them in any code that
they could ship as the hacks could break at any point.  See L<Test::EnhancedIs>
as a good example of this.

To use it you simply subclass the module:

  package Foo;
  use base qw(Devel::UseFromCommandLineOnly);

This exposes an C<import> routine that checks if you're calling it from a
script or module or from the command line and throws an exception if it's
the former.

=cut

sub import {
  my $pkg = shift;

  # don't fire when the module that's using this uses it
  if ($pkg eq "Devel::UseFromCommandLineOnly") {
    return;
  }

  # process all other import arguments
  foreach (@_) {

    # skip the checks if they're disabled
    if ($_ eq "disable_command_line_checks") {
      return;
    }

    # go bang if we didn't understand the import argument
    croak "Invalid import argument to $pkg: $_"

  }

  # panic if this isn't a "-" or "-e" invocation
  my ($package, $filename, $line) = caller;
  unless ($filename eq "-e" || $filename eq "-" || $line == 0) {
    croak "Invalid use of $pkg in '$filename' at line $line; This module can only be loaded from the command line";
  }

  return;
}

=head2 Disabling this module's functionality

The one place that subclasses of this module will be needed to be loaded
from within a script that is testing that subclass.  In this case
it's possible to override this module's behavior:

  #!/usr/bin/perl

  use Test::More tests => 1;
  use Foo qw(disable_command_line_checks);
  isa_ok(Foo->new(), "Foo");

End users should NEVER EVER DO THIS.  Or, if they do, they're playing
with fire and deserve to get burnt...

=head1 AUTHOR

Written by Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

Copryright Mark Fowler 2009.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

None known.

Please see http://www.twoshortplanks.com/project/devel-usefromcommandline for
details of how to submit bugs, access the source control for
this project, and contact the author.

=head1 SEE ALSO

L<perl>

=cut

1;
