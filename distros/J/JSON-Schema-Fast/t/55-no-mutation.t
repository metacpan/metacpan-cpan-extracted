#!perl
use 5.008003;
use strict;
use warnings;
use B ();
use Test::More;
use JSON::Schema::Fast;

# Validation must not change the value it is judging.
#
# SvNV on an integer caches the NV and turns NOK on. It changes no verdict, so
# nothing here noticed - but it changes the value afterwards: a JSON encoder
# that tests NOK before IOK then writes 1 as 1.0, so a caller who validates a
# document and then serialises it puts different bytes on the wire than the
# ones it was handed. That is how this was found, through Open::API::Client
# sending every integer in a request body as a float.
#
# The interpreter now reads the flags a decoder set instead of forcing them
# (jsf__nv_of in include/jsf_types.h), and skips the numeric block entirely
# when no numeric keyword is present.

sub nok { (B::svref_2object(\ $_[0])->FLAGS & B::SVf_NOK()) ? 1 : 0 }
sub iok { (B::svref_2object(\ $_[0])->FLAGS & B::SVf_IOK()) ? 1 : 0 }

# an integer as a JSON decoder leaves it: IOK, not NOK
my $probe = 1;
is(nok($probe), 0, 'a fresh integer is not NOK (the premise)');
is(iok($probe), 1, 'a fresh integer is IOK');

# ---- every keyword that reads a number numerically -------------------------

my @cases = (
    ['type only',      { type => 'integer' },                        7 ],
    ['minimum',        { minimum => 0 },                             7 ],
    ['maximum',        { maximum => 9 },                             7 ],
    ['exclusiveMinimum', { exclusiveMinimum => 0 },                  7 ],
    ['exclusiveMaximum', { exclusiveMaximum => 9 },                  7 ],
    ['multipleOf',     { multipleOf => 7 },                          7 ],
    ['const',          { const => 7 },                               7 ],
    ['enum',           { enum => [5, 6, 7] },                        7 ],
    ['all at once',    { type => 'integer', minimum => 0, maximum => 9,
                         multipleOf => 7, enum => [7] },             7 ],
);

for my $c (@cases) {
    my ($what, $schema, $value) = @$c;
    my $v = JSON::Schema::Fast->compile($schema);
    ok($v->is_valid($value), "$what: valid (the check really ran)");
    is(nok($value), 0, "$what: left the integer alone");
}

# a failing check must not mutate either - the value is handed back to the
# caller for the error report
{
    my $value = 7;
    my $v = JSON::Schema::Fast->compile({ minimum => 100 });
    ok(!$v->is_valid($value), 'a failing minimum');
    is(nok($value), 0, 'and it left the integer alone too');
}

# ---- inside structures -----------------------------------------------------

{
    my $data = { n => 7, list => [1, 2, 3] };
    my $v = JSON::Schema::Fast->compile({
        type => 'object',
        properties => {
            n    => { type => 'integer', minimum => 0 },
            list => { type => 'array', items => { type => 'integer' },
                      uniqueItems => \1 },
        },
    });
    ok($v->is_valid($data), 'a nested document validates');
    is(nok($data->{n}), 0, 'a property value is left alone');
    is(nok($data->{list}[0]), 0, 'an array element is left alone');
    is(nok($data->{list}[2]), 0, 'including under uniqueItems');
}

# ---- the verdicts are still right ------------------------------------------
# Reading the flags rather than forcing them must answer exactly what SvNV
# answered, including for values that are genuinely floats.

{
    my $v = JSON::Schema::Fast->compile({ minimum => 1.5, maximum => 3.5 });
    ok(!$v->is_valid(1),   '1 is below a fractional minimum');
    ok($v->is_valid(2),    '2 is inside it');
    ok($v->is_valid(1.5),  'the bound itself');
    ok(!$v->is_valid(3.6), 'and above the maximum');

    my $u = JSON::Schema::Fast->compile({ exclusiveMinimum => 2 });
    ok(!$u->is_valid(2),   'exclusive bounds still exclude');
    ok($u->is_valid(2.5),  'and admit what is past them');

    # a float keeps its NV; nothing here turns it into an integer
    my $f = 2.5;
    ok($u->is_valid($f), 'a float validates');
    is(nok($f), 1, 'and is still NOK afterwards');

    # 1 and 1.0 are the same JSON number, whichever way round they are written
    my $c = JSON::Schema::Fast->compile({ const => 1 });
    ok($c->is_valid(1),   'const: an integer');
    ok($c->is_valid(1.0), 'const: the same number written as a float');
    my $e = JSON::Schema::Fast->compile({ enum => [1.0] });
    ok($e->is_valid(1),   'enum: likewise');

    # large integers keep their precision through the non-forcing read
    my $big = 9007199254740993;
    my $b = JSON::Schema::Fast->compile({ const => 9007199254740993 });
    ok($b->is_valid($big), 'a large integer compares equal to itself');
    is(nok($big), 0, 'and was not numified to get there');
}

# ---- the symptom that started it -------------------------------------------

SKIP: {
    skip 'File::Raw::JSON not installed', 2
        unless eval { require File::Raw::JSON; 1 };
    my $data = [1, 2];
    my $before = File::Raw::JSON::file_json_encode($data);
    JSON::Schema::Fast->compile({ type => 'array',
                                  items => { type => 'integer' } })->is_valid($data);
    my $after = File::Raw::JSON::file_json_encode($data);
    is($before, '[1,2]', 'integers encode as integers');
    is($after, $before, 'and still do after validation');
}

done_testing();
