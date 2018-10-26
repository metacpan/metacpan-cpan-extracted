package Kafka::Librd;
use strict;
use warnings;
our $VERSION = "0.10";
my $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

require XSLoader;
XSLoader::load('Kafka::Librd', $XS_VERSION);

use Exporter::Lite;
our @EXPORT_OK;

=head1 NAME

Kafka::Librd - bindings for librdkafka

=head1 VERSION

This document describes Kafka::Librd version 0.10

=head1 SUPPORT

Please note that this module is not actively developed and maintained, if you
are interested in taking it over, please contact the author

=head1 SYNOPSIS

    use Kafka::Librd;

    my $kafka = Kafka::Librd->new(
        Kafka::Librd::RD_KAFKA_CONSUMER,
        {
            "group.id" => 'consumer_id',
        },
    );
    $kafka->brokers_add('server1:9092,server2:9092');
    $kafka->subscribe( \@topics );
    while (1) {
        my $msg = $kafka->consumer_poll(1000);
        if ($msg) {
            if ( $msg->err ) {
                say "Error: ", Kafka::Librd::Error::to_string($err);
            }
            else {
                say $msg->payload;
            }
        }
    }


=head1 DESCRIPTION

This module provides perl bindings for librdkafka.

=head1 METHODS

=cut

=head2 new

    $kafka = $class->new($type, \%config)

Create a new instance. $type can be either C<RD_KAFKA_CONSUMER> or
C<RD_KAFKA_PRODUCER>. Config is a hash with configuration parameters as
described in
L<https://github.com/edenhill/librdkafka/blob/master/CONFIGURATION.md>,
additionally it may include C<default_topic_config> key, with a hash containing
default topic configuration properties.

=cut

sub new {
    my ( $class, $type, $params ) = @_;
    return _new( $type, $params );
}

{
    my $errors = Kafka::Librd::Error::rd_kafka_get_err_descs();
    no strict 'refs';
    for ( keys %$errors ) {
        *{__PACKAGE__ . "::RD_KAFKA_RESP_ERR_$_"} = eval "sub { $errors->{$_} }";
        push @EXPORT_OK, "RD_KAFKA_RESP_ERR_$_";
    }
}

=head2 brokers_add

    $cnt = $kafka->brokers_add($brokers)

add one or more brokers to the list of initial bootstrap brokers. I<$brokers>
is a comma separated list of brokers in the format C<[proto://]host[:port]>.

=head2 subscribe

    $err = $kafka->subscribe(\@topics)

subscribe to the list of topics using balanced consumer groups.

=head2 unsubscribe

    $err = $kafka->unsubscribe

unsubscribe from the current subsctiption set

=head2 subscription

    $tplist = $kafka->subscription

return current subscription. Subscription returned as a reference to array of
hashes with the following fields: C<topic>, C<partition>, C<offset>, C<metadata>.

=head2 assign

    $err = $kafka->assign(\@tplist)

assign partitions to consume. C<@tplist> is an array of hashes with
C<topic> and C<partition> fields set.

=head2 assignment

    $tplist = $kafka->assignment

return current assignment. Result returned in the same way as for
L</subscription>.

=head2 consumer_poll

    $msg = $kafka->consumer_poll($timeout_ms)

poll for messages or events. If any message or event received, returns
L</Kafka::Librd::Message> object. If C<<$msg->err>> for returned object is zero
(RD_KAFKA_RESP_ERR_NO_ERROR), then it is a proper message, otherwise it is an
event or an error.

=head2 commit

    $err = $kafka->commit(\@tplist, $async)

commit offsets to the broker. C<@tplist> is an array of hashes
with the following keys: C<topic>, C<partition>, C<offset>, C<metadata>. If
@topic_partition_list is missing or undef, then current partition assignment
is used instead. If C<$async> is 1, then method returns immediately, if it is
0 or missing then method blocks until offsets are commited.

=head2 commit_message

    $err = $kafka->commit_message($msg, $async)

commit message's offset for the message's partition. C<$async> same as for
L</commit>.

=head2 committed

    $tplist = $kafka->committed(\@tplist, $timeout_ms)

retrieve commited offsets for topics and partitions specified in C<@tplist>,
which is an array of hashes with C<topic> and C<partition> fields. Returned
C<$tplist> contains a copy of the input list with added C<offset> fields.

=head2 position

    $tplist = $kafka->position(\@tplist)

retrieve current offsets for topics and partitions specified in C<@tplist>,
which is an array of hashes with C<topic> and C<partition> fields. Returned
C<$tplist> contains a copy of the input list with added C<offset> fields.

=head2 consumer_close

    $err = $kafka->consumer_close

close down the consumer

=head2 topic

    $topic = $kafka->topic($name, \%config)

return a L</Kafka::Librd::Topic>topic object, that can be used to produce
messages

=head2 outq_len

    $len = $kafka->outq_len

return the current out queue length.

=head2 destroy

    $kafka->destroy

destroy kafka handle

=head2 dump

    $kafka->dump

dump internal state of kafka handle to stdout, only useful for debugging

=head1 Kafka::Librd::Topic

This class maps to C<rd_kafka_topic_t> structure from librdkafka and represents
topic. It should be created with L</topic> method of Kafka::Librd object. It
provides the following method:

=head2 produce

    $err = $topic->produce($partition, $msgflags, $payload, $key)

produce a message for the topic. I<$msgflags> can be RD_KAFKA_MSG_F_BLOCK in
the future, but currently it should be set to 0, RD_KAFKA_MSG_F_COPY and
RD_KAFKA_MSG_F_FREE must not be used, internally RD_KAFKA_MSG_F_COPY is always
set.

=head1 Kafka::Librd::Message

This class maps to C<rd_kafka_message_t> structure from librdkafka and
represents message or event. Objects of this class have the following methods:

=head2 err

return error code from the message

=head2 topic

return topic name

=head2 partition

return partition number

=head2 offset

return offset. Note, that the value is truncated to 32 bit if your perl doesn't
support 64 bit integers.

=head2 key

return message key

=head2 payload

return message payload

=cut

1;

__END__

=head1 CAVEATS

Message offset is truncated to 32 bit if perl compiled without support for 64 bit integers.

=head1 SEE ALSO

L<https://github.com/edenhill/librdkafka>

=head1 BUGS

Please report any bugs or feature requests via GitHub bug tracker at
L<http://github.com/trinitum/perl-Kafka-Librd/issues>.

=head1 AUTHOR

Pavel Shaydo C<< <zwon at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2016, 2017 Pavel Shaydo

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
