package Message::Passing::Exception;
use Moo::Role;
use namespace::clean -except => 'meta';

sub as_hash {
    return { %{ $_[0] }, class => ref($_[0]) }
}

sub pack {
    $_[0]->as_hash;
}

1;

=head1 NAME

Message::Passing::Exception - Base role for Message::Passing exceptions

=head1 METHODS

=head2 as_hash

=head2 pack

Synonyms, which return a flattened (to a hash) object.

=head1 AUTHOR, COPYRIGHT AND LICENSE

See L<Message::Passing>.

=cut

