#!perl -T
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Log::Any::Test;    # should appear before 'use Log::Any'!
use Log::Any qw($log);

use lib 't';
use lib 'integ_t';
require 'iron_io_integ_tests_common.pl'; ## no critic (Modules::RequireBarewordIncludes)

plan tests => 4; # Setup, Do, Verify, Cleanup

require IO::Iron::IronMQ::Client;
require IO::Iron::IronMQ::Queue;
require IO::Iron::IronMQ::Message;

#use Log::Any::Adapter ('Stderr'); # Activate to get all log messages.
use Data::Dumper; $Data::Dumper::Maxdepth = 2;

diag("Testing IO::Iron::IronMQ::Client, Perl $], $^X");

## Test case
diag('Testing IO::Iron::IronMQ::Queue method post_messages()');

my $iron_mq_client;
my $project_id;
my $queue_name;
my $queue;
my @send_messages;
my @send_messages_ids;
my %msg_body_hash_02;

subtest 'Setup for testing' => sub {
    plan tests => 2;
    # Create an IronMQ client.
    $iron_mq_client = IO::Iron::IronMQ::Client->new( 'config' => 'iron_mq.json' );
    $project_id = $iron_mq_client->{'connection'}->{'project_id'};
    # Create a new queue name.
    $queue_name = create_unique_queue_name();
    # Create a new queue.
    $queue = $iron_mq_client->create_and_get_queue( 'name' => $queue_name );
    isa_ok($queue, 'IO::Iron::IronMQ::Queue', 'create_and_get_queue returns a IO::Iron::IronMQ::Queue.');
    is($queue->name(), $queue_name, 'Created queue has the given name.');
    diag('Created message queue ' . $queue_name . q{'.});

    use utf8;
    # Let's create some messages
    my $iron_mq_msg_send_01 = IO::Iron::IronMQ::Message->new(
            'body' => 'My message #01',
            );
    diag('Test with YAML in JSON.');
    use YAML::Tiny; # For serializing/deserializing a hash.
    %msg_body_hash_02 = (msg_body_text => 'My message #02', msg_body_item => {sub_item => 'Sub text'});
    my $yaml = YAML::Tiny->new(); $yaml->[0] = \%msg_body_hash_02;
    my $msg_body = $yaml->write_string();
    my $iron_mq_msg_send_02 = IO::Iron::IronMQ::Message->new(
            'body' => $msg_body,
            'delay' => 0,     # The item will not be available on the queue until this many seconds have passed.
            );
    my $iron_mq_msg_send_03 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #03 in Swedish: Räksmörgås' );
    my $iron_mq_msg_send_04 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #04 in Russian: бутерброд' );
    my $iron_mq_msg_send_05 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #05 in Chinese: 三明治' );
    my $iron_mq_msg_send_06 = IO::Iron::IronMQ::Message->new( 'body' => 'My message #06 in Yiddish: סענדוויטש' );
    diag('Test with JSON in JSON.');
    require JSON::MaybeXS;
    my $json = JSON::MaybeXS->new(utf8 => 1, pretty => 1);
    $msg_body = $json->encode(\%msg_body_hash_02);
    my $iron_mq_msg_send_07 = IO::Iron::IronMQ::Message->new( 'body' => $msg_body );
    diag('Test with perl Storable serializer module.');
    require Storable;
    $msg_body = Storable::freeze(\%msg_body_hash_02);
    my $iron_mq_msg_send_08 = IO::Iron::IronMQ::Message->new( 'body' => $msg_body );
    no utf8;
    diag('Created 8 messages for sending.');
    push @send_messages, $iron_mq_msg_send_01, $iron_mq_msg_send_02, $iron_mq_msg_send_03, $iron_mq_msg_send_04, $iron_mq_msg_send_05, $iron_mq_msg_send_06, $iron_mq_msg_send_07, $iron_mq_msg_send_08;
};

my @sent_msg_ids;
subtest 'Pushing' => sub {
    plan tests => 7;
    #Queue is empty
    my @msg_pulls_00 = $queue->reserve_messages( 'n' => 2, 'timeout' => 120 );
    is(scalar @msg_pulls_00, 0, 'No messages pulled from queue, size 0.');
    is($queue->size(), 0, 'Queue size is 0.');
    diag('Empty queue at the start.');

    # Let's push the messages.
    $log->clear();
    my $msg_send_id_01 = $queue->post_messages( 'messages' => [ $send_messages[0] ] );
    #my $log_test = 0;
    #map { $log_test = 1 if ($_->{level} eq 'info' 
    #        && $_->{category} eq 'IO::Iron::IronMQ::Queue' 
    #        && $_->{message} =~ /^Pushed IronMQ Message\(s\) \(queue name=$queue_name; message id\(s\)=$msg_send_id_01\)\.$/gs
    #    ) } @{$log->msgs};
    #is($log_test, 1, 'Push() logged correctly.');
    push @send_messages_ids, $msg_send_id_01;
    is($queue->size(), 1, 'One message pushed, queue size is 1.');
    push @sent_msg_ids, $msg_send_id_01;

    $log->clear();
    my @msg_send_ids_02 = $queue->post_messages( 'messages' => [ @send_messages[1,2] ] );
    #$log_test = 0;
    #my $send_ids_text = join ',', @msg_send_ids_02;
    ##diag(Dumper($log->msgs));
    #map { $log_test = 1 if ($_->{level} eq 'info' 
    #        && $_->{category} eq 'IO::Iron::IronMQ::Queue' 
    #        && $_->{message} =~ m/^Pushed IronMQ Message\(s\) \(queue name=$queue_name; message id\(s\)=$send_ids_text\)\.$/gs
    #    ) } @{$log->msgs};
    #is($log_test, 1, 'Push() logged correctly.');
    is(scalar @msg_send_ids_02, 2, 'Two messages pushed');
    push @send_messages_ids, @msg_send_ids_02;
    is($queue->size(), 3, 'Two messages pushed, queue size is 3.');
    push @sent_msg_ids, @msg_send_ids_02;

    my $number_of_msgs_sent = $queue->post_messages( 'messages' => [ @send_messages[3,4,5,6,7] ] );
    is($number_of_msgs_sent, 5, '5 more messages pushed.');
    is($queue->size(), 8, '5 more messages pushed, queue size is 8.');
    diag('Total 8 messages pushed to queue.');

};

# Let's pull some messages.
my @msg_pulls;
subtest 'Pulled messages match with the sent messages.' => sub {
    plan tests => 16;
    @msg_pulls = $queue->reserve_messages( 'n' => 10, 'timeout' => 120 );
    is( scalar @msg_pulls, 8, 'Pulled 8 messages.');
    my $yaml_de = YAML::Tiny->new(); $yaml_de = $yaml_de->read_string($msg_pulls[1]->body());
    is_deeply($yaml_de->[0], \%msg_body_hash_02, '#2 message body after serialization matches with the sent message body.');
    is( $msg_pulls[0]->id(), $sent_msg_ids[0], 'Pulled two, ids match with the sent ids.');
    is( $msg_pulls[1]->id(), $sent_msg_ids[1], 'Pulled two, ids match with the sent ids.');
    is( $msg_pulls[2]->id(), $sent_msg_ids[2], 'Pulled two, ids match with the sent ids.');
    #is_deeply( [$msg_pulls[0..2]], \@sent_msg_ids, 'Ids match with sent messages.')
    # msg #7 has JSON encoded body
    require JSON::MaybeXS;
    my $json = JSON::MaybeXS->new(utf8 => 1, pretty => 1);
    is_deeply($json->decode($msg_pulls[6]->body()), \%msg_body_hash_02, '#7 message body after serialization matches with the sent message body.');
    # msg #8 has Storable encoded body
    require Storable;
    is_deeply(Storable::thaw($msg_pulls[7]->body()), \%msg_body_hash_02, '#8 message body after serialization matches with the sent message body.');

    is($queue->size(), 8, 'Three messages pulled in total; put queue size is still 8. (pull does not delete messages.)');
    diag('Pulled 8 messages from queue.');
    foreach (0..7) {
        my $pushed_body = $msg_pulls[$_]->body();
        my $pulled_body = $send_messages[$_]->body();
        #diag('Message number $_:\nPushed body: $pushed_body, dumped:\n' . Dumper($pushed_body) . ' is utf8:' . utf8::is_utf8($pushed_body) . ';\n Pulled body: $pulled_body, dumped:\n' . Dumper($pulled_body) . ' is utf8:' . utf8::is_utf8($pulled_body) . '.');
        is($msg_pulls[$_]->body(), $send_messages[$_]->body(), "Message number $_: pulled body matches pushed body.");
    }
};

subtest 'Clean up after us.' => sub {
    plan tests => 2;
    # Let's clear the queue
    $queue->clear_messages();
    is($queue->size(), 0, 'Cleared the queue, queue size is 0.');
    diag('Cleared the queue, queue size is 0.');

    # Delete queue. Confirm deletion.
    $iron_mq_client->delete_queue( 'name' => $queue_name);
    throws_ok {
        my $dummy = $iron_mq_client->get_queue( 'name' => $queue_name);
    } '/IronHTTPCallException: status_code=404/',
    # IronHTTPCallException: status_code=404 response_message=Queue not found
    # status code 404: server could not find what was requested! Response message can change, code remains 404!
            'Throw IronHTTPCallException when no message queue of given name.';
    diag('Definately deleted message queue ' . $queue->name() . q{'.});
    diag('All cleaned up.')
};

