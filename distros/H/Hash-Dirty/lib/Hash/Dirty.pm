package Hash::Dirty;

use warnings;
use strict;

=head1 NAME

Hash::Dirty - Keep track of whether a hash is dirty or not

=head1 VERSION

Version 0.023

=cut

our $VERSION = '0.023';

=head1 SYNOPSIS

    use Hash::Dirty;

    my %hash;
    tie %hash, qw/Hash::Dirty/, { a => 1 };

    (tied %hash)->is_dirty; # Nope, not dirty yet.

    $hash{a} = 1;
    (tied %hash)->is_dirty; # Still not dirty yet.

    $hash{b} = 2;
    (tied %hash)->is_dirty; # Yes, now it's dirty

    (tied %hash)->dirty_keys; # ( b )

    $hash{a} = "hello";
    (tied %hash)->dirty_keys; # ( a, b )

    (tied %hash)->dirty_values; # ( "hello", 2 )

    (tied %hash)->dirty } # { a => 1, b => 1 }

    (tied %hash)->reset;
    (tied %hash)->is_dirty; # Nope, not dirty anymore.

    $hash{c} = 3;
    (tied %hash)->is_dirty; # Yes, dirty again.

    # %hash is { a => "hello", b => 2, c => 3 }
    (tied %hash)->dirty_slice } # { c => 3 }

    # Alternately:

    use Hash::Dirty;

    my $hash = Hash::Dirty::hash;

    # Also:
    
    my ($object, $hash) = Hash::Dirty->new;
    
    $hash->{a} = 1; # Etc., etc.
    $object->is_dirty;

=head1 DESCRIPTION

Hash::Dirty will keep track of the dirty keys in a hash, letting you which values changed.

Currently, Hash::Dirty will only inspect a hash shallowly, that is, it does not deeply compare
the contents of supplied values (say a HASH reference, ARRAY reference, or some other opaque object).

This module was inspired by DBIx::Class::Row

Currently, setting, deleting keys or clearing the hash means that the object will lose history, so it will know
that something has changed, but not if it is reset back at some later date:

    my ($object, $hash) = Hash::Dirty->new({ a => 1 });
    $object->is_dirty; # Nope

    $hash->{a} = 2;
    $object->is_dirty; # Yup
    
    $hash->{a} = 1;
    $object->is_dirty; # Yup, still dirty, even though the original value was 1

=cut

use Scalar::Util qw/weaken/;
use Sub::Exporter -setup => {
    exports => [
        hash => sub { return sub {
            my ($object, $hash) = __PACKAGE__->new(@_);
            return $hash;
        } },
    ],
};
use Tie::Hash;

use base qw/Tie::ExtraHash/;

=head1 EXPORTS

=head2 hash( <hash> )

Creates a new Hash::Dirty object and returns the tied hash reference, per Hash::Dirty->new.

If supplied, will use <hash> as the storage (initializing the object accordingly)

=cut

use constant STORAGE => 0;
use constant DIRTY => 1;
use constant HASH => 2;

sub TIEHASH {
    my ($class, $storage) = @_;
    $storage ||= {};
    my $self = [];
    $self->[STORAGE()] = $storage;
    $self->[DIRTY()] = {};
    return bless $self, $class;
}

=head1 METHODS 

=cut

=head2 Hash::Dirty->new( <hash> )

Creates and returns a new Hash::Dirty object

If supplied, will use <hash> as the storage (initializing the object accordingly)

In list context, new will return both the object and the "regular" hash:

    my ($object, $hash) = Hash::Dirty->new;
    $hash->{a} = 1;
    $object->is_dirty; # Yup, it's dirty

=cut

sub new {
    my $class = shift;
    my %hash;
    my $self = tie %hash, $class, @_;
    my $hash = \%hash;
    $self->[HASH()] = $hash;
    weaken $self->[HASH()];
    return wantarray ? ($self, \%hash) : $self;
}

=head2 $object->hash

Returns a reference to the overlying hash 

=cut

sub hash {
    my $self = shift;
    return $self->[HASH()];
}

=head2 $object->is_dirty

Returns 1 if the hash is dirty at all, 0 otherwise 

=head2 $object->is_dirty ( <key> )

Returns 1 if <key> is dirty, 0 otherwise

=head2 $object->is_dirty ( $key, $key, ..., )

Returns 1 if any <key> is dirty, 0 otherwise

=cut

sub is_dirty {
    my $self = shift; 
    if (@_) {
        for my $key (@_) {
            return 1 if exists $self->[DIRTY()]->{$key};
        }
    }
    else {
        return 1 if $self->dirty_keys;
    }
    return 0;
}

=head2 $object->reset

Resets the hash to non-dirty status

This method affects the dirtiness only, it does not erase or alter the hash in anyway

=cut

sub reset {
    my $self = shift; 
    $self->[DIRTY()] = {};
}

=head2 $object->dirty

Returns a hash indicating which keys are dirty

In scalar context, returns a hash reference

=cut

sub dirty {
    my $self = shift; 
    my %dirty = %{ $self->[DIRTY()] };
    return wantarray ? %dirty : \%dirty;
}

sub _storage {
    my $self = shift; 
    my %storage = %{ $self->[STORAGE()] };
    return wantarray ? %storage : \%storage;
}

=head2 $object->dirty_slice

Returns a hash slice containg only the dirty keys and values

In scalar context, returns a hash reference

=cut

sub dirty_slice {
    my $self = shift; 
    my %slice = map { $_ => $self->[STORAGE()]{$_} } $self->dirty_keys;
    return wantarray? %slice : \%slice;
}

=head2 $object->dirty_keys

Returns a list of dirty keys

=cut

sub dirty_keys {
    my $self = shift; 
    return keys %{ $self->[DIRTY()] };
}

=head2 $object->dirty_values

Returns a list of dirty values

=cut

sub dirty_values {
    my $self = shift; 
    return map { $self->[STORAGE()]{$_} } $self->dirty_keys;
}

sub STORE {
    my ($self, $key, $value) = @_;

    my $storage = $self->[STORAGE()];
    my $new = $value;
    my $old = $storage->{$key};
    $storage->{$key} = $new;
    # Taken from DBIx::Class::Row::set_column
    $self->[DIRTY()]{$key} = 1 if (defined $old ^ defined $new) || (defined $old && $old ne $new);
    return $new;
}

=head2 $object->set( <key>, <value> )

=head2 $object->store( <key>, <value> )

=cut

*set = \&STORE;
*store = \&STORE;

=head2 $object->get( <key> )

=head2 $object->fetch( <key> )

=cut

*get = \&Tie::ExtraHash::FETCH;
*fetch = \&Tie::ExtraHash::FETCH;

sub CLEAR {
    my $self = shift;

    my $storage = $self->[STORAGE()];
    $self->[DIRTY()]{$_} = 1 for keys %$storage;
    %$storage = ();
}

=head2 $object->clear

=cut

*clear = \&Tie::ExtraHash::CLEAR;

sub DELETE {
    my ($self, $key) = @_;

    my $storage = $self->[STORAGE()];
    $self->[DIRTY()]{$key} = 1 if exists $storage->{$key};
    return delete $storage->{$key};
}

=head2 $object->delete( <key> )

=cut

*delete = \&Tie::ExtraHash::DELETE;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-hash-dirty at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Hash-Dirty>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Hash::Dirty

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Hash-Dirty>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Hash-Dirty>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Hash-Dirty>

=item * Search CPAN

L<http://search.cpan.org/dist/Hash-Dirty>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Hash::Dirty
