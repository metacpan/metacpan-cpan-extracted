package M3::ServerView::RootView;

use strict;
use warnings;

use M3::ServerView::RootEntry;

use base qw(M3::ServerView::View);

sub _entry_class { "M3::ServerView::RootEntry"; }

sub _entry_columns {
    return (
        "No"        => [ no         => "text" ],
        "Type"      => [ type       => "text" ],
        "Address"   => sub {
            my ($view, $entry, $uri) = @_;
            if (ref $uri) {
                $entry->{_details} = [$view->connection, $uri->path, $uri->query];
            }
        },
        "PID"       => [ pid        => "numeric" ],
        "Started"   => [ started    => "datetime" ],
        "Jobs"      => [ jobs       => "numeric" ],
        "Threads"   => [ threads    => "numeric" ],
        "CPU%"      => [ cpu        => "text" ],
        "Heap/kb"   => [ heap       => "numeric" ],
        "Status"    => [ status     => "text" ],
        "Command"   => sub {},
    );
}

1;
__END__

=head1 NAME

M3::ServerView::RootView - Handles entries for path '/'

=head1 INTERFACE

See L<M3::ServerView::View>.

=head2 ENTRIES

See L<M3::ServerView::RootEntry>.

=cut
