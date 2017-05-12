#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Log::Dispatch;
use Log::Dispatch::Twilio;

###############################################################################
### Ensure that we have all of the ENV vars we need for testing.
unless ($ENV{TWILIO_ACCOUNT_SID}) {
    plan skip_all => "TWILIO_ACCOUNT_SID must be set in your environment for testing.";
}
unless ($ENV{TWILIO_ACCOUNT_TOKEN}) {
    plan skip_all => "TWILIO_ACCOUNT_TOKEN must be set in your environment for testing.";
}
unless ($ENV{TWILIO_FROM}) {
    plan skip_all => "TWILIO_FROM must be set in your environment for testing.";
}
unless ($ENV{TWILIO_TO}) {
    plan skip_all => "TWILIO_TO must be set in your environment for testing.";
}
plan tests => 12;

###############################################################################
### TEST PARAMETERS
my %params = (
    account_sid => $ENV{TWILIO_ACCOUNT_SID},
    auth_token  => $ENV{TWILIO_ACCOUNT_TOKEN},
    from        => $ENV{TWILIO_FROM},
    to          => $ENV{TWILIO_TO},
);

###############################################################################
# Required parameters for instantiation.
required_parameters: {
    foreach my $p (sort keys %params) {
        my %data = %params;
        delete $data{$p};

        my $output = eval {
            Log::Dispatch::Twilio->new(
                name      => 'twilio',
                min_level => 'debug',
                %data,
            );
        };
        like $@, qr/requires '$p' parameter/, "$p is required parameter";
    }
}

###############################################################################
# Instantiation.
instantiation: {
    my $output = Log::Dispatch::Twilio->new(
        name      => 'twilio',
        min_level => 'debug',
        %params,
    );
    isa_ok $output, 'Log::Dispatch::Twilio';
}

###############################################################################
# Instantiation via Log::Dispatch;
instantiation_via_log_dispatch: {
    my $logger = Log::Dispatch->new(
        outputs => [
            ['Twilio',
                name      => 'twilio',
                min_level => 'debug',
                %params,
            ],
        ],
    );
    isa_ok $logger, 'Log::Dispatch';

    my $output = $logger->output('twilio');
    isa_ok $output, 'Log::Dispatch::Twilio';
}

###############################################################################
# Logging test
logging_test: {
    my $logger = Log::Dispatch->new(
        outputs => [
            ['Twilio',
                name      => 'twilio',
                min_level => 'debug',
                %params,
            ],
        ],
    );

    my @messages;
    local $SIG{__WARN__} = sub { push @messages, @_ };
    $logger->info("test message, logged via Twilio");

    ok !@messages, 'Message logged via Twilio';
}

###############################################################################
# Long messages are truncated by default
truncate_by_default: {
    my $logger = Log::Dispatch::Twilio->new(
        name      => 'twilio',
        min_level => 'debug',
        %params,
    );

    my $message
        = "This is a really long test message, so that I can verify that we "
        . "properly truncate it at 160 chars.  Only one message should be "
        . "sent to Twilio when I send this lengthy statement; it'd be "
        . "truncated automatically.";

    my @expanded = $logger->_expand_message($message);
    is @expanded, 1, 'Long message auto-truncated by default';
}

###############################################################################
# Long messages can be exploded out to multiple messages.
multiple_messages: {
    my $logger = Log::Dispatch::Twilio->new(
        name         => 'twilio',
        min_level    => 'debug',
        max_messages => 2,
        %params,
    );

    my $message
        = "This message is also really long.  This one helps test that we can "
        . "properly slice up the log message across multiple SMS messages, "
        . "even when its too big to fit.  Further, if we have more text than "
        . "we can fit into the configured number of SMS messages, the rest "
        . "just gets truncated and is gone.  No muss, no fuss, no extra "
        . "messages getting generated for no reason.";

    my @expanded = $logger->_expand_message($message);
    is @expanded, 2, 'Long message truncated to max number of messages';
}

###############################################################################
# Short messages don't generate multiples, even when configured
short_messages_stay_short: {
    my $logger = Log::Dispatch::Twilio->new(
        name         => 'twilio',
        min_level    => 'debug',
        max_messages => 9,
        %params,
    );

    my $message  = "w00t!";
    my @expanded = $logger->_expand_message($message);
    is @expanded, 1, 'Short message expanded to one message';
}

###############################################################################
# Messages have leading/trailing whitespace trimmed from them automatically.
whitespace_trimmed: {
    my $logger = Log::Dispatch::Twilio->new(
        name         => 'twilio',
        min_level    => 'debug',
        max_messages => 9,
        %params,
    );

    my $message  = "   no whitespace here    ";
    my @expanded = $logger->_expand_message($message);
    is $expanded[0], 'no whitespace here',
        'Leading/trailing whitespace stripped';
}
