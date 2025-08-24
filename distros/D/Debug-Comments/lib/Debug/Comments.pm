use 5.010;
use strict;
use warnings;

package Debug::Comments;
our $VERSION = '1.000';

use Filter::Util::Call;

my $COLOR = $ENV{NO_COLOR} ? '' : $ENV{DEBUG_COMMENTS_COLOR} // '0;34;47';
my $CON   = $COLOR && -t STDERR ? "\e[${COLOR}m" : '';
my $COFF  = $COLOR && -t STDERR ? "\e[0m"        : '';

sub import {
    my ($class, $prefix) = @_;
    $prefix //= '@!';
    $prefix = quotemeta($prefix);
    if ($ENV{DEBUG_COMMENTS_LIMIT}) {
        $class = caller;
        return unless grep {
            substr($_, -1, 1) eq '*'
                ? substr($_, 0, -1) eq substr($class, 0, length($_) - 1)
                : $class eq $_
        } $ENV{DEBUG_COMMENTS_LIMIT} =~ /\S+/g
    }
    filter_add sub {
        my $status = filter_read();
        if ($status > 0 and /^(\s*)#$prefix\s+(\S.*)/) {
            my $debug = $2;
            my $stripwarn =
                $debug =~ tr/`//d ?
                q|BEGIN { warn "Backticks stripped from debug message" } | :
                '';
            $_ = qq|$1${stripwarn}warn Debug::Comments::_msg(__FILE__, __LINE__, qq`$debug`);\n|;
        }
        return $status;
    };
}

sub _msg {
    my ($file, $line, $msg) = @_;
    my $t = time - $^T;
    my $s = $t % 60;
    my $m = int($t / 60);
    return sprintf(
        "%s%02d:%02d [%s:%d]%s %s\n",
        $CON, $m, $s, $file, $line, $COFF, $msg
        );
}

1;
__END__

=head1 NAME

Debug::Comments - Source filter which turns comments into log messages

=head1 SYNOPSIS

    use if $ENV{DEBUG}, 'Debug::Comments', '@!';
    #@! This is a debug message. DEBUG=$ENV{DEBUG}

=head1 DESCRIPTION

This module is a Perl source filter which turns certain comments into
debug output.  It's a good alternative to peppering your code with C<<
warn "..." if DEBUG; >> statements: the comments are simply comments
with no overhead in the absence of the filter, but still informative
in their own right.

The output is primarily intended to provide a visual trace of where
your code is going, so it includes the filename and line number where
the debug comment is located.  This part is colour-coded on TTY output
by default to make it visually distinct.  Aside from that, the comment
is interpreted as though it appeared in double-quotes at that point in
your code, allowing display of most simple values.

This filter tries to be super-simple rather than super-smart, so some
caution is required to ensure you don't translate something other than
a comment into a debug output statement.  This module takes the
pragmatic approach that a sufficiently distinctive prefix is good
enough for the job.  You can choose your own if you aren't happy with
the default.  Mixed code-and-comment lines are never altered.

Perl source filters in general are fraught with peril and should be
used B<very> sparingly.  That said, this approach has significant
advantages over any other approach.  First, the source is valid and
reasonable when the filter is excluded, so using it does not create a
dependency on it.  The filter can be excluded very easily via "use
if", and should be excluded by default.  Second, there is B<zero>
overhead for the debug code when excluded: they are simple comments.

=head1 USAGE

The recommended way to incorporate this module is as per the synopsis:
a "use if" pragma conditioned on an environment variable which you set
to trigger the debug mode.  The import method takes a single optional
argument: the debug-comment identifier string, defaulting to "@!".

The debug-comment identifier string sets a fairly tight constraint on
what's recognised as a debug comment.  A debug comment line starts
with optional whitespace, then "#", then the identifier string, then
whitespace, then some non-whitespace debug text.  Any line matching
this pattern is treated as a debug comment; other lines are untouched.
Ensure that the identifier string is distinctive enough to prevent
matching on non-comment lines such as multi-line strings.

    #@! This is a debug comment using the default identifier.
        #@! So is this: the indent is not significant.
    #@!~ This isn't one: the identifier string doesn't match.
    #@!This isn't one either due to the lack of whitespace.
    ...; #@! Mixed code and comment lines never match.
    #@!
    # The above line doesn't match because there's no text.
    my $oopsie = <<'EOT';
    #@! This matches, but it's not a comment!
    EOT

Whitespace after the debug-comment identifier is required but skipped;
the rest of the line is interpreted as a double-quoted string to emit
via warn at this point.  This means that variables are interpolated
and must exist or compilation will fail.  Backticks are not allowed:
they are used as delimiters in the generated code.  Any backticks
present will be stripped and evoke a warning.

The output will be prefixed with a relative timestamp, the filename,
and line number of the debug comment.  This prefix will have ANSI
colour (sorry, "color") applied if STDERR is a TTY.  You can choose a
different color scheme via the "DEBUG_COMMENTS_COLOR" environment
variable: the default is "0;34;47"; setting it to empty string will
disable it entirely.

=head1 ENVIRONMENT

The module recognises the following environment variables.  You get to
choose your own (if any) for the "use if" pragma.

=head2 DEBUG_COMMENTS_COLOR

Default "0;34;47".  Set to empty string for no ANSI color output.

=head2 DEBUG_COMMENTS_LIMIT

If set, it is interpreted as a space-separated list of modules for
which debug comments are to be enabled.  If a module name ends in "*",
it is interpreted as a left-side match rather than a full match, so
"Foo::*" would enable debug comments for any module in the "Foo::"
namespace.  Note that this only selectively disables things which
import this module: it does not magically enable other modules.  Note
also that the relevant package name is whatever one was in effect at
the time B<Debug::Comments> was used in a module.

=head2 NO_COLOR

If set to a true value, ANSI color output is disabled, following the
no-color.org convention.

=head1 LIMITATIONS

These issues are addressed elsewhere in the documentation, but are
repeated here to be sure they aren't missed.

=head2 The filtering is simple, not smart

This is a Perl source filter, and comes with all the usual caveats
including compile-time processing overhead.  It does not try to
distinguish between comment lines and things which look like comment
lines in the middle of multi-line strings.  Choose a distinctive
prefix to avoid unintended conversion if the default is inadequate.

=head2 Debug comments are double-quoted strings, no backticks

Debug comments are converted to double-quoted strings to be printed
via warn().  All the usual syntactic constraints on variable
interpolation and backslash escapes apply.  Backtick characters are
not permitted: they will be stripped and evoke a compile-time warning
if present.

=head2 No unimport

You can't turn the feature off with "no" part-way through the file,
and it's not a pragma, restricted to an enclosing BLOCK: the source
filter remains in effect from initial use to end of file or __END__
marker.  The recommended approach is to have an all-or-nothing "use
if" near the head of the file (but after the package declaration, if
any), conditioned on an environment variable or some other preferred
debug-mode indicator.

Importing more than once does not replace the old filter: it adds a
new one.  In principle this can mean independent sets of debug
comments with different prefixes, but I'm not advocating it.

=head1 SEE ALSO

This module is not the first of its kind, though it's probably the
simplest.  If it's too simple for your tastes, consider these
alternatives by other authors.

L<Smart::Comments> is a heavyweight alternative that's been around a
long time.  If you like the idea of this module but think it needs
more bells, whistles, flashing lights, and spinning hubcaps, try it.

L<Debug::Filter::PrintExpr> is a similar concept which is more attuned
to dumping data structures.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2025 by Brett Watson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
