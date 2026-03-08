use Feature::Compat::Class;

class TestPersonWithParents;

field $id :param;
method id { return $id }
field $name :param;
method name { return $name }
field $parents :param = [];
method parents { return $parents }
field $gender :param;
method gender { return $gender }

1;
