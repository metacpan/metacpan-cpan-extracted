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

… or, something a bit fancier:

    my $js = JavaScript::QuickJS->new()->std()->helpers();

    $js->eval_module( q/
        import * as std from 'std';

        for (const [key, value] of Object.entries(std.getenviron())) {
            console.log(key, value);
        }
    / );

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

our $VERSION = '0.15';

XSLoader::load( __PACKAGE__, $VERSION );

# ----------------------------------------------------------------------

=head1 METHODS

=head2 $obj = I<CLASS>->new( %CONFIG_OPTS )

Instantiates I<CLASS>. %CONFIG_OPTS have the same effect as in
C<configure()> below.

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = $class->_new();

    return %opts ? $self->configure(%opts) : $self;
}

=head2 $obj = I<OBJ>->configure( %OPTS )

Tunes the QuickJS interpreter. Returns I<OBJ>.

%OPTS are any of:

=over

=item * C<max_stack_size>

=item * C<memory_limit>

=item * C<gc_threshold>

=back

For more information on these, see QuickJS itself.

=cut

sub configure {
    my ($self, %opts) = @_;

    my ($stack, $memlimit, $gc_threshold) = delete @opts{'max_stack_size', 'memory_limit', 'gc_threshold'};

    if (my @extra = sort keys %opts) {
        Carp::croak("Unknown: @extra");
    }

    return $self->_configure($stack, $memlimit, $gc_threshold);
}

#----------------------------------------------------------------------

=head2 $obj = I<OBJ>->set_globals( NAME1 => VALUE1, .. )

Sets 1 or more globals in I<OBJ>. See below for details on type conversions
from Perl to JavaScript.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->helpers()

Defines QuickJS’s “helpers”, e.g., C<console.log>.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->std()

Enables (but does I<not> import) QuickJS’s C<std> module.
See L</SYNOPSIS> above for example usage.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->os()

Like C<std()> but for QuickJS’s C<os> module.

=head2 $VALUE = I<OBJ>->eval( $JS_CODE )

Comparable to running C<qjs -e '...'>. Returns $JS_CODE’s last value;
see below for details on type conversions from JavaScript to Perl.

Untrapped exceptions in JavaScript will be rethrown as Perl exceptions.

$JS_CODE is a I<character> string.

=head2 $obj = I<OBJ>->eval_module( $JS_CODE )

Runs $JS_CODE as a module, which enables ES6 module syntax.
Note that no values can be returned directly in this mode of execution.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->await()

Blocks until all of I<OBJ>’s pending work (if any) is complete.

For example, if you C<eval()> some code that creates a promise, call
this to wait for that promise to complete.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->set_module_base( $PATH )

Sets a base path (a byte string) for ES6 module imports.

Returns I<OBJ>.

=head2 $obj = I<OBJ>->unset_module_base()

Restores QuickJS’s default directory for ES6 module imports
(as of this writing, it’s the process’s current directory).

Returns I<OBJ>.

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

=item * Function, RegExp, and Date objects become Perl
L<JavaScript::QuickJS::Function>, L<JavaScript::QuickJS::RegExp>,
and L<JavaScript::QuickJS::Date> objects, respectively.

=item * Behaviour is B<UNDEFINED> for other object types.

=back

=back

=head1 TYPE CONVERSION: PERL → JAVASCRIPT

Generally speaking, it’s the inverse of JS → Perl:

=over

=item * Perl strings, numbers, & booleans become corresponding JavaScript
primitives.

B<IMPORTANT:> Perl versions before 5.36 don’t reliably distinguish “numeric
strings” from “numbers”. If your perl predates 5.36, typecast accordingly
to prevent your Perl “number” from becoming a JavaScript string. (Even in
5.36 and later it’s still a good idea.)

=item * Perl undef becomes JS null.

=item * Unblessed array & hash references become JavaScript arrays and
“plain” objects.

=item * L<Types::Serialiser> booleans become JavaScript booleans.

=item * Perl code references become JavaScript functions.

=item * L<JavaScript::QuickJS::Function> objects become their original
JavaScript C<Function> objects.

=item * L<JavaScript::QuickJS::RegExp> objects become their original
JavaScript C<RegExp> objects.

=item * Anything else triggers an exception.

=back

=head1 MEMORY HANDLING NOTES

If any instance of a class of this distribution is DESTROY()ed at Perl’s
global destruction, we assume that this is a memory leak, and a warning is
thrown. To prevent this, avoid circular references, and clean up all global
instances.

Callbacks make that tricky. When you give a JavaScript function to Perl,
that Perl object holds a reference to the QuickJS context. Only once that
object is C<DESTROY()>ed do we release that QuickJS context reference.

Consider the following:

    my $return;

    $js->set_globals(  __return => sub { $return = shift; () } );

    $js->eval('__return( a => a )');

This sets $return to be a L<JavaScript::QuickJS::Function> instance. That
object holds a reference to $js. $js also stores C<__return()>,
which is a Perl code reference that closes around $return. Thus, we have
a reference cycle: $return refers to $js, and $js refers to $return. Those
two values will thus leak, and you’ll see a warning about it at Perl’s
global destruction time.

To break the reference cycle, just do:

    undef $return;

… once you’re done with that variable.

You I<might> have thought you could instead do:

    $js->set_globals( __return => undef )

… but that doesn’t work because $js holds a reference to all Perl code
references it B<ever> receives. This is because QuickJS, unlike Perl,
doesn’t expose object destructors (C<DESTROY()> in Perl), so there’s no
good way to release that reference to the code reference.

=head1 CHARACTER ENCODING NOTES

QuickJS (like all JS engines) assumes its strings are text. Since Perl
can’t distinguish text from bytes, though, it’s possible to convert
Perl byte strings to JavaScript strings. It often yields a reasonable
result, but not always.

One place where this falls over, though, is ES6 modules. QuickJS, when
it loads an ES6 module, decodes that module’s string literals to characters.
Thus, if you pass in byte strings from Perl, QuickJS will treat your
Perl byte strings’ code points as character code points, and when you
combine those code points with those from your ES6 module you may
get mangled output.

Another place that may create trouble is if your argument to C<eval()>
or C<eval_module()> (above) contains JSON. Perl’s popular JSON encoders
output byte strings by default, but as noted above, C<eval()> and
C<eval_module()> need I<character> strings. So either configure your
JSON encoder to output characters, or decode JSON bytes to characters
before calling C<eval()>/C<eval_module()>.

For best results, I<always> interact with QuickJS via I<character>
strings, and double-check that you’re doing it that way consistently.

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
numbers as integers when possible, which fixes this precision problem.

=item * Long-double and quad-math perls may lose precision when converting
numbers to/from JavaScript. To see if this affects your perl—which, if
you’re unsure, it probably doesn’t—run C<perl -V>, and see if that perl’s
compile-time options mention long doubles or quad math.

=back

=head1 OS SUPPORT

QuickJS supports Linux & macOS natively, so these work without issue.

FreeBSD, OpenBSD, & Cygwin work after a few patches that we apply when
building this library. (Hopefully these will eventually merge into QuickJS.)

=head1 LIBATOMIC

QuickJS uses C11 atomics. Most platforms implement that functionality in
hardware, but others (e.g., arm32) don’t. To fill that void, we need to link
to libatomic.

This library’s build logic detects whether libatomic is necessary and will
only link to it if needed. If, for some reason, you need manual control over
that linking, set C<JS_QUICKJS_LINK_LIBATOMIC> in the environment to 1 or a
falsy value.

If you don’t know what any of that means, you can probably ignore it.

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

This library is copyright 2022 Gasper Software Consulting.

This library is licensed under the same terms as Perl itself.
See L<perlartistic>.

QuickJS is copyright Fabrice Bellard and Charlie Gordon. It is released
under the L<MIT license|https://opensource.org/licenses/MIT>.

=cut

#----------------------------------------------------------------------

package JavaScript::QuickJS::JSObject;

package JavaScript::QuickJS::RegExp;

our @ISA;
BEGIN { @ISA = 'JavaScript::QuickJS::JSObject' };

package JavaScript::QuickJS::Function;

our @ISA;
BEGIN { @ISA = 'JavaScript::QuickJS::JSObject' };

1;
