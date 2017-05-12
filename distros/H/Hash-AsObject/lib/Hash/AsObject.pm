package Hash::AsObject;

use strict;
use vars qw($VERSION $AUTOLOAD);

$VERSION = '0.13';

sub VERSION {
    return $VERSION
        unless ref($_[0]);
    scalar @_ > 1 ? $_[0]->{'VERSION'} = $_[1] : $_[0]->{'VERSION'};
}

sub can {
    # $obj->can($method)
    # $cls->can($method)
    die "Usage: UNIVERSAL::can(object-ref, method)"
        unless @_ == 2;
    my ($invocant, $method) = @_;
    # --- Define a stub method in this package (to speed up later invocations)
    my $cls = ref($invocant) || $invocant;
    no strict 'refs';
    return sub {
        my $v;
        if (scalar @_ > 1) {
            $v = $_[0]->{$method} = $_[1];
            return undef unless defined $v;
        }
        else {
            $v = $_[0]->{$method};
        }
        if (ref($v) eq 'HASH') {
            bless $v, $cls;
        }
        else {
            $v;
        }

    };
}

sub import {
    return
        unless ref($_[0]);
    scalar @_ > 1 ? $_[0]->{'import'} = $_[1] : $_[0]->{'import'};
}

sub AUTOLOAD {
    my $invocant = shift;
    my $key = $AUTOLOAD;

    # --- Figure out which hash element we're dealing with
    if (defined $key) {
        $key =~ s/.*:://;
    }
    else {
        # --- Someone called $obj->AUTOLOAD -- OK, that's fine, be cool
        # --- Or they might have called $cls->AUTOLOAD, but we'll catch
        #     that below
        $key = 'AUTOLOAD';
    }
    
    # --- We don't need $AUTOLOAD any more, and we need to make sure
    #     it isn't defined in case the next call is $obj->AUTOLOAD
    #     (why the %*@!? doesn't Perl undef this automatically for us
    #     when execution of this sub ends?)
    undef $AUTOLOAD;
    
    # --- Handle special cases: class method invocations, DESTROY, etc.
    if (ref($invocant) eq '') {
        # --- Class method invocation
        if ($key eq 'import') {
            # --- Ignore $cls->import
            return;
        } elsif ($key eq 'new') {
            # --- Constructor
            my $elems =
                scalar(@_) == 1
                    ? shift   # $cls->new({ foo => $bar, ... })
                    : { @_ }  # $cls->new(  foo => $bar, ...  )
                    ;
            return bless $elems, $invocant;
        }
        else {
            # --- All other class methods disallowed
            die "Can't invoke class method '$key' on a Hash::AsObject object";
        }
    } elsif ($key eq 'DESTROY') {
        # --- This is tricky.  There are four distinct cases:
        #       (1) $invocant->DESTROY($val)
        #       (2) $invocant->DESTROY()
        #           (2a) $invocant->{DESTROY} exists and is defined
        #           (2b) $invocant->{DESTROY} exists but is undefined
        #           (2c) $invocant->{DESTROY} doesn't exist
        #     Case 1 will never happen automatically, so we handle it normally
        #     In case 2a, we must return the value of $invocant->{DESTROY} but not
        #       define a method Hash::AsObject::DESTROY
        #     The same is true in case 2b, it's just that the value is undefined
        #     Since we're striving for perfect emulation of hash access, case 2c
        #       must act just like case 2b.
        return $invocant->{'DESTROY'}          # Case 2c -- autovivify
        unless
            scalar @_                      # Case 1
            or exists $invocant->{'DESTROY'};  # Case 2a or 2b
    }
    
    # --- Handle the most common case (by far)...
    
    # --- All calls like $obj->foo(1, 2) must fail spectacularly
    die "Too many arguments"
        if scalar(@_) > 1;  # We've already shift()ed $invocant off of @_
    
    # --- If someone's called $obj->AUTOLOAD
    if ($key eq 'AUTOLOAD') {
        # --- Tread carefully -- we can't (re)define &Hash::AsObject::AUTOLOAD
        #     because that would ruin everything
        return scalar(@_) ? $invocant->{'AUTOLOAD'} = shift : $invocant->{'AUTOLOAD'};
    }
    else {
        my $cls = ref($invocant) || $invocant;
        no strict 'refs';
        *{ "${cls}::$key" } = sub {
            my $v;
            if (scalar @_ > 1) {
                $v = $_[0]->{$key} = $_[1];
                return undef unless defined $v;
            }
            else {
                $v = $_[0]->{$key};
            }
            if (ref($v) eq 'HASH') {
                bless $v, $cls;
            }
            else {
                $v;
            }

        };
        unshift @_, $invocant;
        goto &{ "${cls}::$key" };
    }
}


1;


=head1 NAME

Hash::AsObject - treat hashes as objects, with arbitrary accessors/mutators

=head1 SYNOPSIS

    $h = Hash::AsObject->new;
    $h->foo(123);
    print $h->foo;       # prints 123
    print $h->{'foo'};   # prints 123
    $h->{'bar'}{'baz'} = 456;
    print $h->bar->baz;  # prints 456

=head1 DESCRIPTION

A Hash::AsObject is a blessed hash that provides read-write
access to its elements using accessors.  (Actually, they're both accessors
and mutators.)

It's designed to act as much like a plain hash as possible; this means, for
example, that you can use methods like C<DESTROY> to get or set hash elements
with that name.  See below for more information.

=head1 METHODS

The whole point of this module is to provide arbitrary methods.  For the most
part, these are defined at runtime by a specially written C<AUTOLOAD> function.

In order to behave properly in all cases, however, a number of special methods
and functions must be supported.  Some of these are defined while others are
simply emulated in AUTOLOAD.

=over 4

=item B<new>

    $h = Hash::AsObject->new;
    $h = Hash::AsObject->new(\%some_hash);
    $h = Hash::AsObject->new(%some_other_hash);

Create a new L<Hash::AsObject|Hash::AsObject>.

If called as an instance method, this accesses a hash element 'new':

    $h->{'new'} = 123;
    $h->new;       # 123
    $h->new(456);  # 456

=item B<isa>

This method cannot be used to access a hash element 'isa', because
Hash::AsObject doesn't attempt to handle it specially.

=item B<can>

Similarly, this can't be used to access a hash element 'can'.

=item B<AUTOLOAD>

    $h->{'AUTOLOAD'} = 'abc';
    $h->AUTOLOAD;       # 'abc'
    $h->AUTOLOAD('xyz') # 'xyz'

Hash::AsObject::AUTOLOAD recognizes when AUTOLOAD is begin called as an
instance method, and treats this as an attempt to get or set the 'AUTOLOAD'
hash element.

=item B<DESTROY>

    $h->{'DESTROY'} = [];
    $h->DESTROY;    # []
    $h->DESTROY({}) # {}

C<DESTROY> is called automatically by the Perl runtime when an object goes out
of scope.  A Hash::AsObject can't distinguish this from a call to access the
element $h->{'DESTROY'}, and so it blithely gets (or sets) the hash's 'DESTROY'
element; this isn't a problem, since the Perl interpreter discards any value
that DESTROY returns when called automatically.

=item B<VERSION>

When called as a class method, this returns C<$Hash::AsObject::VERSION>; when
called as an instance method, it gets or sets the hash element 'VERSION';

=item B<import>

Since L<Hash::AsObject|Hash::AsObject> doesn't export any symbols, this method
has no special significance and you can safely call it as a method to get or
set an 'import' element.

When called as a class method, nothing happens.

=back

The methods C<can()> and C<isa()> are special, because they're defined in the
C<UNIVERSAL> class that all packages automatically inherit from.  Unfortunately,
this means that you can't use L<Hash::AsObject|Hash::AsObject> to access elements
'can' and 'isa'.

=head1 CAVEATS

No distinction is made between non-existent elements and those that are
present but undefined.  Furthermore, there's no way to delete an
element without resorting to C<< delete $h->{'foo'} >>.

Storing a hash directly into an element of a Hash::AsObject
instance has the effect of blessing that hash into
Hash::AsObject.

For example, the following code:

    my $h = Hash::AsObject->new;
    my $foo = { 'bar' => 1, 'baz' => 2 };
    print ref($foo), "\n";
    $h->foo($foo);
    print ref($foo), "\n";

Produces the following output:

    HASH
    Hash::AsObject

I could fix this, but then code like the following would throw an exception,
because C<< $h->foo($foo) >> will return a plain hash reference, not
an object:

    $h->foo($foo)->bar;

Well, I can make C<< $h->foo($foo)->bar >> work, but then code like
this won't have the desired effect:

    my $foo = { 'bar' => 123 };
    $h->foo($foo);
    $h->foo->bar(456);
    print $foo->{'bar'};  # prints 123
    print $h->foo->bar;   # prints 456

I suppose I could fix I<that>, but that's an awful lot of work for little
apparent benefit.

Let me know if you have any thoughts on this.

=head1 BUGS

Autovivification is probably not emulated correctly.

The blessing of hashes stored in a Hash::AsObject might be
considered a bug.  Or a feature; it depends on your point of view.

=head1 TO DO

=over 4

=item *

Add the capability to delete elements, perhaps like this:

    use Hash::AsObject 'deleter' => 'kill';
    $h = Hash::AsObject->new({'one' => 1, 'two' => 2});
    kill $h, 'one';

That might seem to violate the prohibition against exporting functions
from object-oriented packages, but then technically it wouldn't be
exporting it B<from> anywhere since the function would be constructed
by hand.  Alternatively, it could work like this:

    use Hash::AsObject 'deleter' => 'kill';
    $h = Hash::AsObject->new({'one' => 1, 'two' => 2});
    $h->kill('one');

But, again, what if the hash contained an element named 'kill'?

=item *

Define multiple classes in C<Hash/AsObject.pm>?  For example, there
could be one package for read-only access to a hash, one for hashes
that throw exceptions when accessors for non-existent keys are called,
etc.  But this is hard to do fully without (a) altering the underlying
hash, or (b) defining methods besides AUTOLOAD. Hmmm...

=back

=head1 VERSION

0.06

=head1 AUTHOR

Paul Hoffman <nkuitse AT cpan DOT org>

=head1 CREDITS

Andy Wardley for L<Template::Stash|Template::Stash>, which was my
inspiration.  Writing template code like this:

    [% foo.bar.baz(qux) %]

Made me yearn to write Perl code like this:

    foo->bar->baz($qux);

=head1 COPYRIGHT

Copyright 2003-2007 Paul M. Hoffman. All rights reserved.

This program is free software; you can redistribute it
and modify it under the same terms as Perl itself. 

