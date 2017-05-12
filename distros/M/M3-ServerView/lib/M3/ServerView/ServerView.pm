package M3::ServerView::ServerView;

use strict;
use warnings;

use M3::ServerView::ServerEntry;

use base qw(M3::ServerView::View);

sub _entry_class { "M3::ServerView::ServerEntry"; }

sub _entry_columns {
    return (
        "No"        => [ no         => "numeric" ],
        "Type"      => [ type       => "text" ],
        "Address"   => sub {
            my ($view, $entry, $uri) = @_;
            if (ref $uri) {
                $entry->{_details} = [$view->connection, $uri->path, $uri->query];
            }
        },
        "Jobs"      => [ jobs       => "numeric" ],
        "Threads"   => [ threads    => "numeric" ],
        "Status"    => [ status     => "text" ],
        "Command"   => sub {},
    );
}

1;
__END__

=head1 NAME

M3::ServerView::ServerView - Handles entries for path '/server'

=head1 INTERFACE

See L<M3::ServerView::View>.

=head2 ENTRIES

See L<M3::ServerView::ServerEntry>.

=cut
