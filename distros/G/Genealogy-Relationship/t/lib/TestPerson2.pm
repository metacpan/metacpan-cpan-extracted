use feature 'class';
no warnings 'experimental::class';

class TestPerson2;

field $person_id :param :reader;
field $name :param :reader;
field $progenitor :param :reader = undef;
field $sex :param :reader;

1;
