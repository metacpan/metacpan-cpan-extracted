package main;

use 5.018;

use strict;
use warnings;

no warnings 'redefine';

use Test::More;

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package Person;

  use Mars::Class 'attr';

  attr 'fname';
  attr 'lname';

  package Identity;

  use Mars::Role 'attr';

  attr 'id';
  attr 'login';
  attr 'password';

  sub EXPORT {
    return ['id', 'login', 'password'];
  }

  package Authenticable;

  use Mars::Role;

  sub authenticate {
    return true;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    die "${from} missing Identity role" if !$from->does('Identity');
  }

  sub BUILD {
    my ($self, $data) = @_;
    $self->{auth} = undef;
    return $self;
  }

  sub EXPORT {
    return ['authenticate'];
  }

  package User;

  use Mars::Class;

  base 'Person';
  with 'Identity';

  attr 'email';

  test 'Authenticable';

  sub valid {
    my ($self) = @_;
    return $self->login && $self->password ? true : false;
  }

  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok $result->isa('Person');
  ok $result->can('fname');
  ok $result->can('lname');
  ok $result->can('email');
  ok $result->can('login');
  ok $result->can('password');
  ok $result->can('valid');
  ok !$result->valid;
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->fname eq 'Elliot';
  ok $result->lname eq 'Alderson';
  ok $result->does('Identity');
  ok $result->does('Authenticable');
  ok exists $result->{auth};
  ok !defined $result->{auth};
});

subtest('example-1 attr', sub {
  my $result = eval <<'EOF';
  package Example;

  use Mars::Class;

  attr 'name';

  # "Example"
EOF
  ok $result->can('name');
  my $object = $result->new;
  ok !$object->name;
  $object = $result->new(name => 'example');
  ok $object->name eq 'example';
  $object = $result->new({name => 'example'});
  ok $object->name eq 'example';
});

subtest('example-1 base', sub {
  my $result = eval <<'EOF';
  package Entity;

  use Mars::Class;

  sub output {
    return;
  }

  package Example;

  use Mars::Class;

  base 'Entity';

  # "Example"
EOF
  ok $result->isa('Entity');
  ok $result->isa('Mars::Kind::Class');
  ok $result->isa('Mars::Kind');
  ok $result->can('output');
});

subtest('example-1 false', sub {
  my $result = eval <<'EOF';
  package Example;

  use Mars::Class;

  my $false = false;

  # 0
EOF
  ok $result == 0;
});

subtest('example-2 false', sub {
  my $result = eval <<'EOF';
  package Example;

  use Mars::Class;

  my $true = !false;

  # 1
EOF
  ok $result == 1;
});

subtest('example-1 from', sub {
  my $result = eval <<'EOF';
  package Entity;

  use Mars::Role;

  attr 'startup';
  attr 'shutdown';

  sub EXPORT {
    ['startup', 'shutdown']
  }

  package Record;

  use Mars::Class;

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package Example;

  use Mars::Class;

  with 'Entity';

  from 'Record';

  # "Example"
EOF
  ok $result->isa('Record');
  ok $result->does('Entity');
  ok $result->can('startup');
  ok $result->can('shutdown');
});

subtest('example-1 role', sub {
  my $result = eval <<'EOF';
  package Ability;

  use Mars::Role;

  sub action {
    return;
  }

  package Example;

  use Mars::Class;

  role 'Ability';

  # "Example"
EOF
  ok $result->does('Ability');
  ok !$result->can('action');
});

subtest('example-2 role', sub {
  my $result = eval <<'EOF';
  package Ability;

  use Mars::Role;

  sub action {
    return;
  }

  sub EXPORT {
    return ['action'];
  }

  package Example;

  use Mars::Class;

  role 'Ability';

  # "Example"
EOF
  ok $result->does('Ability');
  ok $result->can('action');
});

subtest('example-1 test', sub {
  my $result = eval <<'EOF';
  package Actual;

  use Mars::Role;

  package Example;

  use Mars::Class;

  test 'Actual';

  # "Example"
EOF
  ok $result->does('Actual');
});

subtest('example-2 test', sub {
  local $@;
  my $result = eval <<'EOF';
  package Actual;

  use Mars::Role;

  sub AUDIT {
    die "Example is not an 'actual' thing" if $_[1]->isa('Example');
  }

  package Example;

  use Mars::Class;

  test 'Actual';

  # "Example"
EOF
  ok $@ =~ qr/Example is not an 'actual' thing/;
});

subtest('example-1 true', sub {
  my $result = eval <<'EOF';
  package Example;

  use Mars::Class;

  my $true = true;

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 true', sub {
  my $result = eval <<'EOF';
  package Example;

  use Mars::Class;

  my $false = !true;

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 with', sub {
  my $result = eval <<'EOF';
  package Understanding;

  use Mars::Role;

  sub knowledge {
    return;
  }

  package Example;

  use Mars::Class;

  with 'Understanding';

  # "Example"
EOF
  ok $result->does('Understanding');
  ok !$result->can('knowledge');
});

subtest('example-2 with', sub {
  my $result = eval <<'EOF';
  package Understanding;

  use Mars::Role;

  sub knowledge {
    return;
  }

  sub EXPORT {
    return ['knowledge'];
  }

  package Example;

  use Mars::Class;

  with 'Understanding';

  # "Example"
EOF
  ok $result->does('Understanding');
  ok $result->can('knowledge');
});

done_testing;
