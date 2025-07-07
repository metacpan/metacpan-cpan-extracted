use feature 'class';
no warnings 'experimental::class';

class TestPerson;

field $id :param;
method id { return $id }
field $name :param;
method name { return $name }
field $parent :param = undef;
method parent { return $parent }
field $gender :param;
method gender { return $gender }

1;
