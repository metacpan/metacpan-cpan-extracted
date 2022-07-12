package main;

use 5.018;

use strict;
use warnings;

use Test::More;

subtest('synopsis', sub {
  my $result = eval <<'EOF';
  package Person;

  use Mars::Class;

  attr 'fname';
  attr 'lname';

  package Identity;

  use Mars::Role;

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

  my $meta = $user->meta;

  # bless({name => 'User'}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
  ok UNIVERSAL::isa($result, 'HASH');
});

subtest('example-1 attr', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $attr = $meta->attr('email');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 attr', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $attr = $meta->attr('username');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 attrs', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $attrs = $meta->attrs;

  # [
  #   'email',
  #   'fname',
  #   'id',
  #   'lname',
  #   'login',
  #   'password',
  # ]
EOF
  is_deeply [sort @{$result}], [
    'email',
    'fname',
    'id',
    'lname',
    'login',
    'password',
  ];
});

subtest('example-1 base', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $base = $meta->base('Person');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 base', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $base = $meta->base('Student');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 bases', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $bases = $meta->bases;

  # [
  #   'Person',
  #   'Mars::Kind::Class',
  #   'Mars::Kind',
  # ]
EOF
  is_deeply $result, [
    'Person',
    'Mars::Kind::Class',
    'Mars::Kind'
  ];
});

subtest('example-1 data', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $data = $meta->data;

  # {
  #   'ATTR' => {
  #     'email' => [
  #       'email'
  #     ]
  #   },
  #   'BASE' => {
  #     'Person' => [
  #       'Person'
  #     ]
  #   },
  #   'ROLE' => {
  #     'Authenticable' => [
  #       'Authenticable'
  #     ],
  #     'Identity' => [
  #       'Identity'
  #     ]
  #   }
  # }
EOF
  ok ref $result eq 'HASH';
  ok $result->{ATTR};
  ok $result->{BASE};
  ok $result->{ROLE};
});

subtest('example-1 new', sub {
  my $result = eval <<'EOF';
  package main;

  my $meta = Mars::Meta->new(name => 'User');

  # bless({name => 'User'}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
  ok $result->{name} eq 'User';
});

subtest('example-2 new', sub {
  my $result = eval <<'EOF';
  package main;

  my $meta = Mars::Meta->new({name => 'User'});

  # bless({name => 'User'}, 'Mars::Meta')
EOF
  ok $result->isa('Mars::Meta');
  ok $result->{name} eq 'User';
});

subtest('example-1 role', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $role = $meta->role('Identity');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 role', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $role = $meta->role('Builder');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 roles', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $roles = $meta->roles;

  # [
  #   'Identity',
  #   'Authenticable'
  # ]
EOF
  is_deeply [sort @{$result}], ['Authenticable', 'Identity'];
});

subtest('example-1 sub', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $sub = $meta->sub('authenticate');

  # 1
EOF
  ok $result == 1;
});

subtest('example-2 sub', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $sub = $meta->sub('authorize');

  # 0
EOF
  ok $result == 0;
});

subtest('example-1 subs', sub {
  my $result = eval <<'EOF';
  package main;

  my $user = User->new(
    fname => 'Elliot',
    lname => 'Alderson',
  );

  my $meta = $user->meta;

  my $subs = $meta->subs;

  # [
  #   'attr', ...,
  #   'base',
  #   'email',
  #   'false',
  #   'fname', ...,
  #   'id',
  #   'lname',
  #   'login',
  #   'new', ...,
  #   'role',
  #   'test',
  #   'true',
  #   'with', ...,
  # ]
EOF
  my %subs = map +($_,$_), @{$result};
  ok $subs{'attr'};
  ok $subs{'authenticate'};
  ok $subs{'base'};
  ok $subs{'email'};
  ok $subs{'false'};
  ok $subs{'fname'};
  ok $subs{'id'};
  ok $subs{'lname'};
  ok $subs{'login'};
  ok $subs{'new'};
  ok $subs{'role'};
  ok $subs{'test'};
  ok $subs{'true'};
  ok $subs{'with'};
});

done_testing;
