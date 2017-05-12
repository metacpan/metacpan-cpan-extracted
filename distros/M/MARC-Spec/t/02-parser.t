use Test::More;
use MARC::Spec;

my $parser = MARC::Spec->parse('...$a-z{LDR/0=\A|LDR/0=\X}{LDR/1!=\X}$$/1-#');

# checking field
ok $parser->field->tag eq '...', 'field tag';
ok $parser->field->index_start == 0, 'field index_start';
ok $parser->field->index_end eq '#', 'field index_end';
ok $parser->field->index_length == -1, 'field index_length';
ok $parser->subfields->[0]->code eq 'a', 'subfield code a';
ok $parser->subfields->[2]->code eq 'c', 'subfield code a';
ok scalar @{$parser->subfields} == 27, 'subfields length';

#checking subspecs
ok scalar @{$parser->subfields->[0]->subspecs} == 2, 'subbfield a subspec count';
ok scalar @{$parser->subfields->[0]->subspecs->[0]} == 2, 'subfield a subspec count2';
done_testing();