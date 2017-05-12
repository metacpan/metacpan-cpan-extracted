use warnings;
use strict;
use Test::More;

eval <<"PACKAGE" or die $@;
  package Custom::Base::Class;
  use Mandel::Document;
  1;
PACKAGE

eval <<"PACKAGE" or die $@;
  package My::Document;
  use Mandel::Document 'Custom::Base::Class';
  1;
PACKAGE

can_ok 'Custom::Base::Class', 'model';
can_ok 'My::Document',        'model';
isa_ok 'My::Document',        'Custom::Base::Class';
isa_ok 'My::Document',        'Mandel::Document';
isa_ok 'Custom::Base::Class', 'Mandel::Document';

{
  local $TODO = 'Not sure if Custom::Base::Class should have model()';
  isnt Custom::Base::Class->model, My::Document->model, 'not the same model';
}

{
  is Custom::Base::Class->model->collection_name, 'class',     'class collection';
  is My::Document->model->collection_name,        'documents', 'models collection';
}

done_testing;
