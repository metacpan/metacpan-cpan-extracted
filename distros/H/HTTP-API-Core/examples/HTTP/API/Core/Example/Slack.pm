package HTTP::API::Core::Example::Slack;

use strict;
use warnings;
use parent 'HTTP::API::Core';

sub new {
    my ($class, %args) = @_;
    my $token = delete $args{token};
    die "token is required\n" if !defined($token) || $token eq '';

    return $class->SUPER::new(
        base_url => 'https://slack.com/api',
        headers  => { Authorization => "Bearer $token" },
        %args,
    );
}

sub messages_pager {
    my ($self, %args) = @_;
    my $channel = delete $args{channel};
    die "channel is required\n" if !defined($channel) || $channel eq '';
    my $limit = delete($args{limit}) || 15;
    my $oldest = delete $args{oldest};
    my $latest = delete $args{latest};
    die "unknown messages option: $_\n" for sort keys %args;

    return $self->paginate(
        '/conversations.history',
        mode         => 'cursor',
        items        => 'messages',
        next         => 'response_metadata.next_cursor',
        cursor_param => 'cursor',
        query        => {
            channel => $channel,
            limit   => $limit,
            oldest  => $oldest,
            latest  => $latest,
        },
    );
}

1;
