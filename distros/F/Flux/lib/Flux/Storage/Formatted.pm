package Flux::Storage::Formatted;
{
  $Flux::Storage::Formatted::VERSION = '1.03';
}

# ABSTRACT: Representation of a storage wrapped with a format.


use Moo;
with 'Flux::Storage';

has 'format' => (
    is => 'ro',
    required => 1,
);

has 'storage' => (
    is => 'ro',
    required => 1,
);

sub write {
    my $self = shift;
    my ($item) = @_;

    my @mapped = $self->format->encoder->write($item);
    return unless @mapped;
    $self->storage->write($_, @_) for @mapped; # would write_chunk be better?
}

sub write_chunk {
    my $self = shift;
    my $chunk = shift;
    $self->storage->write_chunk(
        $self->format->encoder->write_chunk($chunk),
        @_ # passing the rest of parameters as-is, some storages accept additional settings on write(), e.g. DelayedQueue
    );
}

sub in {
    my $self = shift;
    my $in = $self->storage->in(@_);
    return ($in | $self->format->decoder);
}

sub commit {
    my $self = shift;
    $self->storage->commit(@_);
}

around 'does' => sub {
    my $orig = shift;
    my $self = shift;
    return 1 if $orig->($self, @_);

    my ($role) = @_;

    if ($role eq 'Flux::Storage::Role::ClientList' or $role eq 'Flux::Role::Description') {
        return $self->storage->does($role);
    }
    return;
};

sub client_names {      return shift->storage->client_names(@_) }
sub register_client {   return shift->storage->register_client(@_) }
sub unregister_client { return shift->storage->unregister_client(@_) }
sub has_client {        return shift->storage->has_client(@_) }

sub description {
    my $self = shift;

    my $inner;
    if ($self->storage->does('Flux::Role::Description')) {
        $inner = $self->storage->description(@_);
    }
    else {
        $inner = $self->storage."";
    }

    return
        "format: ".blessed($self->format)."\n"
        .$inner;
}


1;

__END__

=pod

=head1 NAME

Flux::Storage::Formatted - Representation of a storage wrapped with a format.

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Don't create instances of this class directly. Use C<< $format->wrap($storage) >> instead.

=head1 SEE ALSO

L<Flux::Format>

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
