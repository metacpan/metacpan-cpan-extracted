package Flux::In::Role::Easy;
{
  $Flux::In::Role::Easy::VERSION = '1.03';
}

# ABSTRACT: simplified version of Flux::In role


use Moo::Role;
with 'Flux::In';

sub read_chunk {
    my $self = shift;
    my ($limit) = @_;

    my @chunk;
    while (defined($_ = $self->read)) {
        push @chunk, $_;
        last if @chunk >= $limit;
    }
    return unless @chunk; # return false if nothing can be read
    return \@chunk;
}

sub commit {
}


1;

__END__

=pod

=head1 NAME

Flux::In::Role::Easy - simplified version of Flux::In role

=head1 VERSION

version 1.03

=head1 DESCRIPTION

This role is an extension of L<Flux::In> role. It provides the sane C<read_chunk> implementation and the empty C<commit> implementation, so you only have to define C<read>.

=head1 CONSUMER SYNOPSIS

    use Moo;
    with "Flux::In::Role::Easy";

    my $i = 0;
    sub read {
        return $i++;
    }

=head1 SEE ALSO

This role is a specialization of L<Flux::In>.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
