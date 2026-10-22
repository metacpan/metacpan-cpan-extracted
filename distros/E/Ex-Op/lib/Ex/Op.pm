package Ex::Op;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.01';

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

1;

__END__

=encoding utf8

=head1 NAME

Ex::Op - a drop-in replacement for Exporter with custom ops

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    package My::Util;
    use Ex::Op;

    our @EXPORT_OK   = qw(add clamp);
    our %EXPORT_TAGS = (math => [qw(add clamp)]);

    op add ($x, $y) { $x + $y }
    op clamp ($v, $lo, $hi) { $v < $lo ? $lo : $v > $hi ? $hi : $v }

    package main;
    use My::Util qw(:math);

    my $z = add($a, $b);

=head1 DESCRIPTION

Ex::Op is a replacement for L<Exporter> that reads the same C<@EXPORT>,
C<@EXPORT_OK> and C<%EXPORT_TAGS>, and gives the module that uses it an C<op>
keyword. An C<op> is a named sub whose calls, once compiled, skip the work of
an ordinary sub call.



=head1 OPS

    use Ex::Op;

    op add ($x, $y) { $x + $y }
    op zero () { 0 }
    op name ($self) { $self->{name} }

An op is a named sub whose arguments are copied into its parameters, and
which reads C<@_> nowhere else. C<op add ($x, $y) { ... }> is the same sub as
C<sub add { my ($x, $y) = @_; ... }>. Calls to it that are compiled after it
skip the work of an ordinary sub call. Everything else about it is an ordinary
sub, so C<\&add>, C<&add(...)> and calls compiled before it was made all still
work, and C<@EXPORT> and C<@EXPORT_OK> can name it.

The parameters are a list of scalars, which may be empty, and the
parentheses may be left out when there are none. A missing argument leaves its
parameter undefined and extra arguments are dropped.

A body that an op cannot run, for one of the reasons under L</make>, is an
ordinary sub. L</why_not> says why.

The keyword is there from perl 5.14, from C<use Ex::Op> to the end of the
enclosing block or file, and C<no Ex::Op> ends it sooner. Where it is not,
and on perl 5.10 and 5.12, L</make> makes the same op. Where it is, C<op>
followed by anything but a name is not the keyword, so a sub called C<op> can
still be called as C<op(...)>.

A call in scalar, list or void context takes the faster path, and so does a
C<return> anywhere it is allowed. A call made outside every sub (at the top
level of a file or of a string C<eval>), a call made as the last thing in an
C<eval> block, and a call made from within the op itself are ordinary calls.
It is the same on every perl from 5.10.

An op has no call frame of its own. When its body is compiled with the
C<uninitialized> warning on, or with no lexical warnings at all, code it calls
sees it, through C<caller>, in the place of the sub that called it, so a stack
trace from inside the op names the op and leaves out its caller, and the
warning names the op's own variable. When that warning is off in the body, the
same code sees the op's caller, and the op is left out.

=head2 Why an op is faster than a sub

An ordinary call pushes a call frame for the sub, sets up C<@_> as aliases to
the arguments, and enters the sub's scope. The body's first statement,
C<my ($x, $y) = @_>, then copies the arguments out of C<@_> into the
parameters. At the end the result is copied into a new value for the caller,
and the frame is taken down again, putting back everything it saved.

A call to an op does less of that. There is no frame and no C<@_>. The
arguments are copied straight into the parameters, and the body starts at its
second statement. What a frame would put back afterwards is saved in one
step, and when the body left nothing else to undo, as most small bodies do,
the call puts it back itself at the end. A plain result is written into a value
kept at the call site, so a call makes no new value to return. A result that
is a reference or an object is still copied into a new value, so that nothing
is kept alive after the caller lets it go.

The body itself runs exactly as it would in a sub, so the saving is the cost
of the call, and the smaller the body the more of the time that is. On perl
5.42, F<bench/ops.pl> measures C<add> at 1.59 times the speed of a plain sub
with the same body, an accessor at 1.39 times, C<is_even> at 1.40, C<clamp> at
1.35 and a six-parameter sum at 1.35.

=head2 make

    my $ok = Ex::Op::make($name, $code);

Installs C<$code> under C<$name> in the calling package, or where C<$name>
says when it is qualified, and makes it an op if it can be one. Returns true
when it is one. Call it in a C<BEGIN> block, so that the calls after it are
compiled knowing.

A sub stays an ordinary sub, and C<make> returns false, when it

=over 4

=item * reads C<@_> after the first statement, with C<$_[0]>, C<shift>,
C<pop>, C<scalar @_> or any other way

=item * calls another sub as C<&name;>, which passes C<@_> on

=item * calls C<wantarray> or C<caller>, uses C<goto>, a string C<eval> or
C<__SUB__> in a closure

=item * makes a closure over its own variables, or a C<qr> with a code block

=item * returns from inside a loop, an C<eval> block, a C<sort>, C<grep> or
C<map> block, or a block with its own C<my> variables

=item * uses C<next>, C<last> or C<redo> with a label, or outside a loop of
its own

=item * has a slurpy array or hash among its parameters, has a signature, or
is an lvalue sub

=back

=head2 is_op

    Ex::Op::is_op(\&add);

True when the sub is an op. A sub that has been redefined or undefined since
it was made one is not.

=head2 why_not

    Ex::Op::why_not(\&add);    # undef for an op
    # "it calls wantarray"

The reason a sub is not an op, or C<undef> when it is one.

=head2 strict

    use Ex::Op 'strict';

Makes C<make> die, with the name and the reason, instead of returning false.
It lasts to the end of the enclosing block.

=head1 EXPORTING

    package My::Util;
    use Ex::Op;

    our @EXPORT    = qw(add);
    our @EXPORT_OK = qw(clamp $DEBUG @PATH %OPT *LOG);

C<use Ex::Op> gives the package an C<import>, the same one that
C<use Exporter 'import'> would give it. A package that already has an
C<import> keeps it. C<use Ex::Op 'import'> is accepted, so a module can
move over by changing the one word. C<use Ex::Op '-noimport'> installs no
C<import>. Inheriting with C<our @ISA = ('Ex::Op')> works too.

A module that uses one then imports the way it would with L<Exporter>:

    use My::Util;              # @EXPORT
    use My::Util qw(clamp);    # the names asked for, instead of @EXPORT
    use My::Util ();           # nothing

A name with no sigil, or with C<&>, is the sub. C<$>, C<@> and C<%> are the
variables, and C<*> is the whole glob. Every name asked for must be in
C<@EXPORT> or C<@EXPORT_OK>. If any is not, nothing is imported and the C<use>
dies with Exporter's own message, one line a name:

    "nope" is not exported by the My::Util module
    Can't continue after import errors at script.pl line 3.

A name that starts with a digit is a version check, passed to
C<< My::Util->VERSION >>. Alone it imports C<@EXPORT>, and followed by an
empty string it imports nothing.

An imported sub overrides a builtin of the same name, and an imported
variable satisfies C<use strict 'vars'>, as with Exporter. Importing over a
different sub of the same name warns only under C<-w>, as with Exporter.

=head2 Why it is faster than Exporter

Exporter's C<import> is Perl code that runs on every C<use>. For each name it
joins the package and the name into a string such as C<"My::Util::clamp">,
twice, once for where the name comes from and once for where it goes, and
perl then splits each string again to find the glob. A list with anything but
plain names also loads L<Exporter::Heavy> and walks the lists in Perl.
Ex::Op finds each name directly in the two packages' symbol tables, which
it looks up once for the whole import, and builds no names at all. When every
name asked for is a plain name it already knows, it installs them straight
from the import list, with nothing copied and no checks beyond the ones
Exporter would make. Both remember a package's exportable names after its
first import. On perl 5.42, F<bench/import.pl> measures an import of ten names
at 4.4 times Exporter's speed, C<@EXPORT> alone at 3.3 times, a tag at 2.5
times and a pattern at 1.5 times.

=head2 Tags, negation and patterns

    our %EXPORT_TAGS = (math => [qw(add clamp)], vars => [qw($DEBUG @PATH)]);

    use My::Util qw(:math);            # the names in a tag
    use My::Util qw(:DEFAULT clamp);   # @EXPORT and a name
    use My::Util qw(!add);             # @EXPORT less a name
    use My::Util qw(:math !clamp);     # a tag less a name
    use My::Util qw(/^is_/);           # every exportable name matching
    use My::Util qw(!/^_/);            # @EXPORT less the matches

The specs are read in order, each adding names or, with C<!>, taking them
away. A list that starts with a C<!> starts from C<:DEFAULT>. A pattern is
matched against every name in C<@EXPORT> and C<@EXPORT_OK>, is not anchored,
and takes no flags. A tag that is not in C<%EXPORT_TAGS> warns, and the
import then dies. Every name a spec brings in is checked as a name asked for.

=head2 @EXPORT_FAIL

    our @EXPORT_FAIL = qw(fork_twice);

    sub export_fail {
        my ($class, @names) = @_;
        return grep { !can_here($_) } @names;
    }

A name in C<@EXPORT_FAIL> that is about to be imported is passed to the
package's C<export_fail> method. Any name it returns warns that it
C<is not implemented by the My::Util module on this architecture>, and the
import dies. A package with no C<export_fail> method has every such name
returned.

=head2 export_fail

    Ex::Op::export_fail($class, @names);

The default C<export_fail>, which returns C<@names>. A package that inherits
from Ex::Op gets it as a method.

=head2 export_tags

=head2 export_ok_tags

    our %EXPORT_TAGS = (math => [qw(add clamp)], io => [qw(slurp)]);
    Ex::Op::export_tags('math');      # adds add and clamp to @EXPORT
    Ex::Op::export_ok_tags('io');     # adds slurp to @EXPORT_OK
    Ex::Op::export_ok_tags();         # every tag, to @EXPORT_OK

Add the names in the tags given, or in every tag, to the calling package's
C<@EXPORT> or C<@EXPORT_OK>. A name that is not a tag is added as it is and,
under C<-w>, warns.

=head2 require_version

    My::Util->require_version('1.02');

Calls C<< My::Util->VERSION('1.02') >> and returns what it returns. It takes
an object as well as a class.

=head2 reset_cache

    Ex::Op::reset_cache('My::Util');
    Ex::Op::reset_cache();            # every package

Each exporting package's names are remembered after its first import. A name
that is added later is found the first time it is asked for, and a list that is
replaced or changes length is read again. A name taken out of a list without
changing its length can still be imported until C<reset_cache> is called, as
with Exporter. Also as with Exporter, the first import with a list removes a
leading C<&> from the names in C<@EXPORT> and C<@EXPORT_OK> themselves.

=head2 $Ex::Op::Verbose

When true, every import warns what it adds, takes away and installs, in
Exporter's words.

=head2 export

    Ex::Op::export('My::Util', 'Some::Package', @names);
    My::Util->export('Some::Package', @names);      # with @ISA

Exports C<@names> from the first package into the second, with no regard for
who called it.

=head2 export_to_level

    Ex::Op::export_to_level('My::Util', $level, $ignored, @names);
    My::Util->export_to_level($level, $ignored, @names);   # with @ISA

Exports into the package C<$level> calls up, for a module that writes its
own C<import>:

    sub import {
        my $class = shift;
        do_something();
        Ex::Op::export_to_level($class, 1, $class, @_);
    }

The third argument is ignored, as it is by Exporter. When the package has an
C<export> method of its own, that method is called to do the work. An error is
reported at the line that did the importing.

=head2 $Ex::Op::ExportLevel

How many calls up C<import> exports to. It is 0 and is meant to be set with
C<local> by a module that calls another module's C<import> on its caller's
behalf.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-export-op at rt.cpan.org>,
or through the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Ex-Op>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ex::Op

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
