#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;

use Kafka::Librd;
use Getopt::Long;
use Pod::Usage;

my $res = GetOptions(
    "group-id=s" => \my $group_id,
    "topic=s"    => \my @topics,
    "brokers=s"  => \my $brokers,
    "ca-cert=s"  => \my $cacert,
    "username=s" => \my $sasluser,
    "password=s" => \my $saslpass,
    "debug"      => \my $debug,
    "help"       => \my $help,
);

pod2usage(-verbose => 2, -noperldoc => 1) if $help or not $res;

=head1 SYNOPSIS

     kafka_consumer.pl [options] [file...]

=head1 DESCRIPTION

The script connects to Kafka, subscribes to specified topic and outputs incomming messages.

=head1 OPTIONS

=over 4

=item B<group-id>

consumer group id to use, by default it is "test-consumer"

=item B<topic>

topic to which to subscribe

=item B<brokers>

comma separated list of brokers. For example: C<broker1.mydomain:9092,broker2.mydomain:9092>.

=item B<ca-cert>

path to CA certificate. If not specified then plaintext protocol is used to connect to broker.

=item B<username>

=item B<password>

username and password for authentication if required

=item B<debug>

print additional debugging information

=back

=cut

$group_id //= "test-consumer";
$brokers  //= "localhost:9092";

my $sproto = $cacert ? "ssl" : "plaintext";
$sproto = "sasl_$sproto" if $sasluser;

my $kafka = Kafka::Librd->new(
    Kafka::Librd::RD_KAFKA_CONSUMER,
    {
        'group.id' => $group_id,
        (
            $cacert
            ? (
                'security.protocol' => $sproto,
                'ssl.ca.location'   => $cacert,
              )
            : ()
        ),
        (
            $sasluser
            ? (
                'sasl.mechanisms' => 'PLAIN',
                'sasl.username'   => $sasluser,
                'sasl.password'   => $saslpass,
              )
            : ()
        ),
        ( $debug ? ( debug => 'cgrp,topic,fetch' ) : () ),
        'api.version.request' => 'true',
    },
);

my $added = $kafka->brokers_add($brokers);
say "Added $added brokers";

my $err = $kafka->subscribe( \@topics );
if ( $err != 0 ) {
    die "Couldn't subscribe: ", Kafka::Librd::Error::to_string($err);
}
say "Subscribed";

my $stop;

$SIG{INT} = sub { say "Got SIGINT"; $stop = 1 };

while (1) {
    my $msg = $kafka->consumer_poll(1000);
    if ( defined $msg ) {
        my $err = $msg->err;
        say "-----";
        say "Error: ", Kafka::Librd::Error::to_name($err) if $err;
        say "Topic: ", $msg->topic;
        say "Part: ",  $msg->partition;
        say "Offset: ",  $msg->offset;
        say "Key: ",     $msg->key if defined $msg->key;
        say "Payload: ", $msg->payload;
    }
    # commit offsets to broker
    $kafka->commit;
    last if $stop;
}

$kafka->consumer_close;

$kafka->destroy;

Kafka::Librd::rd_kafka_wait_destroyed(5000);
