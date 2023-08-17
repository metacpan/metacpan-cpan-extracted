#!/usr/bin/env perl
# Test the auto-detection of the character-set

use strict;
use warnings;
use utf8;

use Test::More;
use Encode qw(encode decode);

use Mail::Message::Body;

sub _body($)
{   my $body = shift;
    $body->type . "\n" . "$body";
}

my $body1 = Mail::Message::Body->new
  ( mime_type => 'text/plain'
  , data      => "ascii text\n"
  );

ok defined $body1, 'ascii text, no charset';

### auto-detect ascii, no change

is _body($body1->encode), <<__EXPECT, '... no change, us-ascii to us-ascii';
text/plain; charset="PERL"
ascii text
__EXPECT

### auto-detect ascii, change to latin1

is _body($body1->encode(charset => 'latin1')), <<__EXPECT, '... no change, us-ascii to us-ascii';
text/plain; charset="latin1"
ascii text
__EXPECT

### auto-detect utf8, change to latin1

my $body2 = Mail::Message::Body->new
  ( mime_type => 'text/plain'
  , data      => "utf8 ßüß text\n"
  );

ok defined $body2, 'utf8 flagged text';

my $e2 = _body($body2->encode(charset => 'utf-8'));
ok ! utf8::is_utf8($e2), '... check utf-8 as bytes';
is decode('UTF-8', $e2), <<__EXPECT, '... internal utf8 to utf-8';
text/plain; charset="utf-8"
utf8 ßüß text
__EXPECT

### auto-detect cp1252
# The test runs with latin1 characters, because in older versions of Perl, the
# default string encoding was the smaller latin1 set.

my $body3 = Mail::Message::Body->new
  ( mime_type => 'text/plain'
  , data      => "cp1252 \xA2\xAE text\n"
  );

ok defined $body3, 'cp1252 flagged text';

my $e3 = _body($body3->encode(charset => 'utf-8'));
ok ! utf8::is_utf8($e3), '... check utf-8 as bytes';
is decode('UTF-8', $e3), <<__EXPECT, '... detected cp1252 to utf-8';
text/plain; charset="utf-8"
cp1252 ¢® text
__EXPECT

done_testing;
