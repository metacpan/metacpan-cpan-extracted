package Message::Passing::Filter::ToLogstash;
use Moo;
use MooX::Types::MooseLike::Base qw/ ArrayRef /;
use List::Util qw( uniq );
use DateTime;
use Sys::Hostname::Long;
use namespace::clean -except => 'meta';

use constant HOSTNAME => hostname_long();

with 'Message::Passing::Role::Filter';

has default_tags => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

has add_tags => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

my %map = (
    '__CLASS__' => [ 'perl:Class:', 'type' ],
    hostname    => 'source_host',
    message     => 'message',
    filename    => 'source_path',
    date        => 'timestamp',
    type        => 'type',
);

sub filter {
    my ($self, $message) = @_;
    if ('HASH' ne ref($message)) {
        my $line = $message;
        $message = {
            message   => $line,
            hostname  => HOSTNAME,
            epochtime => AnyEvent->now,
            type      => 'generic_line',
        };
    }
    $message = { '@fields' => { %$message } };
    if (exists($message->{'@fields'}{epochtime})) {
        $message->{'@timestamp'} = DateTime->from_epoch(epoch => delete($message->{'@fields'}{epochtime})) . ''
    }
    foreach my $k (keys %map) {
        my $v = $map{$k};
        $v = [ '', $v ] if !ref $v;
        my ($prefix, $field) = @$v;
        $field = '@' . $field;
        if (exists($message->{'@fields'}{$k}) && !exists($message->{$field})) {
            $message->{$field} = $prefix . delete $message->{'@fields'}{$k};
        }
    }
    $message->{'@tags'} ||= $self->default_tags;
    $message->{'@tags'} = [ uniq @{ $message->{'@tags'} }, @{ $self->add_tags } ];

    $message;
}

1;

=head1 NAME

Method::Passing::Filter::ToLogstash

=head1 DESCRIPTION

This filter changes the message format to comply with LogStash.
Duplicate tags will be removed.

=head1 ATTRIBUTES

=head2 default_tags

This is the list of tags which get added to the messages' @tags field in case
none have been included already.

=head2 add_tags

This is the list of tags which get added to the messages' @tags field in all
cases.

=head1 METHODS

=head2 filter

Filter the message.
