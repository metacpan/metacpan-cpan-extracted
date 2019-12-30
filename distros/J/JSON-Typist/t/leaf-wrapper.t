use strict;
use warnings;

use Test::Tester;
use Test::More;
use Test::Deep;
use Test::Deep::JType;

{
  note("got undef, expect empty str");

  my ($premature, @results) = run_tests(
    sub { jcmp_deeply(undef, "", "undef vs str"); },
  );

  is($premature, '', 'no early diag');
  is($results[0]->{ok}, 0, 'test failed');
  like(
    $results[0]->{diag},
    qr/got \s* : \s* undef \s* expect \s* : \s* ''/x,
    'diag is right'
  );
};

{
  note("got empty str, expect undef");

  my ($premature, @results) = run_tests(
    sub { jcmp_deeply("", undef, "str vs undef"); },
  );

  is($premature, '', 'no early diag');
  is($results[0]->{ok}, 0, 'test failed');
  like(
    $results[0]->{diag},
    qr/got \s* : \s* '' \s* expect \s* : \s* undef/x,
    'diag is right'
  );
}

{
  note("got undef in hash value, expect empty str");

  my ($premature, @results) = run_tests(
    sub { jcmp_deeply({ u => undef }, { u => "" }, "undef vs str"); },
  );

  is($premature, '', 'no early diag');
  is($results[0]->{ok}, 0, 'test failed');
  like(
    $results[0]->{diag},
    qr/got \s* : \s* undef \s* expect \s* : \s* ''/x,
    'diag is right'
  );
}

{
  note("got empty str in hash value, expect undef");

  my ($premature, @results) = run_tests(
    sub { jcmp_deeply({ u => "" }, { u => undef }, "undef vs str"); },
  );

  is($premature, '', 'no early diag');
  is($results[0]->{ok}, 0, 'test failed');
  like(
    $results[0]->{diag},
    qr/got \s* : \s* '' \s* expect \s* : \s* undef/x,
    'diag is right'
  );
}

done_testing;
