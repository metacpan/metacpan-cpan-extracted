use strict;
use warnings;
use Test::More;
require Jojo::Role;

{
    package My::Does::Basic;

    use Jojo::Role;

    requires 'turbo_charger';

    sub conflict {
        return "My::Does::Basic::conflict";
    }
}

eval <<'END_PACKAGE';
package My::Bad::Requirement;
use Jojo::Role -with;
with 'My::Does::Basic'; # requires turbo_charger
END_PACKAGE
like $@,
qr/missing turbo_charger/,
  'Trying to use a role without providing required methods should fail';

{
    {
        package My::Conflict;
        use Jojo::Role;
        sub conflict {};
    }
    eval <<'    END_PACKAGE';
    package My::Bad::MethodConflicts;
    use Jojo::Role -with;
    with qw(My::Does::Basic My::Conflict);
    sub turbo_charger {}
    END_PACKAGE
    like $@,
    qr/.*/,
      'Trying to use multiple roles with the same method should fail';
}


{
    {
        package Role1;
        use Jojo::Role;
        requires 'missing_method';
        sub method1 { 'method1' }
    }
    {
        package Role2;
        use Jojo::Role;
        with 'Role1';
        sub method2 { 'method2' }
    }
    eval <<"    END";
    package My::Class::Missing1;
    use Jojo::Role -with;
    with 'Role2';
    END
    like $@,
    qr/missing missing_method/,
      'Roles composed from roles should propogate requirements upwards';
}
{
    {
        package Role3;
        use Jojo::Role;
        requires qw(this that);
    }
    eval <<"    END";
    package My::Class::Missing2;
    use Jojo::Role -with;
    with 'Role3';
    END
    like $@,
    qr/missing this, that/,
      'Roles should be able to require multiple methods';
}

done_testing;
