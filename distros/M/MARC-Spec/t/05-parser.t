use Test::More;
use MARC::Spec;

my $parser = MARC::Spec::parse('245$0$a$9');

ok $parser->subfields->[0]->code eq '0', 'first subfield code';
ok $parser->subfields->[1]->code eq 'a', 'second subfield code';
ok $parser->subfields->[2]->code eq '9', 'third subfield code';

$parser = MARC::Spec::parse('245$a$0');
ok $parser->subfields->[0]->code eq 'a', 'first subfield code';
ok $parser->subfields->[1]->code eq '0', 'second subfield code';

done_testing();