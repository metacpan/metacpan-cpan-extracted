use Test::More;
use MARC::Spec::Parser;

my $parser = MARC::Spec::parse('006$a{^1}');
ok $parser->subfields->[0]->subspecs->[0]->right->indicator->position eq '1', 'subspec indicator position abbreviation2';

$parser = MARC::Spec::parse('006^2{^1}');
ok $parser->indicator->subspecs->[0]->right->indicator->position eq '1', 'subspec indicator position abbreviation3';

done_testing();