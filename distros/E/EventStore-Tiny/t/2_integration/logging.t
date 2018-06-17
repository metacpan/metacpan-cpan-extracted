use strict;
use warnings;

use Test::More;
use File::Temp qw(tempfile);

use EventStore::Tiny;
use EventStore::Tiny::DataEvent;

# prepare test "file handle"
package TestFileHandle;
use Mo qw(default);
has history => [];
sub print {push @{shift->history}, shift}
sub length {scalar @{shift->history}}
1;
package main;
my $print_target = TestFileHandle->new;

subtest 'Default logger' => sub {

    # prepare logger
    use_ok 'EventStore::Tiny::Logger';
    my $logger = EventStore::Tiny::Logger->new(print_target => $print_target);

    # log a dummy event
    $logger->log(EventStore::Tiny::DataEvent->new(
        name => 'TestEventStored',
        data => {a => 17, b => 42},
    ));
    is $print_target->length => 1, 'Correct event history size';
    my $log_str = $print_target->history->[0];
    is $log_str => "TestEventStored: { a => 17, b => 42 }\n",
        'Correct event string representation logged';

    subtest 'Callback generation' => sub {

        subtest 'Method call' => sub {

            # generate
            my $log_cb = $logger->log_cb;
            is ref($log_cb) => 'CODE', 'Subroutine reference generated';

            # log a dummy event
            $log_cb->(EventStore::Tiny::DataEvent->new(
                name => 'TestEventStored',
                data => {foo => 1, bar => 2},
            ));

            # test
            is $print_target->length => 2, 'Correct event history size';
            my $log_str = $print_target->history->[1];
            is $log_str => "TestEventStored: { bar => 2, foo => 1 }\n",
                'Correct event string representation logged';
        };

        subtest 'Package subroutine call' => sub {

            # generate
            my $log_cb = EventStore::Tiny::Logger->log_cb(
                print_target => $print_target
            );

            # log a dummy event
            $log_cb->(EventStore::Tiny::DataEvent->new(
                name => 'TestEventStored',
                data => {bar => 2, baz => 3},
            ));

            # test
            is $print_target->length => 3, 'Correct event history size';
            my $log_str = $print_target->history->[2];
            is $log_str => "TestEventStored: { bar => 2, baz => 3 }\n",
                'Correct event string representation logged';
        };
    };

    subtest 'Default logging target STDOUT' => sub {

        # redirect STDOUT
        my ($tmp_fh, $tmp_fn) = tempfile;
        select $tmp_fh;

        # create without print target
        my $logger = EventStore::Tiny::Logger->new;

        # log a dummy event
        $logger->log(EventStore::Tiny::DataEvent->new(
            name => 'TestEventStored',
            data => {baz => 17, quux => 42},
        ));

        # restore STDOUT
        select STDOUT;
        close $tmp_fh;

        # check results in temporary file
        open $tmp_fh, '<', $tmp_fn or die "Couldn't open $tmp_fn: $!\n";
        my $tmp = do {local $/; <$tmp_fh>};
        is $tmp => "TestEventStored: { baz => 17, quux => 42 }\n",
            'Correct event string representation logged to file';
    };
};

subtest 'Integration' => sub {

    my $es = EventStore::Tiny->new(
        logger => EventStore::Tiny::Logger->log_cb(
            print_target => $print_target
        ),
    );

    # log and apply a dummy event
    $es->register_event(TestEventStored => sub {});
    $es->store_event(TestEventStored => {x => 'y', p => 'q'});
    $es->snapshot;

    # test
    is $print_target->length => 4, 'Correct event history size';
    my $log_str = $print_target->history->[3];
    is $log_str => "TestEventStored: { p => \"q\", x => \"y\" }\n",
        'Correct event string representation logged';

    subtest 'Update logger' => sub {

        # prepare new logger
        my $tmp_print_target = TestFileHandle->new;
        my $logger = EventStore::Tiny::Logger->log_cb(
            print_target => $tmp_print_target,
        );

        # inject
        $es->logger($logger);

        # add another event
        $es->store_event(TestEventStored => {x => 'q', p => 'y'});
        $es->snapshot;

        # old logger unchanged
        is $print_target->length => 4, 'Correct old history size';
        is $tmp_print_target->length => 1, 'Correct new history size';
        my $log_str = $tmp_print_target->history->[0];
        is $log_str => "TestEventStored: { p => \"y\", x => \"q\" }\n",
            'Correct event string representation logged';
    };
};

done_testing;
