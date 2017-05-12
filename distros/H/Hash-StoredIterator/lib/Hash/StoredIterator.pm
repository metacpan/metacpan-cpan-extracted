package Hash::StoredIterator;

use 5.010000;
use strict;
use warnings;

use base 'Exporter';
use Carp qw/croak carp/;
use B;

our @EXPORT_OK = qw{
    hmap
    eich
    eech
    iterator
    hash_get_iterator
    hash_set_iterator
    hash_init_iterator
    hkeys
    hvalues
};

our %EXPORT_TAGS = (
    'all'      => \@EXPORT_OK
);

our $VERSION = '0.008';

require XSLoader;
XSLoader::load( 'Hash::StoredIterator', $VERSION );

sub eich(\%\$) {
    carp "eich is deprecated, you should use iterator() instead";
    my ( $hash, $i_ref ) = @_;

    my $old_it = hash_get_iterator($hash);

    my ( $key, $val );

    my $success = eval {
        if ( !defined $$i_ref )
        {
            hash_init_iterator($hash);
        }
        else {
            hash_set_iterator( $hash, $$i_ref );
        }

        ( $key, $val ) = each(%$hash);

        $$i_ref = hash_get_iterator($hash);

        1;
    };

    hash_set_iterator( $hash, $old_it );
    die $@ unless $success;

    unless ( defined $key ) {
        $$i_ref = undef;
        return;
    }

    return ( $key, $val );
}

sub iterator(\%) {
    my ($hash) = @_;
    my $i = undef;

    return sub {
        my $old_it = hash_get_iterator($hash);

        my ( $key, $val );

        my $success = eval {
            if ( !defined $i ) {
                hash_init_iterator( $hash );
            }
            else {
                hash_set_iterator( $hash, $i );
            }

            ( $key, $val ) = each( %$hash );

            $i = hash_get_iterator($hash);

            1;
        };

        hash_set_iterator( $hash, $old_it );
        die $@ unless $success;

        unless ( defined $key ) {
            $i = undef;
            return;
        }

        return ( $key, $val );
    };
}

sub hmap(&\%) {
    my ( $code, $hash ) = @_;

    my $old_it = hash_get_iterator($hash);
    hash_init_iterator($hash);

    my $success = eval {
        my $iter = iterator %$hash;

        while ( my ( $k, $v ) = $iter->() ) {
            local $_ = $k;
            # Can't use caller(), subref might be from a different package than
            # eech is called from.
            my $callback_package = B::svref_2object($code)->GV->STASH->NAME;
            no strict 'refs';
            local ${"$callback_package\::a"} = $k;
            local ${"$callback_package\::b"} = $v;
            $code->( $k, $v );
        }

        1;
    };

    hash_set_iterator( $hash, $old_it );
    die $@ unless $success;
    return;
}

sub eech(&\%) {
    carp "eech is deprecated, use hmap instead";
    goto &hmap;
}

sub hkeys(\%) {
    my ($hash) = @_;
    croak "ARGH!" unless $hash;

    my $old_it = hash_get_iterator($hash);
    hash_init_iterator($hash);

    my @out = keys %$hash;

    hash_set_iterator( $hash, $old_it );

    return @out;
}

sub hvalues(\%) {
    my ($hash) = @_;

    my $old_it = hash_get_iterator($hash);
    hash_init_iterator($hash);

    my @out = values %$hash;

    hash_set_iterator( $hash, $old_it );

    return @out;
}

1;

__END__


=head1 NAME

Hash::StoredIterator - Functions for accessing a hashes internal iterator.

=head1 DESCRIPTION

In perl all hashes have an internal iterator. This iterator is used by the
C<each()> function, as well as by C<keys()> and C<values()>. Because these all
share use of the same iterator, they tend to interact badly with each other
when nested.

Hash::StoredIterator gives you access to get, set, and init the iterator inside
a hash. This allows you to store the current iterator, use
each/keys/values/etc, and then restore the iterator, this helps you to ensure
you do not interact badly with other users of the iterator.

Along with low-level get/set/init functions, there are also 2 variations of
C<each()> which let you act upon each key/value pair in a safer way than
vanilla C<each()>

This module can also export new implementations of C<keys()> and C<values()>
which stash and restore the iterator so that they are safe to use within
C<each()>.

=head1 SYNOPSIS

    use Hash::StoredIterator qw{
        hmap
        hkeys
        hvalues
        iterator
        hash_get_iterator
        hash_set_iterator
        hash_init_iterator
    };

    my %hash = map { $_ => uc( $_ )} 'a' .. 'z';

    my @keys = hkeys %hash;
    my @values = hvalues %hash;

Each section below is functionally identical.

    my $iterator = iterator %hash;
    while( my ( $k, $v ) = $i->() ) {
        print "$k: $value\n";
    }

    hmap { print "$a: $b\n" } %hash;

    hamp { print "$_: $b\n" } %hash;

    hmap {
        my ( $key, $val ) = @_;
        print "$key: $val\n";
    } %hash;

It is safe to nest calls to C<hmap()>, C<iterator()>, C<hkeys()>, and C<hvalues()>

    hmap {
        my ( $key, $val ) = @_;
        print "$key: $val\n";
        my @keys = hkeys( %hash );
    } %hash;

C<hmap()> and C<iterator()> will also properly handle calls to C<CORE::each>,
C<CORE::keys>, and C<Core::values> nested within them.

    hmap {
        my ( $key, $val ) = @_;
        print "$key: $val\n";

        # No infinite loop!
        my @keys = keys %hash;
    } %hash;

Low Level:

    hash_init_iterator( \%hash );
    my $iter = hash_get_iterator( \%hash );
    # NOTE: Never manually specify an $iter value, ALWAYS use a value from
    # hash_get_iterator.
    hash_set_iterator( \%hash, $iter );


=head1 EXPORTS

=over 4

=item my $i = iterator %hash

Get an iterator that can be used to retrieve key/value pairs.

    my $i = iterator %hash;
    while( my ($k, $v) = $i->() ) {
        ...
    }

The iterator is a coderef, so you call it like this: C<$i->()>. You can also
use the sub anywhere you would use any other coderef.

=item hmap( \&callback, %hash )

=item hmap { ... } %hash

Iterate each key/pair calling C<$callback->( $key, $value )> for each set. In
addition C<$a> and C<$_> are set to the key, and C<$b> is set to the value.
This is done primarily for convenience of matching against the key, and short
callbacks that will be cluttered by parsing C<@_> noise.

B<Note:> See caveats.

=item my @keys = hkeys( %hash )

Same as the builtin C<keys()>, except it stores and restores the iterator.

B<Note:> Overriding the builtin keys(), even locally, causes strange
interactions with other builtins. When trying to export hkeys as keys, a call
to C<sort keys %hash> would cause undef to be passed into keys() as the first
and only argument.

=item my @values = hvalues( %hash )

Same as the builtin C<values()>, except it stores and restores the iterator.

B<Note:> Overriding the builtin values(), even locally, causes strange
interactions with other builtins. When trying to export hvalues as values, a
call to C<sort values %hash> would cause undef to be passed into values() as
the first and only argument.

=item my $i = hash_get_iterator( \%hash )

Get the current iterator value.

=item hash_set_iterator( \%hash, $i )

Set the iterator value.

B<Note:> Only ever set this to the value retrieved by C<hash_get_iterator()>,
setting the iterator in any other way is untested, and may result in undefined
behavior.

=item hash_init_iterator( \%hash )

Initialize or reset the hash iterator.

=back

=head1 DEPRECATED

These have been deprecated because they were terrible names. eich was also
deprecated because it was unnatural to use.

=over 4

=item eich

use iterator() instead

=item eech

use hmap instead

=back

=head1 CAVEATS

=over 4

=item Modification of hash during iteration

Just like with the builtin C<each()> modifying the hash between calls to each
is not recommended and can result in undefined behavior. The builtin C<each()>
does allow for deleting the iterations key, however that is B<NOT> supported by
this library.

=item sort() edge case

For some reason C<[sort hkeys %hash]> and C<[sort hkeys(%hash)]> both result in
a list that has all the keys and values (and strangely not in sorted order).
However C<[sort(hkeys(%hash))]> works fine.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2013 Chad Granum

Hash-StoredIterator is free software; Standard perl licence.

Hash-StoredIterator is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the license for more details.

