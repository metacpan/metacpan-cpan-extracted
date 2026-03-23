#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

plan tests => 6;

my $tempdir = tempdir(CLEANUP => 1);

# Create a mock logger to capture messages
{
    package MockLogger;
    our @MESSAGES;
    
    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    
    sub debug {
        my ($self, $msg) = @_;
        push @MESSAGES, { level => 'debug', msg => $msg };
    }
    
    sub info {
        my ($self, $msg) = @_;
        push @MESSAGES, { level => 'info', msg => $msg };
    }
    
    sub error {
        my ($self, $msg) = @_;
        push @MESSAGES, { level => 'error', msg => $msg };
    }
    
    sub clear {
        @MESSAGES = ();
    }
}

use Medusa;

# Replace logger with mock
$Medusa::LOG{LOG} = MockLogger->new();

# Test: log_message with single string
{
    MockLogger->clear();
    Medusa::log_message(message => "Simple message");
    is(scalar @MockLogger::MESSAGES, 1, 'one message logged');
    is($MockLogger::MESSAGES[0]{msg}, "Simple message", 'message content correct');
}

# Test: log_message with arguments
{
    MockLogger->clear();
    Medusa::log_message(message => "With args:", params => ["value1", "value2"]);
    is(scalar @MockLogger::MESSAGES, 1, 'one message logged with args');
    like($MockLogger::MESSAGES[0]{msg}, qr/With args:/, 'message prefix present');
    like($MockLogger::MESSAGES[0]{msg}, qr/value1/, 'first arg in message');
    like($MockLogger::MESSAGES[0]{msg}, qr/value2/, 'second arg in message');
}

done_testing();
