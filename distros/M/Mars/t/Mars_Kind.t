package main;

use 5.018;

use strict;
use warnings;

use Test::More;

no warnings 'redefine';

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $user = User->BLESS(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  # i.e. User->BUILD(bless(User->ARGS(User->BUILDARGS(@args) || User->DATA), 'User'))

  # bless({fname => 'Elliot', lname => 'Alderson'}, 'User')
EOF
  ok $result->isa('User');
  ok UNIVERSAL::isa($result, 'Mars::Kind');
  ok UNIVERSAL::isa($result, 'HASH');
  ok $result->{fname} eq 'Elliot';
  ok $result->{lname} eq 'Alderson';
});

subtest('example-1 ARGS', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  package main;

  my $args = User->ARGS;

  # {}
EOF
  ok ref $result eq 'HASH';
});

subtest('example-2 ARGS', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  package main;

  my $args = User->ARGS(name => 'Elliot');

  # {name => 'Elliot'}
EOF
  ok ref $result eq 'HASH';
  ok int(keys(%{$result})) == 1;
  ok $result->{name} eq 'Elliot';
});

subtest('example-3 ARGS', sub {
  my $result = eval <<'EOF';
  # given: synopsis

  package main;

  my $args = User->ARGS({name => 'Elliot'});

  # {name => 'Elliot'}
EOF
  ok ref $result eq 'HASH';
  ok int(keys(%{$result})) == 1;
  ok $result->{name} eq 'Elliot';
});

subtest('example-1 ATTR', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  User->ATTR('name');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')

  # $user->name;

  # ""

  # $user->name('Elliot');

  # "Elliot"
EOF
  ok $result->isa('User');
  ok $result->can('name');
  ok !exists $result->{name};
  ok !$result->name;
  ok $result->name('Elliot') eq 'Elliot';
  ok $result->name;
});

subtest('example-2 ATTR', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  User->ATTR('role');

  package main;

  my $user = User->BLESS(role => 'Engineer');

  # bless({role => 'Engineer'}, 'User')

  # $user->role;

  # "Engineer"

  # $user->role('Hacker');

  # "Hacker"
EOF
  ok $result->isa('User');
  ok $result->can('role');
  ok $result->{role} eq 'Engineer';
  ok $result->role eq 'Engineer';
  ok $result->role('Hacker') eq 'Hacker';
  ok $result->{role} eq 'Hacker';
  ok $result->role eq 'Hacker';
});

subtest('example-1 AUDIT', sub {
  local $@;
  my $result = eval <<'EOF';
  package HasType;

  use base 'Mars::Kind';

  sub AUDIT {
    die 'Consumer missing "type" attribute' if !$_[1]->can('type');
  }

  package User;

  use base 'Mars::Kind';

  User->TEST('HasType');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $@ =~ qr/Consumer missing "type" attribute/;
});

subtest('example-2 AUDIT', sub {
  my $result = eval <<'EOF';
  package HasType;

  sub AUDIT {
    die 'Consumer missing "type" attribute' if !$_[1]->can('type');
  }

  package User;

  use base 'Mars::Kind';

  User->ATTR('type');

  User->TEST('HasType');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->can('type');
});

subtest('example-1 BASE', sub {
  my $result = eval <<'EOF';
  package Entity;

  sub work {
    return;
  }

  package User;

  use base 'Mars::Kind';

  User->BASE('Entity');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->isa('Entity');
  ok $result->can('work');
  {
    no strict 'refs';
    is_deeply [@User::ISA], ['Entity', 'Mars::Kind'];
  }
});

subtest('example-2 BASE', sub {
  my $result = eval <<'EOF';
  package Engineer;

  sub debug {
    return;
  }

  package Entity;

  sub work {
    return;
  }

  package User;

  use base 'Mars::Kind';

  User->BASE('Entity');

  User->BASE('Engineer');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->isa('Entity');
  ok $result->isa('Engineer');
  ok $result->isa('Mars::Kind');
  ok $result->can('work');
  ok $result->can('debug');
  {
    no strict 'refs';
    is_deeply [@User::ISA], ['Engineer', 'Entity', 'Mars::Kind'];
  }
});

subtest('example-3 BASE', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  User->BASE('Manager');

  # Exception! "Can't locate Manager.pm in @INC"
EOF
  ok $@ =~ qr/Can't locate Manager\.pm in \@INC/;
});

subtest('example-1 BLESS', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok !%$result;
});

subtest('example-2 BLESS', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS(name => 'Elliot');

  # bless({name => 'Elliot'}, 'User')
EOF
  ok $result->isa('User');
  ok int(keys(%$result)) == 1;
  ok exists $result->{name};
  ok $result->{name} eq 'Elliot';
  ok $result->name eq 'Elliot';
});

subtest('example-3 BLESS', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $example = User->BLESS({name => 'Elliot'});

  # bless({name => 'Elliot'}, 'User')
EOF
  ok $result->isa('User');
  ok int(keys(%$result)) == 1;
  ok exists $result->{name};
  ok $result->{name} eq 'Elliot';
  ok $result->name eq 'Elliot';
});

subtest('example-1 BUILD', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    $self->{name} = 'Mr. Robot';

    return $self;
  }

  package main;

  my $example = User->BLESS(name => 'Elliot');

  # bless({name => 'Mr. Robot'}, 'User')
EOF
  ok $result->isa('User');
  ok int(keys(%$result)) == 1;
  ok exists $result->{name};
  ok $result->{name} eq 'Mr. Robot';
  ok $result->name eq 'Mr. Robot';
});

subtest('example-2 BUILD', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    $self->{name} = 'Mr. Robot';

    return $self;
  }

  package Elliot;

  use base 'User';

  sub BUILD {
    my ($self, $data) = @_;

    $self->SUPER::BUILD($data);

    $self->{name} = 'Elliot';

    return $self;
  }

  package main;

  my $elliot = Elliot->BLESS;

  # bless({name => 'Elliot'}, 'Elliot')
EOF
  ok $result->isa('Elliot');
  ok $result->isa('User');
  ok int(keys(%$result)) == 1;
  ok exists $result->{name};
  ok $result->{name} eq 'Elliot';
  ok $result->name eq 'Elliot';
});

subtest('example-1 BUILDARGS', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  sub BUILD {
    my ($self) = @_;

    return $self;
  }

  sub BUILDARGS {
    my ($self, @args) = @_;

    my $data = @args == 1 && !ref $args[0] ? {name => $args[0]} : {};

    return $data;
  }

  package main;

  my $user = User->BLESS('Elliot');

  # bless({name => 'Elliot'}, 'User')
EOF
  ok $result->isa('User');
  ok int(keys(%$result)) == 1;
  ok exists $result->{name};
  ok $result->{name} eq 'Elliot';
  ok $result->name eq 'Elliot';
});

subtest('example-1 DATA', sub {
  my $result = eval <<'EOF';
  package Example;

  use base 'Mars::Kind';

  sub DATA {
    return [];
  }

  package main;

  my $example = Example->BLESS;

  # bless([], 'Example')
EOF
  ok $result->isa('Example');
  ok @$result == 0;
});

subtest('example-2 DATA', sub {
  my $result = eval <<'EOF';
  package Example;

  use base 'Mars::Kind';

  sub DATA {
    return {};
  }

  package main;

  my $example = Example->BLESS;

  # bless({}, 'Example')
EOF
  ok $result->isa('Example');
  ok int(keys(%$result)) == 0;
  ok !exists $result->{name};
});

subtest('example-1 DESTROY', sub {
  no warnings 'once';
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  our $USERS = 0;

  sub BUILD {
    return $USERS++;
  }

  sub DESTROY {
    return $USERS--;
  }

  package main;

  my $user = User->BLESS(name => 'Elliot');

  undef $user;

  # undef
EOF
  ok $User::USERS == 0;
});

subtest('example-1 DOES', sub {
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  sub BUILD {
    return;
  }

  sub BUILDARGS {
    return;
  }

  package main;

  my $admin = User->DOES('Admin');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 DOES', sub {
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  sub BUILD {
    return;
  }

  sub BUILDARGS {
    return;
  }

  package main;

  my $is_owner = User->DOES('Owner');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 EXPORT', sub {
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  sub shutdown {
    return;
  }

  sub EXPORT {
    ['shutdown']
  }

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->DOES('Admin');
});

subtest('example-1 FROM', sub {
  my $result = eval <<'EOF';
  package Entity;

  use base 'Mars::Kind';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package User;

  use base 'Mars::Kind';

  User->ATTR('startup');
  User->ATTR('shutdown');

  User->FROM('Entity');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->isa('Entity');
  ok $result->can('startup');
  ok $result->can('shutdown');
});

subtest('example-2 FROM', sub {
  my $result = eval <<'EOF';
  package Entity;

  use base 'Mars::Kind';

  sub AUDIT {
    my ($self, $from) = @_;
    die "Missing startup" if !$from->can('startup');
    die "Missing shutdown" if !$from->can('shutdown');
  }

  package User;

  use base 'Mars::Kind';

  User->FROM('Entity');

  sub startup {
    return;
  }

  sub shutdown {
    return;
  }

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->isa('Entity');
  ok $result->can('startup');
  ok $result->can('shutdown');
});

subtest('example-1 IMPORT', sub {
  no warnings 'once';
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  our $USES = 0;

  sub shutdown {
    return;
  }

  sub EXPORT {
    ['shutdown']
  }

  sub IMPORT {
    my ($self, $into) = @_;

    $self->SUPER::IMPORT($into);

    $USES++;

    return $self;
  }

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->DOES('Admin');
  ok $Admin::USES == 1;
});

subtest('example-1 META', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $meta = User->META;

  # bless({name => 'User'}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
  ok $result->{name} eq 'User';
  is_deeply $result->bases, ['Entity', 'Engineer', 'Mars::Kind'];
  is_deeply [sort @{$result->roles}], ['Admin', 'HasType'];
});

subtest('example-1 NAME', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $name = User->NAME;

  # "User"
EOF
  ok $result eq 'User';
});

subtest('example-2 NAME', sub {
  my $result = eval <<'EOF';
  package User;

  use base 'Mars::Kind';

  package main;

  my $name = User->BLESS->NAME;

  # "User"
EOF
  ok $result eq 'User';
});

subtest('example-1 MIXIN', sub {
  my $result = eval <<'EOF';
  package Action;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->MIXIN('Action');

  package main;

  my $admin = User->DOES('Action');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 ROLE', sub {
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  package main;

  my $admin = User->DOES('Admin');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 ROLE', sub {
  my $result = eval <<'EOF';
  package Create;

  use base 'Mars::Kind';

  package Delete;

  use base 'Mars::Kind';

  package Manage;

  use base 'Mars::Kind';

  Manage->ROLE('Create');
  Manage->ROLE('Delete');

  package User;

  use base 'Mars::Kind';

  User->ROLE('Manage');

  package main;

  my $create = User->DOES('Create');

  # 1
EOF
  ok $result == 1;
  ok +User->DOES('Create');
  ok +User->DOES('Delete');
  ok +User->DOES('Manage');
});

subtest('example-1 SUBS', sub {
  my $result = eval <<'EOF';
  package Example;

  use base 'Mars::Kind';

  package main;

  my $subs = Example->SUBS;

  # [...]
EOF
  is_deeply $result, ['DATA'];
});

subtest('example-1 TEST', sub {
  my $result = eval <<'EOF';
  package Admin;

  use base 'Mars::Kind';

  package IsAdmin;

  use base 'Mars::Kind';

  sub shutdown {
    return;
  }

  sub AUDIT {
    my ($self, $from) = @_;
    die "${from} is not a super-user" if !$from->DOES('Admin');
  }

  sub EXPORT {
    ['shutdown']
  }

  package User;

  use base 'Mars::Kind';

  User->ROLE('Admin');

  User->TEST('IsAdmin');

  package main;

  my $user = User->BLESS;

  # bless({}, 'User')
EOF
  ok $result->isa('User');
  ok $result->DOES('Admin');
  ok $result->DOES('IsAdmin');
});

done_testing;
