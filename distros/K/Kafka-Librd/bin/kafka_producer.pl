#!/usr/bin/env perl
use 5.014;
use strict;
use warnings;

use Kafka::Librd;
use Getopt::Long;
use Pod::Usage;

my $gor = GetOptions(
    "topic=s"    => \my $topic,
    "brokers=s"  => \my $brokers,
    "ca-cert=s"  => \my $cacert,
    "username=s" => \my $sasluser,
    "password=s" => \my $saslpass,
    "debug"      => \my $debug,
    "help"       => \my $help,
);

pod2usage(-verbose => 2, -noperldoc => 1) if $help or not $gor;

=head1 SYNOPSIS

     kafka_producer.pl [options] [file...]

=head1 DESCRIPTION

The script reads messages from the files or stdin and publishes them to Kafka.
Each line is considered as a separate message and may contain also a key
separated by TAB.

=head1 OPTIONS

=over 4

=item B<topic>

topic into which produce messages

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

$brokers //= "localhost:9092";

my $sproto = $cacert ? "ssl" : "plaintext";
$sproto = "sasl_$sproto" if $sasluser;

my $kafka = Kafka::Librd->new(
    Kafka::Librd::RD_KAFKA_PRODUCER,
    {
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
        ( $debug ? ( debug => 'security,cgrp,topic,fetch' ) : () ),
        'api.version.request' => 'true',
    },
);

my $added = $kafka->brokers_add($brokers);
say "Added $added brokers";

my $ktopic = $kafka->topic( $topic, {} );

while (<>) {
    chomp;
    last if $_ eq '.';
    my ( $msg, $key ) = split /\t/, $_, 2;
    my $status = $ktopic->produce( -1, 0, $msg, $key );
    if ($status == -1){
        my $err = Kafka::Librd::Error::last_error();
        say "Couldn't produce: ", Kafka::Librd::Error::to_string($err);
    }
}

sleep 1 while $kafka->outq_len;

$kafka = undef;

my $res = Kafka::Librd::rd_kafka_wait_destroyed(5000);
say "Some kafka resources are still allocated: $res" if $res;
