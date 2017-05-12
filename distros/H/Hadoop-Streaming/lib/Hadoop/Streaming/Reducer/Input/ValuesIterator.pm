package Hadoop::Streaming::Reducer::Input::ValuesIterator;
$Hadoop::Streaming::Reducer::Input::ValuesIterator::VERSION = '0.143060';
use Moo;
with 'Hadoop::Streaming::Role::Iterator';

#ABSTRACT: Role providing access to values for a given key.

has input_iter => (
    is       => 'ro',
    does     => 'Hadoop::Streaming::Role::Iterator',
    required => 1,
);

has first => ( is => 'rw', );


sub has_next
{
    my $self = shift;
    return 1 if $self->first;
    return unless defined $self->input_iter->input->next_key;
    return $self->input_iter->current_key eq
        $self->input_iter->input->next_key ? 1 : 0;
}


sub next
{
    my $self = shift;
    if ( my $first = $self->first )
    {
        $self->first(undef);
        return $first;
    }
    my ( $key, $value ) = $self->input_iter->input->each;
    $value;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::Streaming::Reducer::Input::ValuesIterator - Role providing access to values for a given key.

=head1 VERSION

version 0.143060

=head1 METHODS

=head2 has_next

    $ValuesIterator->has_next();

Checks if the ValueIterator has another value available for this key.

Returns 1 on success, 0 if the next value is from another key, and undef if there is no next key.

=head2 next

    $ValuesIterator->next();

Returns the next value available.  Reads from $ValuesIterator->input_iter->input

=head1 AUTHORS

=over 4

=item *

andrew grangaard <spazm@cpan.org>

=item *

Naoya Ito <naoya@hatena.ne.jp>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naoya Ito <naoya@hatena.ne.jp>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
