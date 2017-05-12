package File::FnMatch;

# $Id: FnMatch.pm,v 1.2 2005/03/30 05:34:57 mjp Exp $

use 5.004;
use strict;

require Exporter;
require DynaLoader;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter DynaLoader);

$VERSION = '0.02';

bootstrap File::FnMatch $VERSION;

# export nothing by default, but allow fnmatch() and all the FNM_ constants
@EXPORT_OK   = ('fnmatch', grep {/^FNM_\w+$/} keys %{File::FnMatch::} );
%EXPORT_TAGS = ( 'fnmatch' => [ @EXPORT_OK ] );

# Preloaded methods go here.

1;
__END__
=pod

=head1 NAME

File::FnMatch - simple filename and pathname matching

=head1 SYNOPSIS

  use File::FnMatch qw(:fnmatch);    # import everything

  # shell-style: match "/a/bc", but not "/a/.bc" nor "/a/b/c"
  fnmatch("/a/*", $fn, FNM_PATHNAME|FNM_PERIOD);

  # find our A- executables only
  grep { fnmatch("A-*.exe", $_) } readdir SOMEDIR;

=head1 DESCRIPTION

File::FnMatch::fnmatch() provides simple, shell-like pattern matching.

Though considerably less powerful than regular expressions, shell patterns
are nonetheless useful and familiar to a large audience of end-users.

=head2 Functions

=over 4

=item fnmatch ( PATTERN, STRING [, FLAGS] )

Returns true if I<PATTERN> matches I<STRING>, undef otherwise.  I<FLAGS> may
be the bitwise OR'ing of any supported FNM_* constants (see below).

=back

=head2 Constants

=over 4

=item FNM_NOESCAPE

Do not treat a backslash ('\') in I<PATTERN> specially.  Otherwise, a
backslash escapes the following character.

=item FNM_PATHNAME

Prohibit wildcards from matching a slash ('/').

=item FNM_PERIOD

Prohibit wildcards from matching a period ('.') at the start of a string and,
if FNM_PATHNAME is also given, immediately after a slash. 

=back

Other possibilities include at least FNM_CASEFOLD (compare C<qr//i>),
FNM_LEADING_DIR to restrict matching to everything before the first '/',
FNM_FILE_NAME as a synonym for FNM_PATHNAME, and the rather more exotic
FNM_EXTMATCH.  Consult your system documentation for details.

=head2 EXPORT

None by default.  The export tag C<:fnmatch> exports the fnmatch function and
all available FNM_* constants.

=head1 PATTERN SYNTAX

Wildcards are the question mark ('?') to match any single character and the
asterisk ('*') to match zero or more characters.  FNM_PATHNAME and FNM_PERIOD
restrict the scope of the wildcards, notably supporting the UNIX convention of
concealing "dotfiles":

Bracket expressions, enclosed by '[' and ']', match any of a set of characters
specified explicitly (C<[abcdef]>), as a range (C<[a-f0-9]>), or as the
combination these (C<[a-f0-9XYZ]>).  Additionally, many implementations
support named character classes such as C<[[:xdigit:]]>.  Character sets
may be negated with an initial '!' (C<[![:space:]]>).

Locale influences the meaning of fnmatch() patterns.  

=head1 CAVEATS

Most UNIX-like systems provide an fnmatch implementation.  This module will
not work on platforms lacking an implementation, most notably Win32.

=head1 SEE ALSO

L<File::Glob|File::Glob>, L<POSIX::setlocale|POSIX::setlocale/setlocale>,
L<fnmatch(3)>

=head1 AUTHOR

Michael J. Pomraning

Please report bugs to E<lt>mjp-perl AT pilcrow.madison.wi.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Michael J. Pomraning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
