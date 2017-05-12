package Flux::Out::Role::Easy;
{
  $Flux::Out::Role::Easy::VERSION = '1.03';
}

# ABSTRACT: simplified version of Flux::Out role


use Moo::Role;
with 'Flux::Out';

sub write_chunk {
    my $self = shift;
    my ($chunk, @extra) = @_;

    die "write_chunk method expects arrayref, you specified: '$chunk'" unless ref($chunk) eq 'ARRAY'; # can chunks be blessed into something?
    for my $item (@$chunk) {
        $self->write($item, @extra);
    }
    return;
}

sub commit {
}


1;

__END__

=pod

=head1 NAME

Flux::Out::Role::Easy - simplified version of Flux::Out role

=head1 VERSION

version 1.03

=head1 DESCRIPTION

This role is an extension of L<Flux::Out> role. It provides the sane C<write_chunk> implementation and the empty C<commit> implementation, so you only have to define C<write>.

=head1 CONSUMER SYNOPSIS

    use Moo;
    with "Flux::Out::Role::Easy";

    sub write {
        my ($self, $item) = @_;
        say $item;
    }

=head1 SEE ALSO

This role is a specialization of L<Flux::Out>.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
