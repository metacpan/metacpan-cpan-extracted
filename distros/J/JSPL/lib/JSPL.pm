package JSPL;
use 5.008;
use strict;
use warnings;

use DynaLoader;
use Carp;

our $VERSION;
BEGIN {
    $VERSION = '1.07';
    our @ISA = qw(DynaLoader);
    our $_gruntime = 0;
    DynaLoader::bootstrap('JSPL', $VERSION);
}

use JSPL::Boolean;
use constant JS_TRUE  => JSPL::Boolean::True();
use constant JS_FALSE => JSPL::Boolean::False();

use constant JS_NULL => 0; # TODO

use Exporter qw(import);

use constant JS_PROP_PRIVATE      => 0x1;
use constant JS_PROP_READONLY     => 0x2;
use constant JS_PROP_ACCESSOR     => 0x4;
use constant JS_CLASS_NO_INSTANCE => 0x1;

our @EXPORT = qw();
our %EXPORT_TAGS = (
    pflags => [qw(JS_PROP_PRIVATE JS_PROP_READONLY JS_PROP_ACCESSOR)],
    cflags => [qw(JS_CLASS_NO_INSTANCE)],
    primitives => [qw(JS_TRUE JS_FALSE JS_NULL)],
);
$EXPORT_TAGS{flags} = [@{$EXPORT_TAGS{pflags}}, @{$EXPORT_TAGS{cflags}}];
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
	grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
our @EXPORT_OK = ('jsvisitor', @{$EXPORT_TAGS{all}});

our %ClassMap = ();

require JSPL::Runtime;

sub get_engine_version {
    my $version_str = js_get_engine_version();

    return  wantarray ? split /\s+/, $version_str, 3 : $version_str;
}

sub supports {
    my $pkg = shift;
    for (@_) {
        my $does = $pkg->can("does_support_" . lc($_));
        croak "I don't know about '$_'" unless defined $does;
        return '' unless $does->();
    }
    return 1;
}

sub _boot_ {
    my($class, $version) = @_;
    no strict 'refs';
    *{$class.'::dl_load_flags'} = DynaLoader->can('dl_load_flags');
    $version ||= $VERSION;
    if(defined &{$class.'::bootstrap'}) {
	*{"${class}::bootstrap"}->($class, $version);
    } else {
	my $symbol = "boot_$class"; $symbol =~ s/\W/_/g;
	my $symref = DynaLoader::dl_find_symbol_anywhere($symbol);
	if($symref) {
	    DynaLoader::dl_install_xsub($class."::bootstrap", $symref);
	    *{"${class}::bootstrap"}->($class, $version);
	} else {
	    DynaLoader::bootstrap($class, $version);
	}
    }
}

1;
__END__

=head1 NAME

JSPL - A bridge between JavaScript and Perl languages

=head1 SYNOPSIS

    use JSPL;
    use Gtk2 -init;

    my $ctx = JSPL->stock_context;
    my $ctl = $ctx->get_controller;
    $ctl->install(
	'Gtk2' => 'Gtk2',
	'Gtk2.Window' => 'Gtk2::Window',
	'Gtk2.Button' => 'Gtk2::Button',
    );

    $ctx->eval(q|
	var window = new Gtk2.Window('toplevel');
	var button = new Gtk2.Button('Quit');
	button.signal_connect('clicked', function() { Gtk2.main_quit() });
	window.add(button);
	window.show_all();
	Gtk2.main();
	say("That's all folks!");
    |);

=head1 INTRODUCTION

Always thought JavaScript was for web-applications only? well, think again...

JavaScript is an easy, elegant and powerful language, known by zillions of
developers worldwide. Having been born as the scripting language for client
side Web it was lacking, until now, the library of functions that any general
purpose language deserves.

Have you enjoyed the functional and prototype based nature of JavaScript and
have you dreamed of using JavaScript to access you favorite database or to
drive your favorite widget toolkit? Then this module is for you.

In your mod_perl framework, have you ever wanted to allow your users to write
content handlers in JavaScript? Then this module is for you.

This modules gives you the power to extend JavaScript adding every
functionality that your application needs, the power to embed JavaScript in
your Perl applications, even the power to make full-blown JavaScript
applications having CPAN's resourcefulness at your fingertips.

With this module you'll be able to use from JavaScript any subroutine or class
written in Perl. And likewise, have available in Perl any JavaScript function
object, etc...

Variables and values such as primitive types, objects and functions are
automagically reflected between both environments. All your perl HASHes, ARRAYs
and objects can be used from JavaScript and all your JavaScript classes and
objects can be used from Perl.

You will be able to even define hybrid classes. Some of the methods defined in
Perl and others defined in JavaScript.

This module is not a JavaScript compiler/interpreter but a bridge between
Mozilla's SpiderMonkey and Perl engines.

If you are a JavaScript developer anxious to make full-blown JavaScript
applications see the included L<jspl> JavaScript shell.

=head1 DESCRIPTION

For use JavaScript from Perl with this module, you normally follow three simple
steps:

=over 4

=item *

B<Create a context> inside which you'll be able to evaluate javascript code.
The context holds a I<global object> with javascript's standard constructors
and functions.

You can create many different contexts each with different properties.

For details on context creation see L<JSPL::Runtime> and L<JSPL::Context>

=item *

B<Populate the context> with any new functionality your application needs. This
is done using either the C<bind_*> family of methods from
L<JSPL::Context> for simple cases or with the L<JSPL::Controller>
object associated to the context for more complex cases, for example binding Perl 
classes or entire modules.

=item *

B<Compile and/or evaluate javascript code> with C<eval>'s family of methods
and L<JSPL::Context/call>, that obtain references to JavaScript values and
call JavaScript functions.  L<JSPL::Context> provides many more methods for
doing that.

=back

JavaScript code can re-enter the Perl interpreter, for example by calling a
function defined in Perl. The flow of your program will be switching between
both interpreters freely.

Values returned by calls to functions and methods of the other interpreter will
be reflected in a proper way, see L</"DATATYPE CONVERSION> for details.

Both interpreters can generate exceptions, see L</"EXCEPTION HANDLING> for how
to handle them.

=head1 DATATYPE CONVERSION

=head2 From javascript to perl

In JavaScript there are two types, B<primitives> and B<objects>. Among the
primitives, there are B<integers>, B<numbers>, B<strings>, and B<booleans>. All
numeric and strings primitives are converted I<by value> to simple scalar
values.

The boolean primitives are wrapped in instances of L<JSPL::Boolean>, to
warrant round trip integrity.

The special JavaScript value C<undefined>, is converted to perl's C<undef>.

All objects will be wrapped to instances of L<JSPL::Object> or one of its
specialized subclasses: L<JSPL::Array>, L<JSPL::Function>,
L<JSPL::Error>. They will pass to perl I<by reference>.

See L</%ClassMap> for a way to declare new wrappers when need arise. 

=head2 From perl to javascript

All simple (non-references) perl scalar values are converted to JavaScript
B<primitives>.  All references will be wrapped in JavaScript objects, unblessed
HASH references to instances of C<PerlHash>, unblessed ARRAY references to
instances of C<PerlArray>, unblessed SCALAR references to instances of
C<PerlScalar>,  CODE references to instances of C<PerlSub>.

C<PerlSub> instances work just like C<Function> instances (javascript
functions), so they may be called.

See L<PerlArray>, L<PerlHash>, L<PerlScalar> and L<PerlSub> for details.

All blessed references (perl objects) will be wrapped I<by default> as instances
of C<PerlObject>, but you can make arrangements to use a different wrapper for
specific perl classes. See L<PerlObject> and L<JSPL::Context/bind_class>
for details.

Perl's C<undef> is converted to JavasSript's C<undefined> value.

=head2 Round trip integrity

When a value from one interpreter enters the other it will be converted/wrapped as
described above. If it gets sent back to its original interpreter JSPL engine
warrants you will see its original form.

For example, if you send a HASH reference to JavaScript and then you send it
back again to perl you'll see exactly the same HASH.

    my $h = { foo=>1, bar=>'hi' };
    sub pong {
	my $href = shift;
	warn "The same\n" if ref($href) eq ref($h);
    }
    $ctx->bind_function(pong => \&pong);
    $ctx->eval(q|     function ping(h) { pong(h); h.foo++; }    |);
    $ctx->call(ping => $h);
    
    print $h->{foo}; # 2

Similarly for javascript objects sent to perl and then returned. You'll get the
same object:

    $ctx->bind_function(ping => sub {
	my $o = shift; $ctx->call(pong => $o); $o->{foo}++;
    });

    $ctx->eval(q|
	var o = {foo:1, bar:'hi'};
	function pong(h) {
	    if(h === o) say("The same");
	}
	ping(o);
	say(o.foo); // 2
    |);

=head1 EXCEPTION HANDLING

In JavaScript a lot of operations can fail in many different ways. Even a
single assignment can fail (remember that in JavaScript every variable is a
"property" of something and there may be a getter involved which can throw an
exception).

When you are running JavaScript code, all I<untrapped> exceptions will be
raised on the caller perl side using C<croak>, normally fatal. But you can
trap them with perl's C<eval>, effectively converting JavaScript's exceptions
into perl exceptions.

Is such cases, in C<$@> you will get a L<JSPL::Error> instance.

And when from JavaScript land you reenter perl, and for any reason your perl
code dies outside an C<eval>, JSPL will convert the error, in C<$@>, into a
JavaScript exception an throw it.

So, if a fatal error occurs in perl code called from JavaScript it can be trapped
using a C<try ... catch>. If you need to raise an exception from perl you can
just use C<die($error_to_raise)>, if the error isn't handled in JavaScript, it
will be propagated and can be trapped in perl by a C<eval { ...  }> block.

This way exceptions can be handled in a regular manner in both environments.

See L<JSPL::Error> for more details

=head1 SIMILAR MODULES

=over 4

=item C<JavaScript> by Claes Jakobsson

Thought the API are similar, there is a fundamental difference: C<JavaScript>
is mainly a "converter" between types, and this module is a true "reflector",
so there are a few but important incompatibilities.

JSPL in fact was born as a fork from Claes's JavaScript perl module. 

=item C<JavaScript::SpiderMonkey> by Mike Schill and Thomas Busch

Mainly if you want to run some JavaScript inside perl.

=item C<JavaScript::V8> by Pawel Murias

Based in the V8 JavaScript engine.

=back

=head1 INTERFACE

=head2 Class methods

=over 4

=item stock_context( )

Executing JavaScript code requires a B<context>, that's an instance of a
L<JSPL::Context>. One easy way to obtain one is by calling
C<stock_context>.

The first time you call C<stock_context> a new context is created, have
its global object populated with some useful functions and values, and returned.

Every subsequent call to C<stock_context> returns the same context.

See L<JSPL::Runtime::Stock> for details on how the context is populated.

This function is intended for when you don't want to worry about contexts and
runtimes, and just need one populated with common services.

=item get_engine_version

In scalar context returns a string describing the engine such as C<JavaScript-C
1.5 2004-09-24>.

In list context returns the separate parts of the string - engine, version and
date of build.

=back

=head2 Special variables

=over 4

=item %ClassMap

C<%ClassMap> allows you to extend the wrapping system used by JSPL.

    $JSPL::ClassMap{Date} => 'My::Date';

Although javascript doesn't really have a notion of a "class", in SpiderMonkey
exist the concept of "native classes". JSPL uses the native class name
for selecting a proper perl wrapper for javascript objects entering perl.

That way, an C<Array> instance becomes a C<JSPL::Array>, for example.

JSPL defines a few of such mappings to provide specialized wrappers for
some known classed, any other object becomes a simple L<JSPL::Object>.

If you create new wrapper classes, declare them adding an entry to
%JSPL::ClassMap. The common way to do this is:

    package My::NativeFoo;
    # A wrapper for javascript's NativeFoo

    use base qw(JSPL::Object); # A must

    # Enter here any method needed in perl
    # to wrap a NativeFoo instance

    # Register my self
    $JSPL::ClassMap{NativeFoo} = __PACKAGE__;
    
    1;

So users of you wrapper should do:

    use JSPL;
    require My::NativeFoo;

=item $This

The value of javascript's C<this> when in perl code. C<$This> will be C<undef>
unless your code was called from javascript.

See L<PerlSub> for details.

=back

=begin PRIVATE

=head1 PRIVATE INTERFACE

=over 4

=item get_internal_version

Returns an integer with the value used as C<JS_VERSION> at compile time.

=item js_get_engine_version

Returns a string with the output of C<JS_GetImplementationVersion()>.

=item does_support_utf8

Returns C<PL_sv_yes> if we have compiled SpiderMonkey with
C<JS_C_STRINGS_ARE_UTF8>. Otherwise returns C<PL_sv_no>.

=item does_support_e4x

Returns C<PL_sv_yes> if we have compiled support for E4X. Otherwise returns
C<PL_sv_no>.

=item does_support_threading

Returns C<PL_sv_yes> if we have compiled support for threading. Otherwise
returns C<PL_sv_no>.

=item does_support_anonfunfix

Returns C<PL_sv_yes> if we have compiled support for the SM JS_OPTION_ANONFUNFIX.
Otherwise returns C<PL_sv_no>.

=item does_support_jit

Returns C<PL_sv_yes> if we have compiled support for the SM JIT. Otherwise
returns C<PL_sv_no>.

=item does_support_opcb

Returns C<PL_sv_yes> if we have compiled support for I<OperationCallbacks> in SM.
Otherwise returns C<PL_sv_no>

=item exact_doubles

Returns TRUE if the internal size of floating point types matches between Perl and SM.

=item supports ( @features )

Checks if all features given in I<@features> are present. Is case insensitive. Supported keys are 
B<e4x>, B<utf8> and B<threading>.

=item jsvisitor (REFERENCE_TO_SOMETHING)

Returns the list of contexts ids in which the perl "thing" referenced by
I<REFERENCE_TO_SOMETHING> is a jsvisitor. See L<JSPL::Context/jsvisitor>.

=back

=end PRIVATE

=head1 SUPPORT

There is a mailing-list available at
L<http://lists.cpan.org/showlist.cgi?name=perl-javascript>.

You may subscribe to the list by sending an empty e-mail to
C<perl-javascript-subscribe@perl.org>

You can submit any questions, comments, feature requests, etc.,
to  Salvador Ortiz <sortiz@cpan.org>

=head1 CREDITS

See L<CREDITS>

=head1 CAVEATS AND BUGS

Although perl 5.8 is supported, it lacks some features and have some bugs, we
strongly recommends you to use 5.10 or a newer perl.

In environments that support "long doubles", perl can be compiled to use them as
the default floating point type, but if its size doesn't match SM's jsdouble type,
you should expect some precision lost.

Please report any bug you found to
L<https://rt.cpan.org/Public/Dist/Display.html?Name=JSPL>

=head1 AUTHORS

=begin man

 Salvador Ortiz <sortiz@cpan.org>
 Miguel Ibarra <mibarra@msg.com.mx>

=end man

=begin html

Salvador Ortiz &lt;sortiz@cpan.org&gt;<br>
Miguel Ibarra &lt;mibarra@msg.com.mx&gt;

=end html

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008 - 2012, Salvador Ortiz <sortiz@cpan.org>
All rights reserved.

Some code adapted from Claes Jakobsson's JavaScript module, 
Copyright (c) 2001 - 2008, Claes Jakobsson <claesjac@cpan.org>

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY FOR THE
SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN OTHERWISE
STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES PROVIDE THE
SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
FITNESS FOR A PARTICULAR PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND
PERFORMANCE OF THE SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE,
YOU ASSUME THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING WILL ANY
COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR REDISTRIBUTE THE
SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE TO YOU FOR DAMAGES,
INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
OUT OF THE USE OR INABILITY TO USE THE SOFTWARE (INCLUDING BUT NOT LIMITED TO
LOSS OF DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR
THIRD PARTIES OR A FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut
