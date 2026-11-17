use strict;
use warnings;
use Test::More;
use JSON::PP ();
use Example::Sugar::Schema qw(str num int_ bool arr obj nullable enum_);
is_deeply(str(min=>1,max=>60),{type=>'string',minLength=>1,maxLength=>60},'string aliases');
is_deeply(num(min=>0,max=>1),{type=>'number',minimum=>0,maximum=>1},'numeric bounds');
is(int_()->{type},'integer','integer name avoids core int');
is(bool()->{type},'boolean','boolean type');
is(arr(str(),max=>2)->{maxItems},2,'array bound');
my $original=enum_(qw(fast thorough));
my $union=nullable($original);
is_deeply($union->{anyOf}[1],{type=>'null'},'nullable creates actual null alternative');
$union->{anyOf}[0]{enum}[0]='edited';
is($original->{enum}[0],'fast','nullable copies nested schema');
my $properties={name=>str(max=>60)};
my $schema=obj($properties,required=>['name']);
$schema->{properties}{name}{maxLength}=1;
is($properties->{name}{maxLength},60,'object helper copies property schemas');
like(JSON::PP->new->canonical->encode($schema),qr/"additionalProperties":false/,'JSON false is not integer zero');
for my $case (
  ['unknown',sub {str(typo=>1)},qr/Unknown/],
  ['duplicate',sub {str(max=>1,max=>2)},qr/Repeated/],
  ['odd',sub {str('max')},qr/Odd/],
  ['negative length',sub {str(min=>-1)},qr/nonnegative/],
  ['inverted',sub {num(min=>4,max=>2)},qr/Inverted/],
  ['invalid number',sub {num(min=>'NaN')},qr/finite/],
  ['overflow',sub {num(max=>'1e9999')},qr/overflows/],
  ['missing item schema',sub {arr(undef)},qr/schema hashref/],
  ['unknown required',sub {obj({},required=>['missing'])},qr/required property/],
  ['duplicate required',sub {obj({x=>str()},required=>[qw(x x)])},qr/Duplicate/],
  ['nonboolean additional',sub {obj({},additional=>2)},qr/0 or 1/],
  ['empty enum',sub {enum_()},qr/at least/],
  ['duplicate enum',sub {enum_(qw(x x))},qr/Duplicate/],
  ['undefined enum',sub {enum_(undef)},qr/defined/],
  ['nullable type',sub {nullable([])},qr/hashref/],
) {
  eval {$case->[1]->()};
  like($@,$case->[2],"reject $case->[0]");
}
done_testing;
