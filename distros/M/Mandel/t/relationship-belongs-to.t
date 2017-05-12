use Mojo::Base -strict;
use Mandel ();
use Mango::BSON ':bson';
use Test::More;

my $connection = Mandel->new;
my $cat        = $connection->model(cat => {})->model('cat');
my $person     = $connection->model(person => {})->model('person');

isa_ok $cat->relationship(belongs_to => person => $person->document_class)->monkey_patch,
  'Mandel::Relationship::BelongsTo';

my $doc = $cat->document_class->new({connection => bless {}, 'dummy_class_connection_required'});
my $oid = bson_oid;

is $doc->person($oid), $oid, 'belongs_to with oid returns oid';
is_deeply($doc->data->{person}, {'$ref' => 'persons', '$id' => $oid}, 'data.person == oid');

done_testing;
