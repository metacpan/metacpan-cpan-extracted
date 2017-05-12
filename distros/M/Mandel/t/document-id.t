use Mojo::Base -strict;
use Test::More;
use Mandel::Document;

my $doc = Mandel::Document->new;

isa_ok $doc->id, 'Mango::BSON::ObjectID';

$doc->id('507f1f77bcf86cd799439011');
isa_ok $doc->id, 'Mango::BSON::ObjectID';
is $doc->id->to_string, '507f1f77bcf86cd799439011', 'set from string';

$doc->id(Mango::BSON::ObjectID->new);
ok $doc->id->to_string, 'set from object';
isnt $doc->id->to_string, '507f1f77bcf86cd799439011', 'changed string';

$doc = Mandel::Document->new(id => '507f1f77bcf86cd799439011');
is $doc->id->to_string, '507f1f77bcf86cd799439011', 'set in constructor';

done_testing;
