package   MyDocument;
use Mandel::Document;
use Types::Standard ':all';

field any => (isa => Any);
field int => (isa => Int);
field num => (isa => Num);
field str => (isa => Str);
field 'nonetype';

package main;
use Mojo::Base -strict;
use Mojo::JSON 'j';
use Test::More;

my $doc = MyDocument->new;

is $doc->any('foobar'), $doc, 'any foobar';

eval { $doc->int('foobar') };
like $@, qr{"Int"}, 'foobar is not Int';

eval { $doc->num('foobar') };
like $@, qr{"Num"}, 'foobar is not Num';

is $doc->str('foobar'), $doc, 'foobar is str';

$doc->num("1.23");
$doc->int("42");
like j($doc->data), qr{\:1\.23}, '1.23 is a number';
like j($doc->data), qr{\:42},    '42 is a number';

subtest 'types by model' => sub {
  my @expected = ('Any', 'Int', 'Num', 'Str', undef);
  my @fields = map { $_->name } $doc->model->fields;

  is_deeply \@fields, ['any', 'int', 'num', 'str', 'nonetype'], 'fields by model';

  for (0 .. @fields - 1) {
    is $doc->model->field($fields[$_])->type_constraint, $expected[$_], "type $fields[$_]";
  }
};
done_testing;
