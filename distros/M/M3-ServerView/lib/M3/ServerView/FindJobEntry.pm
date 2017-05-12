package M3::ServerView::FindJobEntry;

use strict;
use warnings;

use base qw(M3::ServerView::Entry);

# Build accessors
use Object::Tiny qw(
    no
    type
    name
    id
    user
    status
    change
);

1;
__END__

=head1 NAME

M3::ServerView::FindJobEntry - Records returned by 'findjob' view.

=head1 INTERFACE

=head2 ATTRIBUTES

The following attributes are available as accessors and are also searchable. Type of 
value within parenthesis.

=over 4

=item no (I<numerical>)

=item type (I<text>)

=item name (I<text>)

=item id (I<numerical>)

=item user (I<text>)

=item status (I<text>)

=item change (I<numerical>)

=back

=cut