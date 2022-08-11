package main;

use 5.018;

use strict;
use warnings;

use Test::More;

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind::Class';

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
});

subtest('example-1 DESTROY', sub {
  no warnings 'once';
  my $result = eval <<'EOF';
  package Protocol;

  use base 'Mars::Kind::Role';

  our $EVENT = 0;

  sub DESTROY {
    return $EVENT++;
  }

  package Resource;

  use base 'Mars::Kind::Class';

  Resource->ROLE('Protocol');

  our $EVENT = 0;

  sub DESTROY {
    my ($self) = @_;
    $self->SUPER::DESTROY();
    return $EVENT++;
  }

  package main;

  my $resource = Resource->BLESS(name => 'Console');

  undef $resource;

  # undef
EOF
  ok $Resource::EVENT == 1;
  ok $Protocol::EVENT == 1;
});

subtest('example-1 does', sub {
  local $@;
  my $result = eval <<'EOF';
  # given: synopsis

  my $does = $user->does('Identity');

  # 0
EOF
  ok $@;
});

subtest('example-1 meta', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  # bless({...}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
});

subtest('example-1 new', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
});

subtest('example-2 new', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new({
    fname => 'Elliot',
    lname => 'Alderson',
  });

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
});

done_testing;
