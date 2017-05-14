use Test::More;
use MARC::Spec::Parser;

my $parser = MARC::Spec::parse('006[0-3]/1-3{LDR/0=\A|LDR/0=\X}{LDR/1!=\X}');

# checking field
ok $parser->field->tag eq '006', 'field tag';
ok $parser->field->index_start == 0, 'field index_start';
ok $parser->field->index_end == 3, 'field index_end';
ok $parser->field->index_length == 4, 'field index_length';
ok $parser->field->char_start == 1, 'field char_start';
ok $parser->field->char_end == 3, 'field char_end';
ok $parser->field->char_length == 3, 'field char_length';

#checking subspecs
ok scalar(grep {defined $_} @{$parser->field->subspecs}) == 2, 'field subspec count';
ok scalar(grep {defined $_} @{@{$parser->field->subspecs}[0]}) == 2, 'field subspec count2';

ok $parser->field->subspecs->[0]->[0]->operator eq '=', 'subspec 1 tag';
ok $parser->field->subspecs->[0]->[0]->left->field->tag eq 'LDR', 'subspec 1 left tag';
ok $parser->field->subspecs->[0]->[0]->left->field->char_start == 0, 'subspec 1 left char_start';
ok $parser->field->subspecs->[0]->[0]->left->field->char_end == 0, 'subspec 1 left char_end';
ok $parser->field->subspecs->[0]->[0]->left->field->char_length == 1, 'subspec 1 left char_length';
ok $parser->field->subspecs->[0]->[0]->right->raw eq 'A', 'subspec 1 right raw';
ok $parser->field->subspecs->[1]->right->raw eq 'X', 'subspec 3 right raw';

done_testing();