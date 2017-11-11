use strict;
use warnings;
use Test::More;

{
  package Role1; use Jojo::Role;
  sub foo1 { 1 }
}
{
  package Role2; use Jojo::Role;
  sub foo2 { 2 }
}
{
  package BaseClass;
  sub foo { 0 }
}

eval {
  Jojo::Role->create_class_with_roles(
    'BaseClass',
    qw(Role2 Role1 Role1 Role2 Role2),
  );
};

like $@, qr/\ADuplicated roles: Role1, Role2 /,
  'duplicate roles detected';

done_testing;
