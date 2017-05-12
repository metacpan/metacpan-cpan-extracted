package M3::ServerView::ServerEntry;

use strict;
use warnings;

use base qw(M3::ServerView::Entry);

# Build accessors
use Object::Tiny qw(
    no
    type
    jobs
    threads
    status
);

sub details {
    my ($self) = @_;
    return unless $self->{_details};
    my ($conn, $path, $query) = @{$self->{_details}};
    return $conn->_load_view($path, $query);
}

1;
__END__

=head1 NAME

M3::ServerView::ServerEntry - Records returned by 'server' view.

=head1 INTERFACE

=head2 ATTRIBUTES

The following attributes are available as accessors and are also searchable. Type of 
value within parenthesis.

=over 4

=item no (I<numerical>)

=item type (I<text>)

=item jobs (I<numerical>)

=item threads (I<numerical>)

=item status (I<text>)

=back

=head2 INSTANCE METHODS

=over 4

=item details ( )

Retrieves the details for the entry and returns a view corresponding to the kind of entry. This may 
for example be C<M3::ServerView::ServerView>-instance if the type is "Server:*".

=back

=cut