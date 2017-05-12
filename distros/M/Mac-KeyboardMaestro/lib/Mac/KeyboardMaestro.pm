package Mac::KeyboardMaestro;

# require a non pre-historic version of Perl.  Luckily, all version of OS X
# and Mac OS X have always shipped with something at least this modern
use 5.006;

use strict;
use warnings;

use base qw(Exporter);
our @EXPORT_OK;

use Mac::AppleScript qw(RunAppleScript);
use Carp qw(croak);

our $VERSION = "1.01";

=head1 NAME

Mac::KeyboardMaestro - Run Keyboard Maestro macros

=head1 SYNOPSIS

   use Mac::KeyboardMaestro qw(km_macro km_set km_get);

   # set a Keybaord Maestro variable
   km_set "VarName", $value;

   # run a Keyboard Maestro macro
   km_macro "Reticulate Splines";

   # get a Keboard Maestro variable
   my $result = km_get "OtherVar";

=head1 DESCRIPTION

This module is a simple interface to the OS X keyboard macro program
Keyboard Maestro.

The standard way recommended by the Keyboard Maestro application to talk to it
via Perl is to shell out to C<osascript> and pass that an AppleScript program
that calls Keyboard Maestro.  This module avoids this and talks the same
AppleScript directly in process (which is quicker) and handles all the character
escaping necessary to avoid executing parts of your macro/varible names and
values as AppleScript by mistake.

=head2 Functions

These functions can be imported, or you can use them fully qualified.  All
functions throw exceptions if the AppleScript interface to Keyboard Maestro
returns an error.

=over

=item km_macro $macro_name

=item km_macro $macro_uuid

Execute the named macro / macro with the passed uuid.  Returns an empty list.

=cut

sub _ras($) {
  my $script = shift;

  my $result = RunAppleScript($script);
  unless (length $result && defined $result) {
    croak "AppleScript returned error code $@";
  }

  # strip off any applescript string wrapper
  $result =~ s/\A"//x;
  $result =~ s/"\z//x;
  $result =~ s/\\"/"/gx;
  $result =~ s/\\\\/\\/gx;

  return $result;
}

sub _escaped($) {
  my $var = shift;

  # escape meta chars
  $var =~ s/\\/\\\\/gx;     # \ -> \\
  $var =~ s/"/\\"/gx;       # " -> \"

  return '"' . $var . '"'
}

sub _varname($) {
  my $var = shift;
  unless ($var =~ /\A [A-Za-z] [A-Za-z0-9_ ]* \z/x) {
    croak "Invalid Keyboard Maestro variable name '$var'";
  }
  return _escaped $var;
}

sub km_macro($) { _ras <<"APPLESCRIPT"; return }
  tell application "Keyboard Maestro Engine"
     do script @{[ _escaped shift ]}
     {}
  end tell
APPLESCRIPT
push @EXPORT_OK, 'km_macro';

=item km_set $varname, $value

Sets the value of the corrisponding Keyboard Maestro variable.  C<$value> will
be automatically stringified.  Returns an empty list.

=cut

sub km_set($$) { _ras <<"APPLESCRIPT"; return }
  tell application "Keyboard Maestro Engine"
    set kmVarRef to make variable with properties { name:@{[ _varname shift ]} }
    set value of kmVarRef to @{[ _escaped shift ]}
    {}
  end tell
APPLESCRIPT
push @EXPORT_OK, 'km_set';

=item km_get $varname

Gets the current value of the corrisponding Keyboard Maestro variable.  Returns
an empty string if the variable does not exist.

=cut

sub km_get($) { return _ras <<"APPLESCRIPT" }
  tell application "Keyboard Maestro Engine"
    set kmVarRef to make variable with properties { name:@{[ _varname shift ]} }
    get value of kmVarRef
  end tell
APPLESCRIPT
push @EXPORT_OK, 'km_get';

=item km_delete $varname

Deletes the corrisponding Keyboard Maestro variable.  Returns an empty list.

=cut

sub km_delete($) { _ras <<"APPLESCRIPT"; return }
    tell application "Keyboard Maestro Engine"
      delete variable @{[ _varname shift ]}
      {}
    end tell
APPLESCRIPT
push @EXPORT_OK, 'km_delete';

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2012.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

Keyboard Maestro itself is copyright Stairways Software Pty Ltd.  Neither Mark
Fowler nor this Perl library is associated with Keyboard Maestro or
Stairways Software Pty Ltd.

=head1 BUGS

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Mac-KeyboardMaestro>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Mac-KeyboardMaestro>

=head1 SEE ALSO

L<Mac::AppleScript>, L<http://www.keyboardmaestro.com/>

=cut


1;