package JSPL::Function;

use strict;
use warnings;

require JSPL::Object;

our @ISA = qw(JSPL::Object);

use overload '&{}'=> \&CODE_REF, fallback => 1;

sub CODE_REF {
    my $self = shift;
    my $f = $self->__jsvalue;
    my $c = $self->__context;
    return ${$self}->[7] ||= sub {
	@_ = ($c, undef, $f, [@_]);
	goto &JSPL::Context::jsc_call;
    };
}

sub call {
    my $self = shift;
    my $this = shift;
    @_ = ($self->__context, $this, $self, [@_]);
    goto &JSPL::Context::jsc_call;
}

sub apply {
    my($self, $this, $args) = @_;
    @_ = ($self->__context, $this, $self, $args);
    goto &JSPL::Context::jsc_call;
}

sub new {
    my $self = shift;
    $self->__context->jsc_eval($self, q| new (this)(); |, "", 1);
}

sub prototype {
    my $self = shift;
    local $self->__context->{AutoTie} = 0;
    $self->{'prototype'};
}

1;
__END__

=head1 NAME

JSPL::Function - Reference to a JavaScript Function

=head1 DESCRIPTION

Functions in JavaScript are actually C<Function>-objects. This class
encapsulates them and allows you to invoke them from Perl.

The basic way to invoke a JSPL::Function instance is with the
method L<JSPL::Context/call>.

    my $func = $ctx->eval(q{
	// Define a simple function
	function myfunc(arg1) {
	    say("You sendme " + arg1);
	};
	// And return a reference to it
	myfunc;
    });

    $ctx->call($func => "some text"); # say 'You sendme some text'

You can use C<< $ctx->call >> with the name of the Function as its first argument,
but a JSPL::Function instance can hold a reference to an anonymous one:

    my $func2 = $ctx->eval(q{ function (a, b) { return a + b }; });
    $ctx->call($func2 => 5, 6);         # 11
    $ctx->call($func2 => "foo", "bar"); # 'foobar'

Instances of JSPL::Function implement a short cut to avoid such verbose
code:

    $func2->(10, 20);     # 30
    $func->('a value');   # Say "You sendme a value"

Please read on.

This class inherits from JSPL::Object.

=head1 PERL INTERFACE

Function instances are JavaScript Objects and as such, they have some methods,
and this module adds some more, usable from perl.

=head2 INSTANCE METHODS

=over 4

=item call ( $this, ... )

  $func->call($somethis, $arg1, $arg2);

Call the underlaying JavaScript Function as an instance of the I<$somethis>
argument. All remaining arguments are passed as arguments to the function.

That is, inside the function C<this> will be the value of I<$somethis>.

This is the analogous to C<func.call(somethis, arg1, arg2)> in JavaScript when
C<func> is a reference to the function to be called.

This is different from C<< $ctx->call($func, ...) >> that always uses the
global object for C<this>.

=item apply ( $this, $array_arguments )

    $func->apply($somethis, \@arguments);

Call the underlaying JavaScript Function in the same way as L</call> above, but
use the elements of C<$array_arguments> as the arguments to the call,
I<$array_arguments> must be an ARRAY reference.

Analogous to C<func.apply(somethis, arguments)> in JavaScript.

=item new ( )

Call the underlaying JavaScript Function as a constructor.

=item prototype ( )

Returns the C<prototype> of the function as a JSPL::Object. Useful if the
function is a constructor and you need to inspect or modify its C<prototype>
property.

=item CODE_REF ( )

Returns a CODE_REF that encapsulate a closure that calls the underlaying
JSPL::Function.

The reference is cached, so every time you call CODE_REF, you obtain the
same reference.  This reference is the same one used for the L<"OVERLOADED
OPERATIONS"> below, so you seldom need to call this method.

=back

=head2 INSTANCE PROPERTIES

All instances of Function have a few properties which can be used in Perl
when the JSPL::Function is seen as a L<JSPL::Object>

=over 4

=item name

  $func->{name}; # 'myfunc'

Retrieves the name of the function.

=item length

  $func->{length}; # 1

Retrieves the number of arguments that the function expects.

=back

=head2 OVERLOADED OPERATORS

Instances of this class overload C<&{}> which means that you can use the
instance as a code-reference directly.

    $func->($arg1, $arg2, ...);

And inherit the overload C<%{}> from L<JSPL::Object/"OVERLOADED OPERATORS">.

=cut
