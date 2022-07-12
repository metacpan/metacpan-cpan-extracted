package main;

use 5.018;

use strict;
use warnings;

use Test::More;

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package Person;

  use base 'Mars::Kind::Role';

  package User;

  use base 'Mars::Kind::Class';

  package main;

  my $user = User->ROLE('Person')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
  ok $result->does('Person');
});

subtest('example-1 does', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->ROLE('Person')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $does = $user->does('Person');

  # 1
EOF
  ok $result == 1;
});

subtest('example-1 meta', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->ROLE('Person')->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  # bless({...}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
});

done_testing;
