package Flux::Mapper::MappedIn;
{
  $Flux::Mapper::MappedIn::VERSION = '1.03';
}

# ABSTRACT: representation of in|mapper


use Moo;
with 'Flux::In';

has 'mapper' => (
    is => 'ro',
    required => 1,
);

has 'in' => (
    is => 'ro',
    required => 1,
);

sub read {
    my $self = shift;

    while (my $item = $self->in->read) {
        my @mapped = $self->mapper->write($item);
        next unless @mapped;
        die "One-to-many not implemented in input stream mappers" unless @mapped == 1;
        return $mapped[0];
    }
    return; # underlying input stream is depleted
}

sub read_chunk {
    my $self = shift;
    my ($limit) = @_;

    my $chunk = $self->in->read_chunk($limit);
    return unless $chunk;
    return $self->mapper->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    my @items = $self->mapper->commit;
    die "flushable mappers cannot be attached to input streams" if @items;
    #FIXME: check it earlier
    $self->in->commit;
}

sub lag {
    my $self = shift;
    die "underlying input stream doesn't implement Lag role" unless $self->in->does('Flux::In::Role::Lag');
    return $self->in->lag;
}

around 'does' => sub {
    my $orig = shift;
    my $self = shift;
    return 1 if $orig->($self, @_);

    my ($role) = @_;

    if ($role eq 'Flux::In::Role::Lag') {
        # Some roles depend on being implemented by the underlying input stream.
        return $self->in->does($role);
    }
    return;
};

1;

__END__

=pod

=head1 NAME

Flux::Mapper::MappedIn - representation of in|mapper

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Don't create instances of this class directly.

Use C<$in | $mapper> sytax sugar instead.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
