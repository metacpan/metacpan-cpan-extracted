#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 8;

# Create a custom logger class
{
    package My::CustomLogger;
    our @LOG_ENTRIES;
    
    sub new {
        my ($class, %args) = @_;
        @LOG_ENTRIES = ();
        return bless \%args, $class;
    }
    
    sub debug {
        my ($self, $msg) = @_;
        push @LOG_ENTRIES, "[DEBUG] $msg";
    }
    
    sub info {
        my ($self, $msg) = @_;
        push @LOG_ENTRIES, "[INFO] $msg";
    }
    
    sub error {
        my ($self, $msg) = @_;
        push @LOG_ENTRIES, "[ERROR] $msg";
    }
}

# Set up custom logger BEFORE defining audited subs
BEGIN {
    require Medusa::XS;
    $Medusa::XS::LOG{LOG} = My::CustomLogger->new();
    $Medusa::XS::LOG{LOG_LEVEL} = 'debug';
}

{
    package TestCustomLogger;
    use Medusa::XS;
    
    sub my_method :Audit {
        my ($self, $x) = @_;
        return $x * 2;
    }

    sub my_method2 :Audit(error) {
        my ($self, $x) = @_;
        return $x * 2;
    }
}

# Call the audited method
TestCustomLogger->my_method(5);

# Test: custom logger received messages
ok(scalar @My::CustomLogger::LOG_ENTRIES >= 2, 'custom logger received log entries');

# Test: messages have correct format
my $has_call = grep { /my_method called/ } @My::CustomLogger::LOG_ENTRIES;
my $has_return = grep { /my_method returned/ } @My::CustomLogger::LOG_ENTRIES;

ok($has_call, 'custom logger captured call message');
ok($has_return, 'custom logger captured return message');

# Test: LOG_LEVEL is set correctly
is($Medusa::XS::LOG{LOG_LEVEL}, 'debug', 'LOG_LEVEL is set to debug');

is(TestCustomLogger->my_method2(5), 10, 'check returned value');

ok(scalar @My::CustomLogger::LOG_ENTRIES >= 4, 'custom logger received log entries');

# Test: messages have correct format
$has_call = grep { /my_method2 called/ } @My::CustomLogger::LOG_ENTRIES;
$has_return = grep { /my_method2 returned/ } @My::CustomLogger::LOG_ENTRIES;

ok($has_call, 'custom logger captured call message');
ok($has_return, 'custom logger captured return message');

done_testing();
