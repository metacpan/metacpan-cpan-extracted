#!/usr/bin/env perl
#
# Test processing of comments in fields.  GitHub issue #6
#

use strict;
use warnings;

use Test::More;

use Mail::Message::Field::Full;

my @tests = (
  # pattern            results in address
  [ '1: one \(two\) (three)',           0, undef ],
  [ '2: one (two (three) four)',        1, 'one' ],
  [ '3: one (two (three) four',         1, 'one four' ],
  [ '4: one (two \( (three) four)',     1, 'one' ],
  [ '5: one (two (three) \) four)',     1, 'one' ],
  [ '6: one (two (three) four \) five', 1, 'one five' ],
  [ '7: one (two \\',                   0, undef ],
  [ '8: one (two (three) four \\',      0, undef ],
  [ '9: one (two (three (four) five',   1, 'one five' ],
  [ '10: one ()',                       1, 'one' ],
);

### Shouldn't die address parsing (may produce bad results)

foreach (@tests)
{   my ($comment, $valid_email, $phrase) = @$_;
    my $header = "To: $comment <me\@home.nl>";
    my $f = Mail::Message::Field::Full->new($header);
    ok defined $f, "test address $comment";
    isa_ok $f, 'Mail::Message::Field::Addresses', '...';

    my @addresses = $f->addresses;
    if($valid_email)
    {
        cmp_ok scalar @addresses, '==', 1, "... valid email";
        my $address = $addresses[0];
        is $address->phrase, $phrase, '... phrase';
    }
    else
    {
        cmp_ok scalar @addresses, '==', 0, "... invalid email";
    }
}


### Shouldn't die generic structured fields

foreach (@tests)
{   my ($ct, undef) = @$_;
    my $header = "Content-Type: $ct";
    my $f = Mail::Message::Field::Full->new($header);
    ok defined $f, "test ct $ct";
    isa_ok $f, 'Mail::Message::Field::Structured', '...';
    is $f->body, $ct, '... body';
    is $f->comment, '';
}

done_testing;
