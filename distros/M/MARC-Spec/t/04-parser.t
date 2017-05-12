use Test::More;
use MARC::Spec;

my $parser = MARC::Spec->parse('084{245}');

ok $parser->field->subspecs->[0]->left->field->tag eq '084', 'field leftsubterm subfield tag';

$parser = MARC::Spec->parse('084$a{245}');
ok $parser->subfields->[0]->subspecs->[0]->left->field->tag eq '084', 'subfield leftsubterm subfield tag';

done_testing();