package Method::Delegation;

use 5.006;
use strict;
use warnings;
use Carp;
use Sub::Install;
use base 'Exporter';
our @EXPORT  = qw(delegate);    ## no critic
our $VERSION = '0.03';

sub delegate {
    my %arg_for = @_;

    my ( $package, undef, undef ) = caller;
    my $delegate    = delete $arg_for{to};
    my $methods     = delete $arg_for{methods};
    my $args        = delete $arg_for{args};
    my $if_true     = delete $arg_for{if_true};
    my $else_return = delete $arg_for{else_return};
    my $override    = delete $arg_for{override};
    my $maybe_to    = delete $arg_for{maybe_to};

    if ( keys %arg_for ) {
        my $unknown = join ', ' => sort keys %arg_for;
        croak("Unknown keys supplied to delegate(): $unknown");
    }

    if ($maybe_to) {
        if ($delegate) {
            croak(
                "You supplied both 'maybe_to' and 'to'. I don't know which to use.");
        }
        if ($if_true) {
            croak(
"You supplied both 'maybe_to' and 'if_true'. I don't know which to use."
            );
        }
        ( $delegate, $if_true ) = ($maybe_to) x 2;
    }
    $delegate or croak("You must supply a 'to' argument to delegate()");
    $methods  or croak("You must supply a 'methods' argument to delegate()");
    $methods = _normalize_methods( $methods, $delegate );

    if ( defined $else_return && !defined $if_true ) {
        croak(
            "You must supply a 'if_true' argument if 'else_return' is defined");
    }

    _assert_valid_method_name($delegate);
    _assert_valid_method_name($if_true) if defined $if_true;

    while ( my ( $method, $to ) = each %$methods ) {
        _assert_valid_method_name($method);
        _assert_valid_method_name($to);

        my $coderef;
        if ($if_true) {
            if ($args) {
                $coderef = sub {
                    my $self = shift;
                    if ( $self->$if_true ) {
                        return $self->$delegate->$to(@_);
                    }
                    return defined $else_return ? $else_return : ();
                };
            }
            else {
                $coderef = sub {
                    my $self = shift;
                    if ( $self->$if_true ) {
                        return $self->$delegate->$to;
                    }
                    return defined $else_return ? $else_return : ();
                };
            }
        }
        else {
            if ($args) {
                $coderef = sub {
                    my $self = shift;
                    return $self->$delegate->$to(@_);
                };
            }
            else {
                $coderef = sub {
                    my $self = shift;
                    return $self->$delegate->$to;
                };
            }
        }

        {
            no strict 'refs';    ## no critic
            if ( !$override && defined *{"${package}::$method"}{CODE} ) {
                croak(
                    "Package '$package' already has a method named '$method'");
            }
        }

        _install_delegate( $coderef, $package, $method );
    }
}

sub _normalize_methods {
    my ( $methods, $delegate ) = @_;

    if ( 'ARRAY' eq ref $methods ) {
        $methods = { map { $_ => $_ } @$methods };
    }
    elsif ( !ref $methods ) {
        $methods = { $methods => $methods };
    }
    elsif ( 'HASH' ne ref $methods ) {
        croak("I don't know how to delegate to '$delegate' from '$methods'");
    }

    unless ( keys %$methods ) {
        croak("You have not provideed any methods to delegate");
    }
    return $methods;
}

sub _install_delegate {
    my ( $coderef, $package, $method ) = @_;

    Sub::Install::install_sub(
        {
            code => $coderef,
            into => $package,
            as   => $method,
        }
    );
}

sub _assert_valid_method_name {
    my $name = shift;
    if ( $name =~ /^[a-z_][a-z0-9_]*$/i ) {
        return $name;
    }
    croak("Illegal method name: '$name'");
}

1;

__END__

=head1 NAME

Method::Delegation - Easily delegate methods to another object

=head1 VERSION

Version 0.03

=cut

=head1 SYNOPSIS

    package Order;

    use Method::Delegation;
    delegate(
        methods => [qw/name customer_number/],
        to      => 'customer',
    );

=head1 EXPORT

=head2 delegate

Calling C<delegate(%args)> installs one or more methods into the current
package's namespace. These methods will delegate to the object returned by
C<to>.

Arguments to C<delegate> are as follows (examples will be after):

=over 4

=item * C<to>

This is the name of the method that, when called, returns the object we
delegate to.  It is assumed that it will I<always> return an object, unless
the I<if_true> argument is also supplied.

=item * C<maybe_to> (optional)

If the object you wish to delegate to might not exist, you can use C<maybe_to>
instead. This is a shorthand for using both C<to> and C<if_true>. Do not
provide C<to> and C<if_true> if you also provide C<maybe_to>.

=item * C<methods>

These are the names of the methods we can call and what they can delegate to.
If a scalar is supplied, this will be the name of the method of both the
calling package and the delegated package.

If an array refererence, this will contain a list of names of the method of
the both the calling package and the delegated package.

If a hash reference, the keys will be the methods of the calling package and
the values will be the names of the method of the delegated package.

=item * C<args> (optional)

By default, we assume that these delegations are read-only. If you pass
C<args> and give it a true value, the method created in the delegation will
attempt to pass your args to the method we're delegating to.

=item * C<if_true> (optional)

The name of a method to call to see if we can perform the delegation. If it
returns false, we return false. Usually this is the same name as the C<to>
argument, meaning if if the method named in C<to> does not return an object,
simply return false instead of attempting to delegate.

As a convenience, the number (or string) "1" has been special-cased to mean
the current delegate method name.

=item * C<else_return> (optional)

If C<if_true> is supplied, you may also provide C<else_return>. This must
point to a scalar value that will be returned if C<if_true> is false.

=item * C<override>

By default, we will not install a delegated method if the package already has
a method of that name. By providing a true value to C<override>, we will
install these methods anyway.

=back

=cut

=head1 EXAMPLES

=head2 Basic Usage

Delegating a single method:

    delegate(
        methods => 'name',
        to      => 'customer',
    );
    # equivalent to:
    sub name {
        my $self = shift;
        return $self->customer->name;
    }

Delegating several methods:

    delegate(
        methods => [/name rank serial_number/],
        to      => 'soldier',
    );
    # equivalent to:
    sub name {
        my $self = shift;
        return $self->soldier->name;
    }
    sub rank {
        my $self = shift;
        return $self->soldier->rank;
    }
    sub serial_number {
        my $self = shift;
        return $self->soldier->serial_number;
    }

Delegating, but renaming a method:

    delegate(
        methods => {
            customer_name   => 'name',
            customer_number => 'number,
        },
        to => 'customer',
    );
    # equivalent to:
    sub customer_name {
        my $self = shift;
        return $self->customer->name;
    }
    sub customer_number {
        my $self = shift;
        return $self->customer->number;
    }

=head2 Advanced Usage

Delegating to an object that might not exist is sometimes necessary. For
example, in L<DBIx::Class>, you might have an atttribute pointing to a
relationship with no corresponding entry in another table. Use C<if_true> for
that:

    delegate(
        methods => 'current_ship',
        to      => 'character_ship',
        if_true => 'character_ship',
    );
    # equivalent to:
    sub current_ship {
        my $self = shift;
        if ( $self->character_ship ) {
            return $self->character_ship;
        }
        return;
    }

As an optimization for the common case, you can use C<maybe_to> if the object
you're delegating to might not exist.

    delegate(
        methods  => 'current_ship',
        maybe_to => 'character_ship',
    );

Note: the C<if_true> attribute doesn't need to point to the same method, but
usually it does. If it points to another method, it simply checks the truth
value of the response to determine if the original delegate will be called.

Sometimes, if the object you're delegating to another object, you want a
different value than C<undef> being returned if the object isn't there. Use
the C<else_return> attribute. The following will return C<0> (zero) instead of
undef if C<current_weapon> isn't found:

    delegate(
        methods => {
            weapon_damage   => 'damage',
            weapon_accurace => 'accuracy',
        },
        to          => 'current_weapon',
        if_true     => 'current_weapon',
        else_return => 0,
    );

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <curtis.poe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature fequests via the Web interface at
L<https://github.com/Ovid/method-delegation/issues>.  I will be notified, and
then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Method::Delegation

You can also look for information at:

=over 4

=item * Bug Tracker

L<https://github.com/Ovid/method-delegation/issues>

=item * Search CPAN

L<https://metacpan.org/release/Method-Delegation>

=back

=head1 SEE ALSO

C<Method::Delegation> was developed for the narrative sci-fi game L<Tau
Station|https://taustation.space>. We like it because the syntax is simple,
clear, and intuitive (to us). However, there are a few alternatives on the
CPAN that you might find useful:

=over 4

=item * L<Class::Delegation|https://metacpan.org/pod/Class::Delegation>

=item * L<Class::Delegation::Simple|https://metacpan.org/pod/Class::Delegation::Simple>

=item * L<Class::Delegate|https://metacpan.org/pod/Class::Delegate>

=item * L<Class::Method::Delegate|https://metacpan.org/pod/Class::Method::Delegate>

=back

=head1 ACKNOWLEDGEMENTS

This code was written to help reduce the complexity of the narrative sci-fi
adventure, L<Tau Station|https://taustation.space>. As of this writing, it's
around 1/3 of a million lines of code (counting front-end, back-end, tests,
etc.), and anything to reduce that complexity is a huge win.

Thanks to L<ilmari|https://twitter.com/TokenScandi/status/1135533624110047234>
for the C<< if_true => 1 >> shortcut suggestion.

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
