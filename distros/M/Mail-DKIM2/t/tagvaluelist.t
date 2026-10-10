use strict;
use warnings;
use Test::More;
use Mail::DKIM2::Signature;

# parse() is a constructor. Called on an existing object it used to parse
# into that object without clearing it, so a d= from the old value survived
# while serialization dropped it (review: TagValueList instance parsing).

my $old = Mail::DKIM2::Signature->parse('i=1; m=1; d=old.example');
my $new = $old->parse('i=2; m=2');
is($new->domain, undef, 'no d= carried over from the invocant');
is($new->get_tag('i'), 2, 'the new value is parsed');
is($old->domain, 'old.example', 'the invocant is untouched');
is($old->get_tag('i'), 1, 'the invocant keeps its own tags');

my $dup = Mail::DKIM2::Signature->parse('i=1; i=2');
is($dup->duplicate_tag, 'i', 'a repeat is flagged');
is($dup->parse('i=1; m=1')->duplicate_tag, undef,
    'the flag does not survive into a fresh parse');

done_testing;
