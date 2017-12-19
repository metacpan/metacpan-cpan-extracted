use Test::More;
use MARC::Spec::Parser;

my $parser = MARC::Spec::parse('006[0-3]^1{$b}');
ok $parser->indicator->position eq '1', 'indicator position';
ok $parser->indicator->subspecs->[0]->left->field->tag eq '006', 'subspec field tag';

$parser = MARC::Spec::parse('006{^1}');
ok $parser->field->subspecs->[0]->right->indicator->position eq '1', 'subspec indicator position abbreviation1';

done_testing();