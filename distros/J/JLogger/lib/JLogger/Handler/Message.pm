package JLogger::Handler::Message;

use strict;
use warnings;

use base 'JLogger::Handler';

sub handle {
    my ($self, $node) = @_;

    if (my $body_node = ($node->find_all(['component' => 'body']))[0]) {
        my $message = {
            from => $node->attr('from'),
            to   => $node->attr('to'),
            type => 'message',

            id           => $node->attr('id'),
            message_type => $node->attr('type'),
            body         => $body_node->text,
        };

        if (my $thread_node = ($node->find_all(['component' => 'thread']))[0])
        {
            $message->{thread} = $thread_node->text;
        }

        return $message;
    }

    # Ignore empty messages
    return;
}

1;
