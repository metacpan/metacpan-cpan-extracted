package JavaScript::QuickJS;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

JavaScript::QuickJS - Run JavaScript via L<QuickJS|https://bellard.org/quickjs> in Perl

=head1 SYNOPSIS

Quick and dirty …

    my $val = JavaScript::QuickJS->new()->eval( q<
        let foo = "bar";
        [ "The", "last", "value", "is", "returned." ];
    > );

=head1 DESCRIPTION

This library embeds Fabrice Bellard’s L<QuickJS|https://bellard.org/quickjs>
engine into a Perl XS module. You can thus run JavaScript
(L<ES2020|https://tc39.github.io/ecma262/> specification) directly in your
Perl programs.

This distribution includes all needed C code; unlike with most XS modules
that interface with C libraries, you don’t need QuickJS pre-installed on
your system.

=cut

# ----------------------------------------------------------------------

use XSLoader;

our $VERSION = '0.07';

XSLoader::load( __PACKAGE__, $VERSION );

# ----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new()

Instantiates I<CLASS>.

=head2 $obj = I<OBJ>->set_globals( NAME1 => VALUE1, .. )

Sets 1 or more globals in I<OBJ>. See below for details on type conversions
from Perl to JavaScript.

=head2 $obj = I<OBJ>->helpers()

Defines QuickJS’s “helpers”, e.g., C<console.log>.

=head2 $obj = I<OBJ>->std()

Enables (but does I<not> import) QuickJS’s C<std> module.

=head2 $obj = I<OBJ>->os()

Like C<std()> but for QuickJS’s C<os> module.

=head2 $VALUE = I<OBJ>->eval( $JS_CODE )

Comparable to running C<qjs -e '...'>. Returns the last value from $JS_CODE;
see below for details on type conversions from JavaScript to Perl.

Untrapped exceptions in JavaScript will be rethrown as Perl exceptions.

=head2 I<OBJ>->eval_module( $JS_CODE )

Runs $JS_CODE as a module, which enables ES6 module syntax.
Note that no values can be returned directly in this mode of execution.

=head2 $obj = I<OBJ>->set_module_base( $PATH )

Sets a base path (a byte string) for ES6 module imports.

=head2 $obj = I<OBJ>->unset_module_base()

Restores QuickJS’s default directory for ES6 module imports
(as of this writing, it’s the process’s current directory).

=cut

# ----------------------------------------------------------------------

=head1 TYPE CONVERSION: JAVASCRIPT → PERL

This module converts returned values from JavaScript thus:

=over

=item * JS string primitives become I<character> strings in Perl.

=item * JS number & boolean primitives become corresponding Perl values.

=item * JS null & undefined become Perl undef.

=item * JS objects …

=over

=item * Arrays become Perl array references.

=item * “Plain” objects become Perl hash references.

=item * Functions become Perl code references.

=item * Behaviour is B<UNDEFINED> for other object types.

=back

=back

=head1 TYPE CONVERSION: PERL → JAVASCRIPT

Generally speaking, it’s the inverse of JS → Perl, though since Perl doesn’t
differentiate “numeric strings” from “numbers” there’s occasional ambiguity.
In such cases, behavior is undefined; be sure to typecast in JavaScript
accordingly.

=over

=item * Perl strings, numbers, & booleans become corresponding JavaScript
primitives.

=item * Perl undef becomes JS null.

=item * Unblessed array & hash references become JavaScript arrays and
“plain” objects.

=item * Perl code references become JavaScript functions.

=item * Anything else triggers an exception.

=back

=head1 NUMERIC PRECISION

Note the following if you expect to deal with “large” numbers:

=over

=item * JavaScript’s numeric-precision limits apply. (cf.
L<Number.MAX_SAFE_INTEGER|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER>.)

=item * Perl’s stringification of numbers may be I<less> precise than
JavaScript’s storage of those numbers, or even than Perl’s own storage.
For example, in Perl 5.34 C<print 1000000000000001.0> prints C<1e+15>.

To counteract this loss of precision, add 0 to Perl’s numeric scalars
(e.g., C<print 0 + 1000000000000001.0>); this will encourage Perl to store
numbers as integers when possible, which fixes the precision problem.

=item * Long-double and quad-math perls may lose precision when converting
numbers to/from JavaScript. To see if this affects your perl—which, if
you’re unsure, it probably doesn’t—run C<perl -V>, and see if the
compile-time options mention long doubles or quad math.

=back

=head1 OS SUPPORT

QuickJS supports Linux & macOS natively, so these work without issue.

FreeBSD, OpenBSD, & Cygwin work after a few patches that we apply when
building this library. (Hopefully these will eventually merge into QuickJS.)

=head1 SEE ALSO

Other JavaScript modules on CPAN include:

=over

=item * L<JavaScript::Duktape::XS> and L<JavaScript::Duktape> make the
L<Duktape|https://duktape.org> library available to Perl. They’re similar to
this library, but Duktape itself (as of this writing) lacks support for
several JavaScript constructs that QuickJS supports. (It’s also slower.)

=item * L<JavaScript::V8> and L<JavaScript::V8::XS> expose Google’s
L<V8|https://v8.dev> library to Perl. Neither seems to support current
V8 versions.

=item * L<JE> is a pure-Perl (!) JavaScript engine.

=item * L<JavaScript> and L<JavaScript::Lite> expose Mozilla’s
L<SpiderMonkey|https://spidermonkey.dev/> engine to Perl.

=back

=head1 LICENSE & COPYRIGHT

Copyright 2022 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
See L<perlartistic>.

=cut

#----------------------------------------------------------------------

sub _wrap_jsfunc {
    my $jsfunc_obj = $_[0];
    return sub { $jsfunc_obj->call(@_) };
}

1;
