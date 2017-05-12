#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 24;
use Mail::Log::Exceptions;

BASE: {
# Throw one to catch.
eval { Mail::Log::Exceptions->throw('Test Exception.') };

my $test_val = Mail::Log::Exceptions->caught();
ok(defined($test_val), 'Caught returns defined variable.');
isa_ok($test_val, 'Mail::Log::Exceptions', 'Generic throw/catch.');

is($test_val->description(), 'A generic Mail::Log::Exception.', 'Base description exists.');
is($test_val->message(), 'Test Exception.', 'Base message exists.');
is($test_val->error(), 'Test Exception.', 'Base error exists.');
is($test_val->as_string(), 'Test Exception.', 'Base as_string exists.');
}

UNIMPLEMENTED: {
# Throw one to catch.
eval { Mail::Log::Exceptions::Unimplemented->throw('Test Exception.') };

my $test_val = Mail::Log::Exceptions->caught();
ok(defined($test_val), '(Unimplemented) Caught returns defined variable.');
isa_ok($test_val, 'Mail::Log::Exceptions::Unimplemented', 'Unimplemented throw/catch.');

is($test_val->description(), 'Stuff that should be implemented by subclasses.', 'Unimplemented description exists.');
is($test_val->message(), 'Test Exception.', 'Unimplemented message exists.');
is($test_val->error(), 'Test Exception.', 'Unimplemented error exists.');
is($test_val->as_string(), 'Test Exception.', 'Unimplemented as_string exists.');
}

LOGFILE: {
# Throw one to catch.
eval { Mail::Log::Exceptions::LogFile->throw('Test Exception.') };

my $test_val = Mail::Log::Exceptions->caught();
ok(defined($test_val), '(LogFile) Caught returns defined variable.');
isa_ok($test_val, 'Mail::Log::Exceptions::LogFile', 'LogFile throw/catch.');

is($test_val->description(), 'An error with the logfile.','LogFile description exists.');
is($test_val->message(), 'Test Exception.','LogFile message exists.');
is($test_val->error(), 'Test Exception.','LogFile error exists.');
is($test_val->as_string(), 'Test Exception.','LogFile as_string exists.');
}

MESSAGE: {
# Throw one to catch.
eval { Mail::Log::Exceptions::Message->throw('Test Exception.') };

my $test_val = Mail::Log::Exceptions->caught();
ok(defined($test_val), '(Message) Caught returns defined variable.');
isa_ok($test_val, 'Mail::Log::Exceptions::Message', 'Message throw/catch.');

is($test_val->description(), 'An error with the message info.','Message description exists.');
is($test_val->message(), 'Test Exception.','Message message exists.');
is($test_val->error(), 'Test Exception.','Message error exists.');
is($test_val->as_string(), 'Test Exception.','Message as_string exists.');
}
