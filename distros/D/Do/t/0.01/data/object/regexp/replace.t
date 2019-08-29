use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp';
# deprecated
# can_ok 'Data::Object::Regexp', 'replace';

subtest 'replace' => sub {
  my $re = Data::Object::Regexp->new(qr(test));

  is $re->replace('this is a test', 'drill')->string, 'this is a drill',
    'successful replace';

  is $re->replace('test one test two test three', 'match')->string,
    'match one test two test three',
    'multiple substitutions replaces only first match';

  is $re->replace('this does not match')->string, 'this does not match',
    'replace against non-matching string';

  my $re_multi = Data::Object::Regexp->new(qr/test/);
  is $re_multi->replace('test one test two test three', 'match', 'g')->string,
    'match one match two match three', 'multiple substitutions';
};

ok 1 and done_testing;
