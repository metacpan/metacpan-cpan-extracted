package IO::Handle::Util;

use strict;
use warnings;

our $VERSION = "0.01";
$VERSION = eval $VERSION;


use warnings::register;

use Scalar::Util ();

# we use this to create errors
#use autodie ();

# perl blesses IO objects into these namespaces, make sure they are loaded
use IO::Handle ();
use FileHandle ();

# fake handle types
#use IO::String ();
#use IO::Handle::Iterator ();

#use IO::Handle::Prototype::Fallback ();

use Sub::Exporter -setup => {
    exports => [qw(
            io_to_write_cb
            io_to_read_cb
            io_to_string
            io_to_array
            io_to_list
            io_to_glob

            io_from_any
            io_from_ref
            io_from_string
            io_from_object
            io_from_array
            io_from_scalar_ref
            io_from_thunk
            io_from_getline
            io_from_write_cb
            io_prototype

            is_real_fh
    )],
    groups => {
        io_to => [qw(
            io_to_write_cb
            io_to_read_cb
            io_to_string
            io_to_array
            io_to_list
            io_to_glob
        )],

        io_from => [qw(
            io_from_any
            io_from_ref
            io_from_string
            io_from_object
            io_from_array
            io_from_scalar_ref
            io_from_thunk
            io_from_getline
            io_from_write_cb
        )],

        coercion => [qw(
            :io_to
            :io_from
        )],

        misc => [qw(
            io_prototype
            is_real_fh
        )],
    },
};

sub io_to_write_cb ($) {
    my $fh = io_from_any(shift);

    return sub {
        local $,;
        local $\;
        $fh->print(@_) or do {
            my $e = $!;
            require autodie;
            die autodie::exception->new(
                function => q{CORE::print}, args => [@_],
                message => "\$E", errno => $e,
            );
        }
    }
}

sub io_to_read_cb ($) {
    my $fh = io_from_any(shift);

    return sub { scalar $fh->getline() };
}

sub io_to_string ($) {
    my $thing = shift;

    if ( defined $thing and not ref $thing ) {
        return $thing;
    } else {
        my $fh = io_from_any($thing);

        # list context is in case ->getline ignores $/,
        # which is likely the case with ::Iterator
        local $/;
        return join "", <$fh>;
    }
}

sub io_to_list ($) {
    my $thing = shift;

    warnings::warnif(__PACKAGE__, "io_to_list not invoked in list context")
        unless wantarray;

    if ( ref $thing eq 'ARRAY' ) {
        return @$thing;
    } else {
        my $fh = io_from_any($thing);
        return <$fh>;
    }
}

sub io_to_array ($) {
    my $thing = shift;

    if ( ref $thing eq 'ARRAY' ) {
        return $thing;
    } else {
        my $fh = io_from_any($thing);

        return [ <$fh> ];
    }
}

sub io_to_glob {
    my $thing = shift;

    my $fh = io_from_any($thing);

    if ( ref($fh) eq 'GLOB' or ref($fh) eq 'IO::Handle' ) {
        return $fh;
    } else {
        # wrap in a tied handle
        my $glob = Symbol::gensym();

        require IO::Handle::Util::Tie;
        tie *$glob, 'IO::Handle::Util::Tie', $fh;

        return $glob;
    }
}

sub io_from_any ($) {
    my $thing = shift;

    if ( ref $thing ) {
        return io_from_ref($thing);
    } else {
        return io_from_string($thing);
    }
}

sub io_from_ref ($) {
    my $ref = shift;

    if ( Scalar::Util::blessed($ref) ) {
        return io_from_object($ref);
    } elsif ( ref $ref eq 'GLOB' and *{$ref}{IO}) {
        # once IO::Handle is required, entersub DWIMs method invoked on globs
        # there is no need to bless or IO::Wrap if there's a valid IO slot
        return $ref;
    } elsif ( ref $ref eq 'ARRAY' ) {
        return io_from_array($ref);
    } elsif ( ref $ref eq 'SCALAR' ) {
        return io_from_scalar_ref($ref);
    } elsif ( ref $ref eq 'CODE' ) {
        Carp::croak("Coercing an IO object from a coderef is ambiguous. Please use io_from_thunk, io_from_getline or io_from_write_cb directly.");
    } else {
        Carp::croak("Don't know how to make an IO from $ref");
    }
}

sub io_from_object ($) {
    my $obj = shift;

    if ( $obj->isa("IO::Handle") or $obj->can("getline") && $obj->can("print") ) {
        return $obj;
    } elsif ( $obj->isa("Path::Class::File") ) {
        return $obj->openr; # safe default or open for rw?
    } else {
        # FIXME URI? IO::File? IO::Scalar, IO::String etc? make sure they all pass
        Carp::croak("Object does not seem to be an IO::Handle lookalike");
    }
}

sub io_from_string ($) {
    my $string = shift; # make sure it's a copy, IO::String will use \$_[0]
    require IO::String;
    return IO::String->new($string);
}

sub io_from_array ($) {
    my $array = shift;

    my @array = @$array;

    require IO::Handle::Iterator;

    # IO::Lines/IO::ScalarArray is part of IO::stringy which is considered bad.
    IO::Handle::Iterator->new(sub {
        if ( @array ) {
            return shift @array;
        } else {
            return;
        }
    });
}

sub io_from_scalar_ref ($) {
    my $ref = shift;
    require IO::String;
    return IO::String->new($ref);
}

sub io_from_thunk ($) {
    my $thunk = shift;

    my @lines;

    require IO::Handle::Iterator;

    return IO::Handle::Iterator->new(sub {
        if ( $thunk ) {
            @lines = $thunk->();
            undef $thunk;
        }

        if ( @lines ) {
            return shift @lines;
        } else {
            return;
        }
    });
}

sub io_from_getline ($) {
    my $cb = shift;

    require IO::Handle::Iterator;

    return IO::Handle::Iterator->new($cb);
}

sub io_from_write_cb ($) {
    my $cb = shift;

    io_prototype( __write => sub {
        local $,;
        local $\;
        $cb->($_[1]);
    } );
}

sub io_prototype {
    require IO::Handle::Prototype::Fallback;
    IO::Handle::Prototype::Fallback->new(@_);
}

# returns true if the handle is (hopefully) suitable for passing to things that
# want to do non method operations on it, including operations that need a
# proper file descriptor
sub is_real_fh ($) {
    my $fh = shift;

    my $reftype = Scalar::Util::reftype($fh);

    if (   $reftype eq 'IO'
        or $reftype eq 'GLOB' && *{$fh}{IO}
    ) {
        # if it's a blessed glob make sure to not break encapsulation with
        # fileno($fh) (e.g. if you are filtering output then file descriptor
        # based operations might no longer be valid).
        # then ensure that the fileno *opcode* agrees too, that there is a
        # valid IO object inside $fh either directly or indirectly and that it
        # corresponds to a real file descriptor.

        my $m_fileno = $fh->fileno;

        return '' unless defined $m_fileno;
        return '' unless $m_fileno >= 0;

        my $f_fileno = fileno($fh);

        return '' unless defined $f_fileno;
        return '' unless $f_fileno >= 0;

        return 1;
    } else {
        # anything else, including GLOBS without IO (even if they are blessed)
        # and non GLOB objects that look like filehandle objects cannot have a
        # valid file descriptor in fileno($fh) context so may break.
        return '';
    }
}

__PACKAGE__

# ex: set sw=4 et:

__END__

=pod

=head1 NAME

IO::Handle::Util - Functions for working with L<IO::Handle> like objects.

=head1 SYNOPSIS

    # make something that looks like a filehandle from a random data:
    my $io = io_from_any $some_data;

    # or from a callback that returns strings:
    my $io = io_from_getline sub { return $another_line };

    # create a callback that iterates through the handle
    my $read_cb = io_to_read_cb $io;

=head1 DESCRIPTION

This module provides a number of helpful routines to manipulate or create
L<IO::Handle> like objects.

=head1 EXPORTS

=head2 Coercions resulting in IO objects

These are available using the C<:io_from> export group.

=over 4

=item io_from_any $whatever

Inspects the value of C<whatever> and calls the appropriate coercion function
on it, either C<io_from_ref> or C<io_from_string>.

=item io_from_ref $some_ref

Depending on the reference type of C<$some_ref> invokes either
C<io_from_object>, C<io_from_array> or C<io_from_scalar_ref>.

Code references are not coerced automatically because either C<io_from_thunk>
or C<io_from_getline> or C<io_from_write_cb> could all make sense.

Globs are returned as is B<only> if they have a valid C<IO> slot.

=item io_from_object $obj

Depending on the class of C<$obj> either returns or coerces the object.

Objects that are passed through include anything that subclasses L<IO::Handle>
or seems to duck type (supports the C<print> and C<getline> methods, which
might be a bit too permissive).

Objects that are coerced currently only include L<Path::Class::File>, which
will have the C<openr> method invoked on it.

Anything else is an error.

=over 4

=item io_from_string $str

Instantiates an L<IO::String> object using C<$str> as the buffer.

Note that C<$str> is B<not> passed as an alias, so writing to the IO object
will not modify string. For that see C<io_from_scalar_ref>.

=item io_from_array \@array

Creates an L<IO::Handle::Iterator> that will return the elements of C<@array>
one by one.

Note that a I<copy> of C<@array> is made.

In order to be able to append more elements to the array or remove the ones
that have been returned use L<IO::Handle::Iterator> yourself directly.

=item io_from_scalar_ref \$str

Creates an L<IO::String> object using C<$str> as the buffer.

Writing to the IO object will modify C<$str>.

=item io_from_thunk sub { ... }

Invokes the callback once in list context the first time it's needed, and then
returns each element of the list like C<io_from_array> would.

=item io_from_getline sub { ... }

Creates an L<IO::Handle::Iterator> object using the callback.

=item io_from_write_cb sub { ... }

Creates an L<IO::Handle::Prototype::Fallback> using the callback.

The callback will always be invoked with one string argument and with the
values of C<$,> and C<$\> localized to C<undef>.

=back

=head2 Coercions utilizing IO objects

These coercions will actually call C<io_from_any> on their argument first. This
allows you to do things like:

    my $str = '';
    my $sub = io_to_write_cb(\$str);

    $sub->("foo");

These are available using the C<:io_to> export group.

=over 4

=item io_to_write_cb $thing

Creates a code ref that will invoke C<print> on the handle with the arguments
to the callback.

C<$,> and C<$\> will both be localized to C<undef>.

=item io_to_read_cb $thing

Creates a code ref that will invoke C<getline> on the handle.

C<$/> will not be localized and should probably be set to a reference to a
number if you want efficient iteration. See L<perlvar> for details.

=item io_to_string $thing

Slurps a string out of the IO object by reading all the data.

If a string was passed it is returned as is.

=item io_to_array $thing

Returns an array reference containing all the lines of the IO object.

If an array reference was passed it is returned as is.

=item io_to_list $thing

Returns the list of lines from the IO object.

Warns if not invoked in list context.

If an array reference was passed it is dereferenced an its elements are
returned.

=item io_to_glob $thing

If the filehandle is an unblessed glob returns it as is, otherwise returns a
new glob which is tied to delegate to the OO interface.

This lets you use most of the builtins without the method syntax:

    my $fh = io_to_glob($some_kind_of_OO_handle);

    while ( defined( my $line = <$fh> ) ) {
        ...
    }

=back

=head2 Misc functions

=over 4

=item io_prototype %callbacks

Given a key-value pair list of named callbacks, constructs an
L<IO::Handle::Prototype::Fallback> object with those callbacks.

For example:

    my $io = io_prototype print => sub {
        my $self = shift;

        no warnings 'uninitialized';
        $string .= join($,, @_) . $\;
    };

    $io->say("Hello"); # $string now has "Hello\n"

See L<IO::Handle::Prototype::Fallback> for more details.

=item is_real_fh $io

Returns true if the IO handle probably could be passed to something like
L<AnyEvent::Handle> which would break encapsulation.

Checks for the following conditions:

=over 4

=item *

The handle has a reftype of either a C<GLOB> with an C<IO> slot, or is an C<IO>
itself.

=item *

The handle's C<fileno> method returns a positive number, corresponding to a
filedescriptor.

=item *

The C<fileno> builtin returns the same thing as C<fileno> invoked as a method.

=back

If these conditions hold the handle is I<probably> OK to work with using the IO
builtins directly, or passing the filedesctiptor to C land, instead of by
invoking methods on it.

=back

=head1 SEE ALSO

L<IO::Handle>, L<FileHandle>, L<IO::String>, L<perlio>, L<perlfunc/open>

=head1 VERSION CONTROL

L<http://github.com/nothingmuch/io-handle-util>

=head1 AUTHOR

Yuval Kogman

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2009 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
