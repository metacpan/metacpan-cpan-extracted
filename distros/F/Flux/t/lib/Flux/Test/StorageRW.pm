package Flux::Test::StorageRW;

# ABSTRACT: test storage rw capabilities

use strict;
use warnings;

use parent qw(Test::Class);
use Test::More;
use Params::Validate qw(:all);

=head1 DESCRIPTION

Since we want this class to be useful both for storages supporting named clients, and for storages supporting cursor-style input streams only, constructor arguments are pretty complex.

=head1 METHODS

=over

=item B<< new($storage_gen, $cursor_gen) >>

Constructor parameters:

=over

=item I<$storage_gen>

Coderef which returns newly constructed storage when called.

=item I<$cursor_gen>

Coderef which generates new argument appropriate for C<< $storage->in($cursor) >> call. By default, it's trivial C<< sub { shift } >>, which works fine for storages which support named clients.

=back

=cut
sub new {
    my $class = shift;
    my ($storage_gen, $cursor_gen) = validate_pos(@_, { type => CODEREF }, { type => CODEREF, default => sub { shift } } );
    my $self = $class->SUPER::new;
    $self->{storage_gen} = $storage_gen;
    $self->{cursor_gen} = $cursor_gen;
    return $self;
}

sub setup :Test(setup) {
    my $self = shift;
    $self->{storage} = $self->{storage_gen}->();
}

sub teardown :Test(teardown) {
    my $self = shift;
    delete $self->{storage};
}

sub storage {
    my $self = shift;
    return $self->{storage};
}

sub in {
    my $self = shift;
    return $self->storage->in($self->{cursor_gen}->(shift));
}

sub client_is_input_stream :Test(1) {
    my $self = shift;
    ok($self->in('abc')->does('Flux::In'));
}

sub simple_read_write :Test(3) {
    my $self = shift;
    my $storage = $self->{storage};

    $storage->register_client('blah') if $storage->can('register_client'); # because some storages start their clients from the tail of the storage
    $storage->write("123\n");
    $storage->write("abc\n");
    $storage->commit;

    my $in = $self->in('blah');
    is($in->read, "123\n");
    is($in->read, "abc\n");
    is($in->read, undef);
    $in->commit;
}

sub two_clients :Test(3) {
    my $self = shift;
    my $storage = $self->{storage};
    if ($storage->can('register_client')) {
        $storage->register_client($_) for qw( blah blah2 );
    }

    $storage->write("123\n");
    $storage->write("abc\n");
    $storage->commit;

    {
        my $in = $self->in('blah');
        $in->read;
        $in->commit;
    }

    my $in = $self->in('blah');
    my $in2 = $self->in('blah2');
    is($in->read, "abc\n");
    is($in2->read, "123\n");
    is($in2->read, "abc\n");
}

=back

=cut

1;
