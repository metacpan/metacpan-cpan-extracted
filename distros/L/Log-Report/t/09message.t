#!/usr/bin/env perl
# Try constructing a message object

use warnings;
use strict;

use Test::More tests => 22;
use Scalar::Util 'refaddr';

use Log::Report;
use Log::Report::Message;

### direct creation

my $msg = Log::Report::Message->new
 ( _msgid => 'try'
 , _domain => 'test'
 , _class  => 'monkey, donkey'
 , var     => 42
 );

ok(defined $msg, 'created message manually');
isa_ok($msg, 'Log::Report::Message');
is($msg->msgid, 'try');
is($msg->domain, 'test');
is($msg->valueOf('_domain'), 'test');
is($msg->valueOf('var'), 42);

my @c = $msg->classes;
cmp_ok(scalar @c, '==', 2, 'list classes');
is($c[0], 'monkey');
is($c[1], 'donkey');

ok($msg->inClass('monkey'), 'inClass');
ok($msg->inClass('donkey'));
is($msg->inClass( qr/^d/ ), 'donkey');
is($msg->inClass( qr/key/ ), 'monkey');

### indirect creation, non-translated

try { report ERROR => 'not translated', _classes => 'one two' };
my $err = $@;
isa_ok($err, 'Log::Report::Dispatcher::Try');
my $fatal = $err->wasFatal;
isa_ok($fatal, 'Log::Report::Exception');
my $message = $fatal->message;
isa_ok($message, 'Log::Report::Message');

is("$message", 'not translated', 'untranslated');
is($message->inClass('one'), 'one');
is($message->inClass('two'), 'two');
is($fatal->inClass('two'), 'two');

my $fatal2 = $err->wasFatal(class => 'two');
isa_ok($fatal2, 'Log::Report::Exception');
cmp_ok(refaddr $fatal, '==', refaddr $fatal2);
