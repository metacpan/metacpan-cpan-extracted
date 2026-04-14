#!/usr/bin/env perl
# freezing and thawing a message object

use warnings;
use strict;

use Test::More;
use Scalar::Util 'refaddr';

use Log::Report;
use Log::Report::Message;
#use Data::Dumper;

my $LR_VERSION = $Log::Report::VERSION // '3.14';

###
### Simple
###

my $msg1 = Log::Report::Message->new(
	_domain => 'test',
	_msgid  => 'the answer is {var}!',
	_tags   => 'monkey, donkey',
	var     => 42,
	_expand => 1,
);

ok defined $msg1, 'created message manually';
isa_ok $msg1, 'Log::Report::Message', '...';

### Freeze

my $msg1f = $msg1->freeze;
ok defined $msg1f, 'Freeze';

#warn Dumper $msg1f;

is_deeply $msg1f, {
	_domain => 'test',
	_msgid  => 'the answer is {var}!',
	_tags   => [ qw/monkey donkey/ ],
	_expand => 1,
	var     => 42,

	_join   => ' ',
	_lr_version => $LR_VERSION,
}, '... content';

### Thaw

my $msg1t = Log::Report::Message->thaw($msg1f);
ok defined $msg1t, 'Thaw';
isa_ok $msg1t, 'Log::Report::Message', '...';
is $msg1t->msgid, 'the answer is {var}!', '... msgid';
is $msg1t->domain, 'test', '... domain';
ok $msg1t->taggedWith('monkey'), '... tag1';
ok $msg1t->taggedWith('donkey'), '... tag2';
is $msg1t->valueOf('var'), 42, '... var';

###
### Nested
###

my $msg2 = (__x"before") . $msg1 . (__x"after", _domain => textdomain 'default');

ok defined $msg2, 'created message with append and prepend';
isa_ok $msg2, 'Log::Report::Message', '...';
#warn Dumper $msg2;

### freeze

my $msg2f = $msg2->freeze;
ok defined $msg2f, 'Frozen complex';
is ref $msg2f, 'HASH', '... HASH output';
#warn Dumper $msg2f;

# unsafe during distribution
$msg2f->{_use} = 'REMOVED';
$msg2f->{_append}{_append}{_use} = 'REMOVED';

is_deeply $msg2f, +{
   _msgid  => 'before',
   _domain => 'default',
   _append => {
      _msgid  => 'the answer is {var}!',
      var     => 42,
      _tags   => [ qw/monkey donkey/ ],
      _expand => 1,
      _append => {
          _msgid  => 'after',
          _expand => 1,
          _join   => ' ',
          _domain => 'default',
          _use    => 'REMOVED',
          _lr_version => $LR_VERSION,
      },
      _domain => 'test',
      _join   => ' ',
      _lr_version => $LR_VERSION,
   },
   _join   => ' ',
   _expand => 1,
   _use    => 'REMOVED',
   _lr_version => $LR_VERSION,
}, '... no objects';

### thaw

my $msg2t = Log::Report::Message->thaw($msg2f);
ok defined $msg2t, 'Thaw complex';
isa_ok $msg2t, 'Log::Report::Message', '... before, ';
isa_ok $msg2t->append, 'Log::Report::Message', '... middle, ';
isa_ok $msg2t->append->append, 'Log::Report::Message', '... after,';
is $msg2t->toString, 'beforethe answer is 42!after', '... string';

done_testing;
