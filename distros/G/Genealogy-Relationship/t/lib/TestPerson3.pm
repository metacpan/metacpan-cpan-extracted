use Feature::Compat::Class;

class TestPerson3;

field $person_id :param;
method person_id { return $person_id }
field $name :param;
method name { return $name }
field $progenitors :param = [];
method progenitors { return $progenitors }
field $sex :param;
method sex { return $sex }

1;
