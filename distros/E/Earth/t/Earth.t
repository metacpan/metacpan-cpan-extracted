package main;

use 5.018;

use strict;
use warnings;

use Test::More;

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package main;

  use Earth;

  wrap 'Digest::SHA', 'SHA';

  call(SHA(), 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"
EOF
  ok $result eq 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
});

subtest('args example 1', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  args(content => 'example');

  # {content => "example"}
EOF
  is_deeply $result, {content => 'example'};
});

subtest('args example 2', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  args({content => 'example'});

  # {content => "example"}
EOF
  is_deeply $result, {content => 'example'};
});

subtest('args example 3', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  args('content');

  # {content => undef}
EOF
  is_deeply $result, {content => undef};
});

subtest('args example 4', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  args('content', 'example', 'algorithm');

  # {content => "example", algorithm => undef}
EOF
  is_deeply $result, {content => 'example', algorithm => undef};
});

subtest('call example 1 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  # function dispatch with wrapper

  call(SHA, 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"
EOF
  ok $result eq 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
});

subtest('call example 2 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  # function dispatch with package name

  call('Digest::SHA', 'sha1_hex');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"
EOF
  ok $result eq 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
});

subtest('call example 3 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  # function dispatch with explicit method call

  call(\SHA, 'new');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')
EOF
  ok $result->isa('Digest::SHA');
});

subtest('call example 4 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  wrap 'Digest';

  # function dispatch with wrapper as constructor

  call(Digest('SHA'), 'reset');

  # "da39a3ee5e6b4b0d3255bfef95601890afd80709"
EOF
  ok $result->isa('Digest::SHA');
});

subtest('can example 1 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $coderef = can(SHA(1), 'sha1_hex');

  # sub { ... }
EOF
  ok ref($result) eq 'CODE';
});

subtest('chain example 1 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $hex = chain(\SHA, 'new', 'sha1_hex');

  # "d3aed913fdc7f277dddcbde47d50a8b5259cb4bc"
EOF
  ok $result;
});

subtest('chain example 2 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $hex = chain(\SHA, 'new', ['add', 'hello'], 'sha1_hex');

  # "f47b0cd4b6336d07ab117d7ee3f47566c9799f23"
EOF
  ok $result;
});

subtest('chain example 3 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  wrap 'Digest';

  my $hex = chain(Digest('SHA'), ['add', 'hello'], 'sha1_hex');

  # "8575ce82b266fdb5bc98eb43488c3b420577c24c"
EOF
  ok $result;
});

subtest('error example 1', sub {
  local $@;
  my $result = eval <<'EOF';
  package main;

  use Earth;

  error;

  # "Exception!"
EOF
  ok !$result;
  ok $@ =~ qr/Exception!/;
});

subtest('error example 2', sub {
  local $@;
  my $result = eval <<'EOF';
  package main;

  use Earth;

  error('Exception!');

  # "Exception!"
EOF
  ok !$result;
  ok $@ =~ qr/Exception!/;
});

subtest('error example 3', sub {
  local $@;
  my $result = eval <<'EOF';
  package main;

  use Earth;

  error('Exception!', 0, 1);

  # "Exception!"
EOF
  ok !$result;
  ok $@ =~ qr/Exception!/;
});

subtest('function false', sub {
  my $result = eval <<'EOF';
  package main;

  use Earth;

  my $false = false;

  # 0
EOF
  ok $result == 0;
});

subtest('false example 2 ', sub {
  my $result = eval <<'EOF';
  package main;

  use Earth;

  my $true = !false;

  # 1
EOF
  ok $result == 1;
});

subtest('make example 1 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $string = make(SHA);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')
EOF
  ok $result->isa('Digest::SHA');
});

subtest('make example 2 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $string = make(Digest, 'SHA');

  # bless(do{\(my $o = '...')}, 'Digest::SHA')
EOF
  ok $result->isa('Digest::SHA');
});

subtest('roll example 1 ', sub {
  my @result = eval <<'EOF';
  package main;

  use Earth;

  my @list = roll('sha1_hex', SHA);

  # ("Digest::SHA", "sha1_hex")
EOF
  ok $result[0] eq 'Digest::SHA';
  ok $result[1] eq 'sha1_hex';
});

subtest('roll example 2 ', sub {
  my @result = eval <<'EOF';
  package main;

  use Earth;

  my @list = roll('sha1_hex', call(SHA(1), 'reset'));

  # (bless(do{\(my $o = '...')}, 'Digest::SHA'), "sha1_hex")
EOF
  ok $result[0]->isa('Digest::SHA');
  ok $result[1] eq 'sha1_hex';
});

subtest('then example 1 ', sub {
  my @result = eval <<'EOF';
  package main;

  use Earth;

  my @list = then(SHA, 'sha1_hex');

  # ("Digest::SHA", "da39a3ee5e6b4b0d3255bfef95601890afd80709")
EOF
  ok $result[0]->isa('Digest::SHA');
  ok $result[1] eq 'da39a3ee5e6b4b0d3255bfef95601890afd80709';
});

subtest('true example 1 ', sub {
  my $result = eval <<'EOF';
  package main;

  use Earth;

  my $true = true;

  # 1
EOF
  ok $result == 1;
});

subtest('true example 2 ', sub {
  my $result = eval <<'EOF';
  package main;

  use Earth;

  my $false = !true;

  # 0
EOF
  ok $result == 0;
});

subtest('wrap example 1 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $coderef = wrap('Digest::SHA');

  # my $digest = DigestSHA();

  # "Digest::SHA"
EOF
  ok $result->() eq 'Digest::SHA';
});

subtest('wrap example 2 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $coderef = wrap('Digest::SHA');

  # my $digest = DigestSHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')
EOF
  ok $result->()->isa('Digest::SHA');
});

subtest('wrap example 3 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $coderef = wrap('Digest::SHA', 'SHA');

  # my $digest = SHA;

  # "Digest::SHA"
EOF
  ok $result->() eq 'Digest::SHA';
});

subtest('wrap example 4 ', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  my $coderef = wrap('Digest::SHA', 'SHA');

  # my $digest = SHA(1);

  # bless(do{\(my $o = '...')}, 'Digest::SHA')
EOF
  ok $result->()->isa('Digest::SHA');
});

done_testing;
