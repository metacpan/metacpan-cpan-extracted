package Flux::Mapper::MappedMapper;
{
  $Flux::Mapper::MappedMapper::VERSION = '1.03';
}

# ABSTRACT: representation of mapper|mapper


use Moo;
with 'Flux::Mapper';

has ['left', 'right'] => (
    is => 'ro',
    required => 1,
);

sub write {
    my ($self, $item) = @_;
    my @items = $self->left->write($item);
    my @result = map { $self->right->write($_) } @items;
    return (wantarray ? @result : $result[0]);
}

sub write_chunk {
    my ($self, $chunk) = @_;
    $chunk = $self->left->write_chunk($chunk);
    return $self->right->write_chunk($chunk);
}

sub commit {
    my ($self) = @_;
    my @items = $self->left->commit;
    my $result = $self->right->write_chunk(\@items);
    push @$result, $self->right->commit;
    return @$result;
}

1;

__END__

=pod

=head1 NAME

Flux::Mapper::MappedMapper - representation of mapper|mapper

=head1 VERSION

version 1.03

=head1 DESCRIPTION

Don't create instances of this class directly.

Use C<$mapper1 | $mapper2> syntax sugar instead.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
