use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);
use Kafka::Librd qw();

{
    my $max_message_size = 1000;

    my $kafka = Kafka::Librd->new(
        Kafka::Librd::RD_KAFKA_PRODUCER,
        {
            # this constrains the message size a well as topic name size
            'message.max.bytes' => $max_message_size,
        },
    );
    isa_ok $kafka, 'Kafka::Librd';

    # test normal creation of a topic
    my $topic = $kafka->topic("test", {});
    my $err = Kafka::Librd::Error::last_error();
    isa_ok $topic, 'Kafka::Librd::Topic';
    is $err, Kafka::Librd::RD_KAFKA_RESP_ERR_NO_ERROR, "last error returns success";

    # test a simple produce call
    my $value = $topic->produce(1, 0, "test", 0);
    $err = Kafka::Librd::Error::last_error();
    is $value, 0, "simple message produce returns no error";
    is $err, Kafka::Librd::RD_KAFKA_RESP_ERR_NO_ERROR, "last error returns success";

    # provoke an error by trying to produce a message exceeding the maximum size
    my $large_message = 'a' x ($max_message_size + 1);
    $value = $topic->produce(1, 0, $large_message, 0);
    $err = Kafka::Librd::Error::last_error();
    is $value, -1, "to large message produce returns error";
    is $err, Kafka::Librd::RD_KAFKA_RESP_ERR_MSG_SIZE_TOO_LARGE, "last error returns too large error";

    # same size constraints apply to topic creation call
    $topic = $kafka->topic($large_message, {});
    $err = Kafka::Librd::Error::last_error();
    is $topic, undef;
    is $err, Kafka::Librd::RD_KAFKA_RESP_ERR__INVALID_ARG;
}

done_testing;

__END__
