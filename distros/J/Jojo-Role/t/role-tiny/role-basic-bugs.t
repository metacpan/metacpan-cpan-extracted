use strict;
use warnings;
use Test::More;

# multiple roles with the same role
{
    package RoleC;
    use Jojo::Role;
    sub baz { 'baz' }
}
{
    package RoleB;
    use Jojo::Role;
    with 'RoleC';
    sub bar { 'bar' }
}
{
    package RoleA;
    use Jojo::Role;
    with 'RoleC';
    sub foo { 'foo' }
}
{
    package Foo;
    use strict;
    use warnings;
    use Jojo::Role -with;
    eval {
        with 'RoleA', 'RoleB';
        1;
    } or $@ ||= 'unknown error';
    ::is $@, '',
      'Composing multiple roles which use the same role should not have conflicts';
    sub new { bless {} => shift }

    my $object = Foo->new;
    foreach my $method (qw/foo bar baz/) {
        ::can_ok $object, $method;
        ::is $object->$method, $method,
          '... and all methods should be composed in correctly';
    }
}

{
    no warnings 'redefine';
    local *UNIVERSAL::can = sub { 1 };
    eval <<'    END';
    package Can::Can;
    use Jojo::Role -with;
    with 'A::NonExistent::Role';
    END
}

{
    my $error = $@ || '';
    like $error, qr{^Can't locate A/NonExistent/Role.pm},
        'If ->can always returns true, we should still not think we loaded the role'
            or diag "Error found: $error";
}

{
    package Role1;
    use Jojo::Role;
}
{
    package Role2;
    use Jojo::Role;
}
{
    package Frew;
    use strict;
    use warnings;
    sub new { bless {} => shift }

    my $object = Frew->new;

    my $does_role = Jojo::Role->can('does_role');
    ::ok(!$does_role->($object, 'Role1'), 'no Role1 yet');
    ::ok(!$does_role->($object, 'Role2'), 'no Role2 yet');

    Jojo::Role->apply_roles_to_object($object, 'Role1');
    ::ok($does_role->($object, "Role1"), 'Role1 consumed');
    ::ok(!$does_role->($object, 'Role2'), 'no Role2 yet');
    Jojo::Role->apply_roles_to_object($object, 'Role2');
    ::ok($does_role->($object, "Role1"), 'Role1 consumed');
    ::ok($does_role->($object, 'Role2'), 'Role2 consumed');
}

BEGIN {
    package Bar;
    $INC{'Bar.pm'} = __FILE__;

    sub new { bless {} => shift }
    sub bar { 1 }
}
BEGIN {
    package Baz;
    $INC{'Baz.pm'} = __FILE__;

    use Jojo::Role;

    sub baz { 1 }
}

can_ok(Jojo::Role->create_class_with_roles(qw(Bar Baz))->new, qw(bar baz));

done_testing;
