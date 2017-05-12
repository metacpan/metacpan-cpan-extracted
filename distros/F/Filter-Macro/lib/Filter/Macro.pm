package Filter::Macro;
$Filter::Macro::VERSION = '0.11';

use strict;
use Filter::Simple::Compile sub {
    $_ = quotemeta($_);
    s/\\\n/\n/g;
    $_ = sprintf(q(
        use Filter::Simple::Compile sub {
            $_ = join("\n",
                '#line '.(__LINE__+1).' '.__FILE__,
                "%s",
                '#line %s %s',
                $_,
            );
        };
        1;
    ), $_, (caller(6))[2]+1, (caller(6))[1]);
};

1;

=head1 NAME

Filter::Macro - Make macro modules that are expanded inline

=head1 VERSION

This document describes version 0.11 of Filter::Macro, released
May 11, 2006.

=head1 SYNOPSIS

In F<MyHandyModules.pm>:

    package MyHandyModules;
    use Filter::Macro;
    # lines below will be expanded into caller's code
    use strict;
    use warnings;
    use Switch;
    use IO::All;
    use Quantum::Superpositions;

In your program or module:

    use MyHandyModules; # lines above are expanded here

=head1 DESCRIPTION

If many of your programs begin with the same lines, it may make sense to
abstract them away into a module, and C<use> that module instead.

Sadly, it does not work that way, because by default, all lexical pragmas,
source filters and subroutine imports invoked in F<MyHandyModules.pm> takes
effect in that module, I<not> the calling programs.

One way to solve this problem is to use B<Filter::Include>:

    use Filter::Include;
    include MyHandyModules;

However, it would be really nice if F<MyHandyModules.pm> could define the
macro-like semantic itself, instead of placing the burden on the caller.

This module lets you do precisely that.  All you need to do is to put one
line in F<MyHandyModules.pm>, after the C<package MyHandyModules;> line:

    use Filter::Macro;

With this, a program or module that says C<use Filter::Macro> will expand
lines below C<use Filter::Macro> into their own code, instead of the default
semantic of evaluating them in the C<MyHandyModules> package.

Line numbers in error and warning messages are unaffected by this module;
they still point to the correct file name and line numbers.

=head1 SEE ALSO

L<Filter::Include>, L<Filter::Simple::Cached>

=head1 AUTHORS

Audrey Tang E<lt>cpan@audreyt.orgE<gt>

Based on Damian Conway's concept, covered in his excellent I<Sufficiently
Advanced Technologies> talk.

=head1 COPYRIGHT (The "MIT" License)

Copyright 2004, 2006 by Audrey Tang E<lt>cpan@audreyt.orgE<gt>.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is fur-
nished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FIT-
NESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE X
CONSORTIUM BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=cut
