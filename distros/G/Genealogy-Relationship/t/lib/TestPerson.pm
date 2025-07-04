use feature 'class';
no warnings 'experimental::class';

class TestPerson;

field $id :param :reader;
field $name :param :reader;
field $parent :param :reader = undef;
field $gender :param :reader;

1;
