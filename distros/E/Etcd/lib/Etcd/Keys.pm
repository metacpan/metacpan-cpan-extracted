package Etcd::Keys;
$Etcd::Keys::VERSION = '0.004';
use namespace::autoclean;

use Etcd::Response;
use Try::Tiny;
use Scalar::Util qw(blessed);
use Carp qw(croak);

use Moo::Role;
use Types::Standard qw(Str);

requires qw(version_prefix api_exec);

has _keys_endpoint => ( is => 'lazy', isa => Str );
sub _build__keys_endpoint {
    shift->version_prefix . '/keys';
}

sub set {
    my ($self, $key, $value, %args) = @_;
    croak 'usage: $etcd->set($key, $value, [%args])' if grep { !defined } ($key, $value);
    Etcd::Response->new_from_http($self->api_exec($self->_keys_endpoint.$key, 'PUT', %args, value => $value));
}

sub get {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->get($key, [%args])' if !defined $key;
    Etcd::Response->new_from_http($self->api_exec($self->_keys_endpoint.$key, 'GET', %args));
}

sub delete {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->delete($key, [%args])' if !defined $key;
    Etcd::Response->new_from_http($self->api_exec($self->_keys_endpoint.$key, 'DELETE', %args));
}

sub compare_and_swap {
    my ($self, $key, $value, $prev_value, %args) = @_;
    croak 'usage: $etcd->compare_and_swap($key, $value, $prev_value, [%args])' if grep { !defined } ($key, $value, $prev_value);
    $self->set($key, $value, %args, prevValue => $prev_value);
}

sub compare_and_delete {
    my ($self, $key, $prev_value, %args) = @_;
    croak 'usage: $etcd->compare_and_delete($key, $prev_value, [%args])' if grep { !defined } ($key, $prev_value);
    $self->delete($key, %args, prevValue => $prev_value);
}

sub create {
    my ($self, $key, $value, %args) = @_;
    croak 'usage: $etcd->create($key, $value, [%args])' if grep { !defined } ($key, $value);
    $self->set($key, $value, %args, prevExist => 'false');
}

sub update {
    my ($self, $key, $value, %args) = @_;
    croak 'usage: $etcd->update($key, $value, [%args])' if grep { !defined } ($key, $value);
    $self->set($key, $value, %args, prevExist => 'true');
}

sub exists {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->exists($key, [%args])' if !defined $key;
    try {
        $self->get($key, %args);
        1;
    }
    catch {
        die $_ unless defined blessed $_ && $_->isa('Etcd::Error');
        die $_ unless $_->error_code == 100;
        "";
    }
}

sub create_dir {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->create_dir($key, [%args])' if !defined $key;
    Etcd::Response->new_from_http($self->api_exec($self->_keys_endpoint.$key, 'PUT', %args, dir => 'true'));
}

sub delete_dir {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->delete_dir($key, [%args])' if !defined $key;
    $self->delete($key, %args, dir => 'true');
}

sub create_in_order {
    my ($self, $key, $value, %args) = @_;
    croak 'usage: $etcd->create_in_order($key, $value, [%args])' if grep { !defined } ($key, $value);
    Etcd::Response->new_from_http($self->api_exec($self->_keys_endpoint.$key, 'POST', %args, value => $value));
}

sub watch {
    my ($self, $key, %args) = @_;
    croak 'usage: $etcd->watch($key, [%args])' if !defined $key;
    $self->get($key, %args, wait => 'true');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Etcd::Keys - etcd key space API

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    use Etcd;
    my $etcd = Etcd->new;
    
    # set value for key
    $etcd->set("/message", "hello world");
    
    # get key
    my $response = $etcd->get("/message");
    
    # delete key
    $etcd->delete("/message");
    
    # atomic compare-and-swap value for key
    $etcd->compare_and_swap("/message", "new", "old");
    
    # atomic compare-and-delete key
    $etcd->compare_and_delete("/message", "old");
    
    # create key. like set, but fails if the key exists
    $etcd->create("/message", "value");
    
    # update key. like set, but fails if the key doesn't exist
    $etcd->update("/message", "value");
    
    # check if key exists
    my $exists = $etcd->exists("/message");
    
    # create dir, a "valueless" key to hold subkeys
    $etcd->create_dir("/dir");
    
    # delete key and everything under it
    $etcd->delete_dir("/dir");
    
    # atomically create in-order key
    $etcd->create_in_order("/dir", "value");
    
    # block until key changes
    $etcd->watch("/message");

=head1 DESCRIPTION

This module provides access to etcd's key space API. The methods here map
almost exactly to operations described in the etcd API documentation. See
L<Etcd/SEE ALSO> for further reading.

All methods except C<exists> returns a L<Etcd::Response> object on success and
C<die> on error. On error, C<$@> will contain either a reference to a
L<Etcd::Error> object (for API-level errors) or a regular string (for network,
transport or other errors).

All methods can take any number of additional arguments in C<key =E<gt> value>
form. These are added to the query parameters in the URL that gets submitted to
etcd. This is how you would pass options for C<ttl> or C<recursive>, for
example.

Any arguments of this kind that clash with the internal operation of a method
will silently be ignored; for example, passing a C<value> key to C<set> will be
ignored because that's how the value is passed internally.

=head1 METHODS

=over 4

=item *

C<set>

    $etcd->set("/message", "hello world");

Set a value for a key. The key will be created if it doesn't exist.

This invokes the C<PUT> method for the given key.

=item *

C<get>

    my $node = $etcd->get("/message");

Get a key.

This invokes the C<GET> method for the given key.

=item *

C<delete>

    $etcd->delete("/message");

Delete a key.

This invokes the C<DELETE> method for the given key.

=item *

C<compare_and_swap>

    $etcd->compare_and_swap("/message", "new", "old");

Atomic compare-and-swap the value of a key.

This invokes the C<PUT> method for the given key with the C<prevValue> query
parameter.

=item *

C<compare_and_delete>

    $etcd->compare_and_delete("/message", "old");

Atomic compare-and-delete the value of a key.

This invokes the C<DELETE> method for the given key with the C<prevValue> query
parameter.

=item *

C<create>

    $etcd->create("/message", "value");

Create a key. Like set, but fails if the key exists.

This invokes the C<PUT> method for the given key with the C<prevExist> query
parameter set to C<false>.

=item *

C<update>

    $etcd->update("/message", "value");

Update the value of a key. Like set, but fails if the key doesn't exist.

This invokes the C<PUT> method for the given key with the C<prevExist> query
parameter set to C<true>.

=item *

C<exists>

    my $exists = $etcd->exists("/message");

Check if key exists. Unlike the other methods, it does not return a reference
to a L<Etcd::Response> object but insteads returns a true or false value. It
may still throw an error.

This invokes the C<GET> method for the given key.

=item *

C<create_dir>

    $etcd->create_dir("/dir");

Creates a directory, a "valueless" key to hold sub-keys.

This invokes the C<PUT> method for the given key with the C<dir> query
parameter set to C<true>.

=item *

C<delete_dir>

    $etcd->delete_dir("/dir");

Deletes a key and all its sub-keys.

This invokes the C<DELETE> method for the given key with the C<dir> query
parameter set to C<true>.

=item *

C<create_dir>

    $etcd->create_in_order("/dir", "value");

Atomically creates an in-order key.

This invokes the C<POST> method for the given key.

=item *

C<watch>

    $etcd->watch("/message");

Block until the given key changes, then return the change.

This invokes the C<GET> method for the given key with the C<wait> query
parameter set to C<true>.

=back

=head1 KNOWN ISSUES

=over 4

=item *

There is no convenient way to specify the C<prevIndex> test to
C<compare_and_swap> or C<compare_and_delete>. These can be implemented directly
with C<set>.

=item *

C<watch> has no asynchronous mode.

=back

See L<Etcd/SUPPORT> for information on how to report bugs or feature requests.

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
