#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use Log::Dispatch;
use Log::Dispatch::Twilio;
use Sub::Override;

###############################################################################
### TEST PARAMETERS
my %params = (
  account_sid => 'XXX-ACCOUNT-SID-XXX',
  auth_token  => 'XXX-AUTH-TOKEN-XXX',
  from        => '1-604-555-1212',
  to          => '1-250-555-1212',
);


###############################################################################
subtest 'Required parameters' => sub {
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
};

###############################################################################
subtest 'Instantiation' => sub {
  my $output = Log::Dispatch::Twilio->new(
    name      => 'twilio',
    min_level => 'debug',
    %params,
  );
  isa_ok $output, 'Log::Dispatch::Twilio';
};

###############################################################################
subtest 'Instantiation via Log::Dispatch' => sub {
  my $logger = Log::Dispatch->new(
    outputs => [
      [
        'Twilio',
        name      => 'twilio',
        min_level => 'debug',
        %params,
      ],
    ],
  );
  isa_ok $logger, 'Log::Dispatch';

  my $output = $logger->output('twilio');
  isa_ok $output, 'Log::Dispatch::Twilio';
};

###############################################################################
subtest 'Logging test' => sub {
  my $logger = Log::Dispatch->new(
    outputs => [
      [ 'Twilio',
        name      => 'twilio',
        min_level => 'debug',
        %params,
      ],
    ],
  );

  subtest 'Successful log' => sub {
    # ... capture calls to "warn"
    my @messages;
    local $SIG{__WARN__} = sub { push @messages, @_ };
    # ... mock the POST response, and capture the message
    my $body;
    my $guard = Sub::Override->new('WWW::Twilio::API::POST' => sub {
      my ($self, $endpoint, %args) = @_;
      $body = $args{Body};
      return +{
        message => 'Created',
        code    => 201,
        content => 'XXX-NO-REAL-CONTENT-XXX',
      };
    } );
    # ... log our message, verify the results
    $logger->info('test');

    ok $body, 'Logging call sent to Twilio';
    is $body, 'test', '... logging our message';
    ok !@messages, '... and no warnings recorded';
  };

  subtest 'Failed to send' => sub {
    # ... capture calls to "warn"
    my @messages;
    local $SIG{__WARN__} = sub { push @messages, @_ };
    # ... mock the POST response, and capture the message
    my $body;
    my $guard = Sub::Override->new('WWW::Twilio::API::POST' => sub {
      my ($self, $endpoint, %args) = @_;
      $body = $args{Body};
      return +{
        message => 'Nope, no worky',
        code    => 400,
        content => 'XXX-NO-REAL-CONTENT-XXX',
      };
    } );
    # ... log our message, verify the results
    $logger->info('test');

    ok $body, 'Logging call sent to Twilio';
    ok @messages, '... and warnings recorded';
    like $messages[0], qr/Failed to send/, '... ... failed to send';
    like $messages[0], qr/XXX-NO-REAL-CONTENT-XXX/, '... ... including returned content';
  };
};

###############################################################################
subtest 'Long messages are truncated by defaut' => sub {
  my $logger = Log::Dispatch::Twilio->new(
    name      => 'twilio',
    min_level => 'debug',
    %params,
  );

  local $Log::Dispatch::Twilio::MAX_TWILIO_LENGTH = 10;
  my $message  = '1234567890abcdefghijklmnop';
  my @expanded = $logger->_expand_message($message);
  is @expanded, 1, 'Long message auto-truncated by default';
  is $expanded[0], '1234567890', '... and truncated at correct point';
};

###############################################################################
subtest 'Long messages can be split' => sub {
  my $logger = Log::Dispatch::Twilio->new(
    name         => 'twilio',
    min_level    => 'debug',
    max_messages => 3,
    %params,
  );

  subtest 'short messages' => sub {
    my $message  = "w00t!";
    my @expanded = $logger->_expand_message($message);
    is @expanded, 1, 'Short message expanded to one message';
  };

  subtest 'reaching max messages' => sub {
    local $Log::Dispatch::Twilio::MAX_TWILIO_LENGTH = 10;
    my $message  = '1234567890abcdefghijklmnop';
    my @expanded = $logger->_expand_message($message);
    is @expanded, 3, 'Long message truncated to max number of messages';
    is $expanded[0], '1/3: 12345', '... first message truncated to length';
    is $expanded[1], '2/3: 67890', '... second message truncated to length';
    is $expanded[2], '3/3: abcde', '... third message truncated to length';
  };

  subtest 'not quite hitting max messages' => sub {
    local $Log::Dispatch::Twilio::MAX_TWILIO_LENGTH = 15;
    my $message  = '1234567890abcdefg';
    my @expanded = $logger->_expand_message($message);
    is @expanded, 2, 'Long message truncated to max number of messages';
    is $expanded[0], '1/2: 1234567890', '... first message truncated to length';
    is $expanded[1], '2/2: abcdefg',    '... second message complete';
  };
};

###############################################################################
subtest 'Leading/trailing whitespace gets trimmed' => sub {
  my $logger = Log::Dispatch::Twilio->new(
    name      => 'twilio',
    min_level => 'debug',
    %params,
  );

  my $message  = "   no whitespace here    ";
  my @expanded = $logger->_expand_message($message);
  is $expanded[0], 'no whitespace here', 'Leading/trailing whitespace stripped';
};

###############################################################################
done_testing();
