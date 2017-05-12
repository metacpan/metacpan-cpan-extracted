#!/usr/bin/env perl
#
# Test the refolding of fields
#

use strict;
use warnings;

use Mail::Message::Test;

use Test::More tests => 32;
use Scalar::Util      qw/refaddr/;

#
# FAST FIELDS
#

use Mail::Message::Field::Fast;
my $fast = 'Mail::Message::Field::Fast';

my $fast1 = $fast->new(Name => 'body');
ok(defined $fast1,                                    'fast field created');
isa_ok($fast1, $fast);
is($fast1->unfoldedBody, 'body');
is($fast1->foldedBody, " body\n");

my $fast2 = $fast1->setWrapLength;
is(refaddr $fast1, refaddr $fast2,                       'empty wrap');
is($fast2->unfoldedBody, 'body');
is($fast2->foldedBody, " body\n");

my $fast3 = $fast1->setWrapLength(34);
is(refaddr $fast1, refaddr $fast3,                       'wrap much longer');
is($fast3->unfoldedBody, 'body');
is($fast3->foldedBody, " body\n");

my $long = 'this is very long field, which has no folding yet';
my $fast4 = $fast->new(Name => $long);
is($fast4->unfoldedBody, $long);
is($fast4->foldedBody, " $long\n",                    'long folding');

my $llong = 'this line is longer than the default fold of 78 characters. It should get folded more than once. Wow, 78 characters it quite a lot, you know!  Are we on the third line already?';

my $fast5 = $fast->new(Name => $llong);
is($fast5->unfoldedBody, $llong);
is($fast5->foldedBody, <<__LLONG,                     'llong folding');
 this line is longer than the default fold of 78 characters. It should
 get folded more than once. Wow, 78 characters it quite a lot,
 you know!  Are we on the third line already?
__LLONG

$fast5->setWrapLength(30);
is($fast5->foldedBody, <<__LLONG,                     'llong folding at 30');
 this line is longer than
 the default fold of 78
 characters. It should get
 folded more than once. Wow,
 78 characters it quite a lot,
 you know!  Are we on the
 third line already?
__LLONG

$fast5->setWrapLength(100);
is($fast5->foldedBody, <<__LLONG,                     'llong folding at 100');
 this line is longer than the default fold of 78 characters. It should get folded more than
 once. Wow, 78 characters it quite a lot, you know!  Are we on the third line already?
__LLONG

#
# FLEX FIELDS
#

use Mail::Message::Field::Flex;
my $flex = 'Mail::Message::Field::Flex';

my $flex1 = $flex->new(Name => 'body');
ok(defined $flex1,                                    'flex field created');
isa_ok($flex1, $flex);
is($flex1->unfoldedBody, 'body');
is($flex1->foldedBody, " body\n");

my $flex2 = $flex1->setWrapLength;
is(refaddr $flex1, refaddr $flex2,                       'empty wrap');
is($flex2->unfoldedBody, 'body');
is($flex2->foldedBody, " body\n");

my $flex3 = $flex1->setWrapLength(34);
is(refaddr $flex1, refaddr $flex3,                       'wrap much longer');
is($flex3->unfoldedBody, 'body');
is($flex3->foldedBody, " body\n");

my $flex4 = $flex->new(Name => $long);
is($flex4->unfoldedBody, $long);
is($flex4->foldedBody, " $long\n",                    'long folding');

my $flex5 = $flex->new(Name => $llong);
is($flex5->unfoldedBody, $llong);
is($flex5->foldedBody, <<__LLONG,                     'llong folding');
 this line is longer than the default fold of 78 characters. It should
 get folded more than once. Wow, 78 characters it quite a lot,
 you know!  Are we on the third line already?
__LLONG

$flex5->setWrapLength(30);
is($flex5->foldedBody, <<__LLONG,                     'llong folding at 30');
 this line is longer than
 the default fold of 78
 characters. It should get
 folded more than once. Wow,
 78 characters it quite a lot,
 you know!  Are we on the
 third line already?
__LLONG

$flex5->setWrapLength(100);
is($flex5->foldedBody, <<__LLONG,                     'llong folding at 100');
 this line is longer than the default fold of 78 characters. It should get folded more than
 once. Wow, 78 characters it quite a lot, you know!  Are we on the third line already?
__LLONG
