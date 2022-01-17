##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Number.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/13
## Modified 2021/12/13
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Number;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Number );
    use Config;
    # use Machine::Epsilon ();
    use POSIX qw( Inf NaN );
    use constant {
        MAX_SAFE_INTEGER    => (POSIX::pow(2,53) - 1),
        # MAX_VALUE           => (1.7976931348623157 * POSIX::pow(10,308)),
        MAX_VALUE           => (POSIX::pow(2, $Config::Config{use64bitint} eq 'define' ? 64 : 32)),
        MIN_SAFE_INTEGER    => (-(POSIX::pow(2,53) - 1)),
        MIN_VALUE           => POSIX::pow(2, -1074),
        # <https://perldoc.perl.org/perldata#Special-floating-point:-infinity-(Inf)-and-not-a-number-(NaN)>
        # NEGATIVE_INFINITY   => -9**9**9,
        NEGATIVE_INFINITY   => -Inf,
        POSITIVE_INFINITY   => Inf,
    };
    our $EPSILON;
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    # $EPSILON = Machine::Epsilon::machine_epsilon() if( !defined( $EPSILON ) );
    $EPSILON = POSIX::pow(2,-52) if( !defined( $EPSILON ) );
    return( $self );
}

# Note: property EPSILON
sub EPSILON : lvalue { return( shift->_lvalue({
    get => sub
    {
        my $self = shift( @_ );
        return( $EPSILON );
    },
    set => sub
    {
        my( $self, $ref ) = @_;
        $EPSILON = shift( @$ref );
    }
}, @_ ) ); }

# Note: property MAX_SAFE_INTEGER is a constant

# Note: property MAX_VALUE is a constant

# Note: property MIN_SAFE_INTEGER is a constant

# Note: property MIN_VALUE is a constant

# Note: property NEGATIVE_INFINITY is a constant

# Note: property POSITIVE_INFINITY is a constant

sub isFinite { return( $_[1] != Inf ); }

sub isInteger { return( shift->_is_integer( $_[0] ) ); }

sub isNaN { return( POSIX::isnan( $_[1] ) ); }

sub isSafeInteger { return( $_[0]->_is_integer( $_[1] ) && abs( $_[1] ) < MAX_SAFE_INTEGER ); }

sub parseFloat { return( shift->new( shift( @_ ) ) ); }

sub parseInt { return( shift->new( shift( @_ ) ) ); }

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Number - HTML Object DOM Number

=head1 SYNOPSIS

    use HTML::Object::DOM::Number;
    my $this = HTML::Object::DOM::Number->new || 
        die( HTML::Object::DOM::Number->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents and manipulates numbers like 37 or -9.25.

It inherits from L<Module::Generic::Number>

=head1 PROPERTIES

=head2 EPSILON

The smallest interval between two representable numbers.

The EPSILON property has a value of approximately 2.22044604925031e-16, or 2^-52

You do not have to create a HTML::Object::DOM::Number object to access this static property (use HTML::Object::DOM::Number->EPSILON).

Example:

    my $result = abs(0.2 - 0.3 + 0.1);

    say $result;
    # expected output: 2.77555756156289e-17

    say $result < HTML::Object::DOM::Number->EPSILON;
    # expected output: 1 (i.e. true)

    if( !defined( HTML::Object::DOM::Number->EPSILON ) )
    {
        HTML::Object::DOM::Number->EPSILON = POSIX::pow(2, -52);
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/EPSILON>

=head2 MAX_SAFE_INTEGER

This represents the maximum safe integer in JavaScript i.e. (2^53 - 1).

However, under perl, it does not work the same way.

Example:

Under JavaScript

    const x = Number.MAX_SAFE_INTEGER + 1;
    const y = Number.MAX_SAFE_INTEGER + 2;

    console.log(Number.MAX_SAFE_INTEGER);
    // expected output: 9007199254740991

    console.log(x);
    // expected output: 9007199254740992

    console.log(x === y);
    // expected output: true

However, under perl, C<$x == $y> would be false of course.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER>

=head2 MAX_VALUE

This represents the maximum numeric value representable in JavaScript.

The C<MAX_VALUE> property has a value of approximately 1.79E+308, or 2^64. Values larger than MAX_VALUE are represented as Infinity.

Because MAX_VALUE is a static property of HTML::Object::DOM::Number, you always use it as C<HTML::Object::DOM::Number->MAX_VALUE>, rather than as a property of a C<HTML::Object::DOM::Number> object you created.

Example:

    if( $num1 * $num2 <= HTML::Object::DOM::Number->MAX_VALUE )
    {
        func1();
    }
    else
    {
        func2();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_VALUE>

=head2 MIN_SAFE_INTEGER

This represents the minimum safe integer in JavaScript (-(2^53 - 1)).

Because C<MIN_SAFE_INTEGER> is a static property of HTML::Object::DOM::Number, you can use it as C<HTML::Object::DOM::Number->MIN_SAFE_INTEGER>, rather than as a property of a C<HTML::Object::DOM::Number> object you created.

Example:

    HTML::Object::DOM::Number->MIN_SAFE_INTEGER # -9007199254740991
    -(POSIX::pow(2, 53) - 1)                    # -9007199254740991

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER>

=head2 MIN_VALUE

The smallest positive representable number—that is, the positive number closest to zero (without actually being zero).

Example:

    if( $num1 / $num2 >= HTML::Object::DOM::Number->MIN_VALUE )
    {
        func1();
    }
    else
    {
        func2();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_VALUE>

=head2 NEGATIVE_INFINITY

Special value representing negative infinity. Returned on overflow.

Example:

    my $smallNumber = (-HTML::Object::DOM::Number->MAX_VALUE) * 2;

    if( $smallNumber == HTML::Object::DOM::Number->NEGATIVE_INFINITY )
    {
        $smallNumber = returnFinite();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/NEGATIVE_INFINITY>

=head2 NaN

Special "Not a Number" value.

This is actually a value exported by L<POSIX>

Example:

    sub sanitise
    {
        my $x = shift( @_ );
        if( isNaN($x) )
        {
            return( HTML::Object::DOM::Number->NaN );
        }
        return($x);
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/NaN>

=head2 POSITIVE_INFINITY

Special value representing infinity. Returned on overflow.

Example:

    my $bigNumber = HTML::Object::DOM::Number->MAX_VALUE * 2;

    if( $bigNumber == HTML::Object::DOM::Number->POSITIVE_INFINITY )
    {
        $bigNumber = returnFinite();
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/POSITIVE_INFINITY>

=head1 METHODS

Inherits methods from its parent L<Module::Generic::Number>

=head2 isFinite

Determine whether the passed value is a finite number.

Example:

    HTML::Object::DOM::Number->isFinite($value)

    HTML::Object::DOM::Number->isFinite(Infinity);  # false
    HTML::Object::DOM::Number->isFinite(NaN);       # false
    HTML::Object::DOM::Number->isFinite(-Infinity); # false

    HTML::Object::DOM::Number->isFinite(0);         # true
    HTML::Object::DOM::Number->isFinite(2e64);      # true

    HTML::Object::DOM::Number->isFinite('0');       # false, would've been true with
                                                    # global isFinite('0')
    HTML::Object::DOM::Number->isFinite(undef);     # false, would've been true with
                                                    # global isFinite(undef)

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isFinite>

=head2 isInteger

Determine whether the passed value is an integer.

Example:

    HTML::Object::DOM::Number->isInteger(value)

    HTML::Object::DOM::Number->isInteger(0);           # true
    HTML::Object::DOM::Number->isInteger(1);           # true
    HTML::Object::DOM::Number->isInteger(-100000);     # true
    HTML::Object::DOM::Number->isInteger(99999999999999999999999); # true

    HTML::Object::DOM::Number->isInteger(0.1);         # false
    HTML::Object::DOM::Number->isInteger(Math->PI);    # false

    HTML::Object::DOM::Number->isInteger(NaN);         # false
    HTML::Object::DOM::Number->isInteger(Infinity);    # false
    HTML::Object::DOM::Number->isInteger(-Infinity);   # false
    HTML::Object::DOM::Number->isInteger('10');        # false
    HTML::Object::DOM::Number->isInteger(true);        # false
    HTML::Object::DOM::Number->isInteger(false);       # false
    HTML::Object::DOM::Number->isInteger([1]);         # false

    HTML::Object::DOM::Number->isInteger(5.0);         # true
    HTML::Object::DOM::Number->isInteger(5.000000000000001);  # false
    HTML::Object::DOM::Number->isInteger(5.0000000000000001); # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isInteger>

=head2 isNaN

Determine whether the passed value is C<NaN>.

Example:

    HTML::Object::DOM::Number->isNaN(value)

    HTML::Object::DOM::Number->isNaN(NaN);              # true
    HTML::Object::DOM::Number->isNaN(HTML::Object::DOM::Number->NaN); # true
    HTML::Object::DOM::Number->isNaN(0 / 0);            # true

    # e->g. these would have been true with global isNaN()
    HTML::Object::DOM::Number->isNaN('NaN');            # false
    HTML::Object::DOM::Number->isNaN(undefined);        # false
    HTML::Object::DOM::Number->isNaN({});               # false
    HTML::Object::DOM::Number->isNaN('blabla');         # false

    # These all return false
    HTML::Object::DOM::Number->isNaN(true);
    HTML::Object::DOM::Number->isNaN(undef);
    HTML::Object::DOM::Number->isNaN(37);
    HTML::Object::DOM::Number->isNaN('37');
    HTML::Object::DOM::Number->isNaN('37.37');
    HTML::Object::DOM::Number->isNaN('');
    HTML::Object::DOM::Number->isNaN(' ');

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isNaN>

=head2 isSafeInteger

Determine whether the passed value is a safe integer (number between -(2^53 - 1) and 2^53 - 1).

Example:

    HTML::Object::DOM::Number->isSafeInteger(3);                     # true
    HTML::Object::DOM::Number->isSafeInteger(POSIX::pow(2, 53));     # false
    HTML::Object::DOM::Number->isSafeInteger(POSIX::pow(2, 53) - 1); # true
    HTML::Object::DOM::Number->isSafeInteger(NaN);                   # false
    HTML::Object::DOM::Number->isSafeInteger(Infinity);              # false
    HTML::Object::DOM::Number->isSafeInteger('3');                   # false
    HTML::Object::DOM::Number->isSafeInteger(3.1);                   # false
    HTML::Object::DOM::Number->isSafeInteger(3.0);                   # true

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/isSafeInteger>

=head2 parseFloat

Provided with a value and this will return a new L<HTML::Object::DOM::Number> object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseFloat>

=head2 parseInt

Provided with a value and this will return a new L<HTML::Object::DOM::Number> object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/parseInt>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number>, L<Machine::Epsilon>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
