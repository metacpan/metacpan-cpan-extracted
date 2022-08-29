package English::Name;
$English::Name::VERSION = '0.002';
use v5.10;
use strict;
use warnings;

use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

# ABSTRACT: ${^ENGLISH_NAME} for magic variables

__END__

=pod

=encoding UTF-8

=head1 NAME

English::Name - ${^ENGLISH_NAME} for magic variables

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use English::Name;

 if (${^ERRNO} =~ /denied/) { ... }

=head1 DESCRIPTION

This module provides aliases for the built-in variables whose names no one seems to like to read much like the `English` module does and is described in L<perlvar>. However instead of using C<$LONG_NAME>, it uses C<${^LONG_NAME}>, making it more obvious that these are in fact magical variables. As caret variables are super-global, this module has a global effect.

=head1 ALIASES

This module defines the following aliases:

=over 4

=item * C<${^ARG}> => C<$_>

=item * C<${^LIST_SEPARATOR}> => C<$\>

=item * C<${^PID}> => C<$$>

=item * C<${^PROCESS_ID}> => C<$$>

=item * C<${^PROGRAM_NAME}> => C<$0>

=item * C<${^REAL_GROUP_ID}> => C<$(>

=item * C<${^GID}> => C<$(>

=item * C<${^EFFECTIVE_GROUP_ID}> => C<$)>

=item * C<${^EGID}> => C<$)>

=item * C<${^REAL_USER_ID}> => C<< $< >>

=item * C<${^UID}> => C<< $< >>

=item * C<${^EFFECTIVE_USER_ID}> => C<< $> >>

=item * C<${^EUID}> => C<< $> >>

=item * C<${^SUBSCRIPT_SEPARATOR}> => C<$;>

=item * C<${^SUBSEP}> => C<$;>

=item * C<${^OLD_PERL_VERSION}> => C<$]>

=item * C<${^SYSTEM_FD_MAX}> => C<$^F>

=item * C<${^INPLACE_EDIT}> => C<$^I>

=item * C<${^OSNAME}> => C<$^O>

=item * C<${^PERL_VERSION}> => C<$^V>

=item * C<${^EXECUTABLE_NAME}> => C<$^X>

=item * C<${^PERLDB}> => C<$^P>

=item * C<${^LAST_PAREN_MATCH}> => C<$+>

=item * C<${^LAST_SUBMATCH_RESULT}> => C<$^N>

=item * C<${^LAST_MATCH_END}> => C<$+>

=item * C<${^LAST_MATCH_START}> => C<$->

=item * C<${^LAST_REGEXP_CODE_RESULT}> => C<$^R>

=item * C<${^INPUT_LINE_NUMBER}> => C<$.>

=item * C<${^INPUT_RECORD_SEPARATOR}> => C<$/>

=item * C<${^RS}> => C<$/>

=item * C<${^NR}> => C<$.>

=item * C<${^OUTPUT_FIELD_SEPARATOR}> => C<$,>

=item * C<${^OFS}> => C<$,>

=item * C<${^OUTPUT_RECORD_SEPARATOR}> => C<$\>

=item * C<${^ORS}> => C<$\>

=item * C<${^OUTPUT_AUTOFLUSH}> => C<$|>

=item * C<${^OS_ERROR}> => C<$!>

=item * C<${^ERRNO}> => C<$!>

=item * C<${^EXTENDED_OS_ERROR}> => C<$^E>

=item * C<${^EXCEPTIONS_BEING_CAUGHT}> => C<$^S>

=item * C<${^WARNING}> => C<$^W>

=item * C<${^EVAL_ERROR}> => C<$@>

=item * C<${^CHILD_ERROR}> => C<$?>

=item * C<${^COMPILING}> => C<$^C>

=item * C<${^DEBUGGING}> => C<$^D>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
