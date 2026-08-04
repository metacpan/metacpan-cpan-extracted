use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;

# Cross-check verdicts against JSON::Schema::Modern (the reference pure-Perl
# validator) when it is installed. Optional: a test-only comparator, never a
# runtime dependency. Schemas are defined as JSON text so booleans (uniqueItems
# etc.) are real JSON booleans - Modern strictly meta-validates the schema.
BEGIN {
    plan skip_all => 'JSON::Schema::Modern not installed (optional oracle)'
        unless eval { require JSON::Schema::Modern; 1 };
    plan skip_all => 'Cpanel::JSON::XS not installed'
        unless eval { require Cpanel::JSON::XS; 1 };
}
# decode with a boolean type BOTH validators recognise (File::Raw::JSON's
# Boolean class is not one Modern accepts, which is only a harness concern)
my $codec = Cpanel::JSON::XS->new->utf8->allow_nonref;
sub J { $codec->decode($_[0]) }

my @corpus = (
    [ '{"type":"object","required":["a"],"properties":{"a":{"type":"integer","minimum":0}}}',
      [ '{"a":1}', '{"a":-1}', '{}', '{"a":"x"}' ] ],
    [ '{"type":"array","items":{"type":"string"},"minItems":1,"uniqueItems":true}',
      [ '["a","b"]', '[]', '["a","a"]', '[1]' ] ],
    [ '{"anyOf":[{"type":"integer"},{"type":"string"}]}',
      [ '5', '"x"', 'true', 'null' ] ],
    [ '{"type":"string","minLength":2,"maxLength":4,"pattern":"^[a-z]+$"}',
      [ '"ab"', '"a"', '"abcde"', '"AB"' ] ],
    [ '{"oneOf":[{"multipleOf":2},{"multipleOf":3}]}',
      [ '2', '3', '6', '5' ] ],
);

my $tests = 0;
for my $pair (@corpus) {
    my ($sjson, $datas) = @$pair;
    my $schema = J($sjson);
    my $fast   = JSON::Schema::Fast->compile($schema);
    my $modern = JSON::Schema::Modern->new(specification_version => 'draft2020-12');
    for my $j (@$datas) {
        my $data = J($j);
        my $f = $fast->is_valid($data) ? 1 : 0;
        my $m = $modern->evaluate($data, $schema)->valid ? 1 : 0;
        is($f, $m, "agree on $sjson vs $j");
        $tests++;
    }
}
diag("cross-checked $tests (schema,data) pairs against JSON::Schema::Modern " . JSON::Schema::Modern->VERSION);

done_testing;
