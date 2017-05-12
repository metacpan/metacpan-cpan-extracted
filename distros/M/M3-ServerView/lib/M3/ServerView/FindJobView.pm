package M3::ServerView::FindJobView;

use strict;
use warnings;

use M3::ServerView::FindJobEntry;

use base qw(M3::ServerView::View);

sub _entry_class { "M3::ServerView::FindJobEntry"; }

sub _entry_columns {
    return (
        "No"        => [ no         => "numeric" ],
        "Type"      => [ type       => "text" ],
        "Location"  => sub {
        },
        "Name"      => sub {
            my ($view, $entry, $data) = @_;
            if (!ref $data) {
                $entry->{name} = $data;
            }
        },
        "Id"        => [ id         => "numeric" ],
        "User"      => [ user       => "text" ],
        "Status"    => [ status     => "text" ],
        "Change"    => [ change     => "numeric" ],
    );
}

1;
__END__

=head1 NAME

M3::ServerView::FindJobView - Handles entries for path '/findjob'

=head1 INTERFACE

See L<M3::ServerView::View>.

=head2 ENTRIES

See L<M3::ServerView::FindJobEntry>.

=cut
