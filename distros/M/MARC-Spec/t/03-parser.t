use Test::More;
use MARC::Spec;

my $parser = MARC::Spec->parse('084$a{$2=\bcl}');

# checking field
ok $parser->field->tag eq '084', 'field tag';
ok $parser->field->index_start == 0, 'field index_start';
ok $parser->field->index_end eq '#', 'field index_end';
ok $parser->field->index_length == -1, 'field index_length';
ok $parser->subfields->[0]->code eq 'a', 'subfield code a';

#checking subspecs
ok scalar @{$parser->subfields->[0]->subspecs} == 1, 'subbfield a subspec count';
ok $parser->subfields->[0]->subspecs->[0]->left->subfields->[0]->code eq '2', 'leftsubterm subfield tag';
ok ref $parser->subfields->[0]->subspecs->[0]->right eq 'MARC::Spec::Comparisonstring', 'rightsubterm comparisonstring';
ok $parser->subfields->[0]->subspecs->[0]->operator eq '=', 'subspec operator';
done_testing();