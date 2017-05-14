use Test::More;
use MARC::Spec;
use MARC::Spec::Subfield;

my $parser = MARC::Spec::parse('006');

# checking field
ok $parser->field->tag eq '006'        , 'field tag';
ok $parser->field->index_start == 0    , 'field index_start';
ok $parser->field->index_end eq '#'    , 'field index_end';
ok $parser->field->index_length == -1  , 'field index_length';
ok $parser->field->has_char_pos eq ''  , 'field attribute has_char_pos false';
ok $parser->field->has_char_start eq '', 'field attribute has_char_start false';
ok $parser->field->has_char_end eq ''  , 'field attribute has_char_end false';
ok $parser->field->has_indicator1 eq '', 'field attribute has_indicator1 false';
ok $parser->field->has_indicator2 eq '', 'field attribute has_indicator2 false';

$parser->field->index_start(1);
ok $parser->field->index_start == 1    , 'field index_start';
ok $parser->field->index_end eq '#'    , 'field index_end';
ok $parser->field->index_length == -1  , 'field index_length';

$parser->field->indicator1(0);
$parser->field->indicator2(0);
ok $parser->field->has_indicator1      , 'field attribute has_indicator1 true';
ok $parser->field->has_indicator2      , 'field attribute has_indicator2 true';

$parser->field->index_end(3);
ok $parser->field->index_end == 3      , 'field index_end';
ok $parser->field->index_length == 3   , 'field index_length';

$parser->field->set_char_start_end('0-#');
ok $parser->field->char_start == 0     , 'field char_start';
ok $parser->field->char_end eq '#'     , 'field char_end';
ok $parser->field->char_length == -1   , 'field char_length';
ok $parser->field->has_char_pos        , 'field attribute has_char_pos true';
ok $parser->field->has_char_start      , 'field attribute has_char_start true';
ok $parser->field->has_char_end        , 'field attribute has_char_end true';

$parser->field->char_start(1);
ok $parser->field->char_start == 1     , 'field char_start';
ok $parser->field->char_end eq '#'     , 'field char_end';
ok $parser->field->char_length == -1   , 'field char_length';

$parser->field->char_end(3);
ok $parser->field->char_end == 3       , 'field char_end';
ok $parser->field->char_length == 3    , 'field char_length';

my $subfield = MARC::Spec::Subfield->new('a');

$parser->add_subfield($subfield);
ok $parser->subfields->[0]->code eq 'a', 'added new subfield';

done_testing();