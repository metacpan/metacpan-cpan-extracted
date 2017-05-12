use Test::More;
use strict; use warnings FATAL => 'all';

use IRC::Toolkit::Case;

is lc_irc('ABC[]', 'ascii'), 'abc[]', 'ascii lc ok';
is uc_irc('abc[]', 'ascii'), 'ABC[]', 'ascii uc ok';

is lc_irc('Nick^[Abc]', 'strict-rfc1459'), 'nick^{abc}', 
  'strict-rfc1459 lc ok';
is uc_irc('nick^{abc}', 'strict-rfc1459'), 'NICK^[ABC]',
  'strict-rfc1459 uc ok';

is lc_irc('Nick~[A\bc]'), 'nick^{a|bc}', 'rfc1459 lc ok';
is uc_irc('Nick^{a|bc}'), 'NICK~[A\BC]', 'rfc1459 uc ok';

## infix operator
ok 'Nick~[A\bc]' |rfc1459| 'nick^{a|bc}',
  'infix compare ok';
ok not( 'foo' |rfc1459| 'bar' ), 'negative infix compare ok';

## overloaded objs

my $mapped = irc_str( strict => 'Nick^[Abc]' );
ok $mapped eq 'nick^{abc}', 'strict-rfc1459 eq ok';
ok $mapped ne 'nick~{abc}', 'strict-rfc1459 ne ok';

$mapped = irc_str( 'Nick~[A\bc]' );
ok $mapped eq 'nick^{a|bc}', 'default eq ok';
ok $mapped ne 'foo', 'default ne ok';

$mapped = irc_str( ascii => 'Abc[]' );
ok $mapped eq 'ABC[]', 'ascii eq ok';
ok $mapped ne 'ABC{}', 'ascii ne ok';

# FIXME test other comparison operators

ok $mapped->casemap eq 'ascii', 'casemap() ok';
ok $mapped->length  == 5,       'length() ok';
ok $mapped->as_upper eq 'ABC[]', 'as_upper() ok';
isa_ok $mapped->as_upper, ref $mapped;
ok $mapped->as_lower eq 'abc[]', 'as_lower() ok';
isa_ok $mapped->as_lower, ref $mapped;

done_testing;
