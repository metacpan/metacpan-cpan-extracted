package English::Control;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.002";
$VERSION = eval $VERSION;

*{^ARG} = *_;

# Matching.

*{^LAST_PAREN_MATCH}     = *+;
*{^LAST_SUBMATCH_RESULT} = *^N;
*{^LAST_MATCH_START}     = *-{ARRAY};
*{^LAST_MATCH_END}       = *+{ARRAY};

# Input.

*{^INPUT_LINE_NUMBER}      = *.;
*{^NR}                     = *.;
*{^INPUT_RECORD_SEPARATOR} = */;
*{^RS}                     = */;

# Output.

*{^OUTPUT_AUTOFLUSH}        = *|;
*{^OUTPUT_FIELD_SEPARATOR}  = *,;
*{^OFS}                     = *,;
*{^OUTPUT_RECORD_SEPARATOR} = *\;
*{^ORS}                     = *\;

# Interpolation "constants".

*{^LIST_SEPARATOR} = *";
#   "    # the extra quote restores syntax checking to sanity in vim
*{^SUBSCRIPT_SEPARATOR} = *;;
*{^SUBSEP}              = *;;

# Formats

*{^FORMAT_PAGE_NUMBER}           = *%;
*{^FORMAT_LINES_PER_PAGE}        = *=;
*{^FORMAT_LINES_LEFT}            = *-{SCALAR};
*{^FORMAT_NAME}                  = *~;
*{^FORMAT_TOP_NAME}              = *^;
*{^FORMAT_LINE_BREAK_CHARACTERS} = *:;
*{^FORMAT_FORMFEED}              = *^L;

# Error status.

*{^CHILD_ERROR}       = *?;
*{^OS_ERROR}          = *!;
*{^ERRNO}             = *!;
*{^OS_ERROR}          = *!;
*{^ERRNO}             = *!;
*{^EXTENDED_OS_ERROR} = *^E;
*{^EVAL_ERROR}        = *@;

# Process info.

*{^PROCESS_ID}         = *$;
*{^PID}                = *$;
*{^REAL_USER_ID}       = *<;
*{^UID}                = *<;
*{^EFFECTIVE_USER_ID}  = *>;
*{^EUID}               = *>;
*{^REAL_GROUP_ID}      = *(;
*{^GID}                = *(;
*{^EFFECTIVE_GROUP_ID} = *);
*{^EGID}               = *);
*{^PROGRAM_NAME}       = *0;

# Internals.

*{^PERL_VERSION}            = *^V;
*{^OLD_PERL_VERSION}        = *];
*{^ACCUMULATOR}             = *^A;
*{^COMPILING}               = *^C;
*{^DEBUGGING}               = *^D;
*{^SYSTEM_FD_MAX}           = *^F;
*{^INPLACE_EDIT}            = *^I;
*{^PERLDB}                  = *^P;
*{^LAST_REGEXP_CODE_RESULT} = *^R;
*{^EXCEPTIONS_BEING_CAUGHT} = *^S;
*{^BASETIME}                = *^T;
*{^WARNING}                 = *^W;
*{^EXECUTABLE_NAME}         = *^X;
*{^OSNAME}                  = *^O;

1;

__END__

=encoding utf-8

=head1 NAME

English::Control - use names beginning with control for punctuation variables

=head1 VERSION

This document refers to version 0.002

=head1 SYNOPSIS

    use English::Control;
    if (${^ERRNO} =~ /denied/) { ... }

=head1 DESCRIPTION

This module provides aliases for the built-in variables whose names no one
seems to like to read. Variables with side-effects which get triggered just by
accessing them (like $0) will still be affected.

Unlike the L<English|English> module, the aliases created by this module begin
with a control character, and thus will be always found in package "main", in
the area reserved by perl for its own use. They don't clutter the namespace
used by your program's variables or by any other modules.

For those variables that have an B<awk> version, both long and short English
alternatives are provided. For example,  the C<$/> variable can be referred to
either ${^RS} or  ${^INPUT_RECORD_SEPARATOR} if you are using this module.

See L<perlvar> for a complete list of these. Except for $MATCH, $PREMATCH, and
$POSTMATCH, all the multi-character names are used.

Since control-character variables are forced to be in package main, nothing is
imported into the caller's namespace, and the control-character aliases are
made immediately upon compilation of this module. There is no difference
between

   use English::Control;

and

   use English::Control ();

=head1 PERFORMANCE

This module does not touch the match variables that slow down older versions of
perl. The aliases ${^PREMATCH}, ${MATCH}, and ${^POSTMATCH}  are provided by
perl itself in more recent versions.

=head1 BUGS AND LIMITATIONS

Unlike regular variables, variables that begin with control characters are
exempt from the strictures imposed by C<use strict 'vars'>. Mistyped variable
names (e.g, "${^ERRRNO}" instead of "${ERRNO}") will not be flagged by the
compiler. Thanks to Aristotle Pagaltzis for pointing this out.

Since these variables are in the space reserved by Perl for its own use,  it
may be that a future version of Perl will break this module by using some of
these variable names for a different purpose.

=head1 AUTHOR

Aaron Priven <apriven@actransit.org>

=head1 BASED ON

English::Control is a pretty simple modification of L<English|English> from
the Perl 5 distribution, by Larry Wall et al.

=head1 COPYRIGHT & LICENSE

Copyright 2017

This program is free software; you can redistribute it and/or modify it under
the terms of either:

=over 4

=item *

the GNU General Public License as published by the Free Software Foundation;
either version 1, or (at your option) any later version, or

=item *

the Artistic License version 2.0.

=back

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

