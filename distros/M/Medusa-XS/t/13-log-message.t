#!perl
use 5.010;
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

use Medusa::XS;

# Replace logger with mock
$Medusa::XS::LOG{LOG} = MockLogger->new();

# Test: log_message with single string
{
    MockLogger->clear();
    Medusa::XS::log_message(message => "Simple message");
    is(scalar @MockLogger::MESSAGES, 1, 'one message logged');
    like($MockLogger::MESSAGES[0]{msg}, qr/Simple message/, 'message content correct');
}

# Test: log_message with arguments
{
    MockLogger->clear();
    Medusa::XS::log_message(message => "With args:", params => ["value1", "value2"], prefix => 'args');
    is(scalar @MockLogger::MESSAGES, 1, 'one message logged with args');
    like($MockLogger::MESSAGES[0]{msg}, qr/With args:/, 'message prefix present');
    like($MockLogger::MESSAGES[0]{msg}, qr/value1/, 'first arg in message');
    like($MockLogger::MESSAGES[0]{msg}, qr/value2/, 'second arg in message');
}

done_testing();
