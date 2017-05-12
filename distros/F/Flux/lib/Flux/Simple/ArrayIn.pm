package Flux::Simple::ArrayIn;
{
  $Flux::Simple::ArrayIn::VERSION = '1.03';
}

# ABSTRACT: input stream representation of an array


use Moo;
with 'Flux::In';

has '_data' => (
    is => 'ro',
    required => 1,
);

sub BUILDARGS {
    my $class = shift;
    my ($data) = @_;
    return { _data => $data };
}

sub read {
    my $self = shift;
    return shift @{ $self->_data };
}

sub read_chunk {
    my $self = shift;
    my ($number) = @_;

    return unless @{ $self->_data };
    return [ splice @{ $self->_data }, 0, $number ];
}

sub commit {}

1;

__END__

=pod

=head1 NAME

Flux::Simple::ArrayIn - input stream representation of an array

=head1 VERSION

version 1.03

=head1 SYNOPSIS

    use Flux::Simple::ArrayIn;
    $in = Flux::Simple::ArrayIn->new(\@items);

=head1 DESCRIPTION

Usually, you shouldn't create instances of this class directly. Use C<array_in> helper from L<Flux::Simple> instead.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
