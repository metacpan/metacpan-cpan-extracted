package Flux::Mapper::MappedOut;
{
  $Flux::Mapper::MappedOut::VERSION = '1.03';
}

# ABSTRACT: representation of mapper|out


use Moo;
with 'Flux::Out';

has 'mapper' => (
    is => 'ro',
    required => 1,
);

has 'out' => (
    is => 'ro',
    required => 1,
);

sub write {
    my $self = shift;
    my ($item) = @_;

    my @items = $self->mapper->write($item);
    $self->out->write($_) for @items;
    return;
}

sub write_chunk {
    my $self = shift;
    my ($chunk) = @_;

    $chunk = $self->mapper->write_chunk($chunk);
    $self->out->write_chunk($chunk);
    return;
}

sub commit {
    my ($self) = @_;

    my @items = $self->mapper->commit; # flushing the stuff remaining in possible mapper buffers
    $self->out->write_chunk(\@items);
    $self->out->commit;
    return;
}

1;

__END__

=pod

=head1 NAME

Flux::Mapper::MappedOut - representation of mapper|out

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Don't create instances of this class directly.

Use C<$mapper | $out> syntax sugar instead.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
