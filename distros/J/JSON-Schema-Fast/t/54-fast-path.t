use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

my $v = JSON::Schema::Fast->compile({ type => 'integer', minimum => 0 });

# the imported function form is parity with the method form
for my $j ('5', '-1', '"x"') {
    is(JSON::Schema::Fast::is_valid($v, J($j)) ? 1 : 0, $v->is_valid(J($j)) ? 1 : 0,
       "is_valid() function matches method for $j");
}

# validate() function: list + scalar context
{
    my @ok = JSON::Schema::Fast::validate($v, J('5'));
    is_deeply(\@ok, [1], 'validate() function valid -> (1)');
    my ($ok, $errs) = JSON::Schema::Fast::validate($v, J('-1'));
    is($ok, 0, 'validate() function invalid -> 0');
    ok(@$errs >= 1, 'validate() function returns errors');
    ok(!scalar(JSON::Schema::Fast::validate($v, J('-1'))), 'validate() function scalar context bool');
}

# guard: a non-compiled first argument dies rather than crashing
eval { is_valid("not a compiled schema", J('5')) };
ok($@, 'is_valid() rejects a non-compiled invocant');

done_testing;
