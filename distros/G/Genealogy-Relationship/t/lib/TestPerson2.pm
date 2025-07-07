use feature 'class';
no warnings 'experimental::class';

class TestPerson2;

field $person_id :param;
method person_id { return $person_id }
field $name :param;
method name { return $name }
field $progenitor :param = undef;
method progenitor { return $progenitor }
field $sex :param;
method sex { return $sex }

1;
