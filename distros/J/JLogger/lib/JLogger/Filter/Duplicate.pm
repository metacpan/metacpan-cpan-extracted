package JLogger::Filter::Duplicate;

use strict;
use warnings;

use base 'JLogger::Filter';

sub filter {
    my ($self, $message) = @_;

    return 0 if $message->{type} ne 'message';

    if (my $pm = delete $self->{_previous_message}) {
        my $message_to_no_resource = (split /\//, $message->{to}, 2)[0];
        if ($pm->{from} eq $message->{from}
                && $pm->{to} eq $message_to_no_resource
                && $pm->{id} eq $message->{id}) {
                return 1;
            }
    }

    $self->{_previous_message} = {
        from => $message->{from},
        to   => (split /\//, $message->{to}, 2)[0],
        id   => $message->{id}};

    0;
}

1;
__END__

=head1 NAME

JLogger::Filter::Duplicate - filtrate duplicate messages send to different
resources of same recipient.

=cut
