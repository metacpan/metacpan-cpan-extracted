use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }

my $schema = { type => 'object', required => ['name'],
               properties => { name => { type => 'string' } } };
my $v = JSON::Schema::Fast->compile($schema);

# validate: list context
{
    my @r = $v->validate(J('{"name":"ada"}'));
    is_deeply(\@r, [1], 'valid -> (1) in list context');
}
{
    my ($ok, $errs) = $v->validate(J('{}'));
    is($ok, 0, 'invalid -> 0');
    is(ref $errs, 'ARRAY', 'invalid -> \@errors');
    ok(@$errs >= 1, 'at least one error');
}

# validate: scalar context
ok(  scalar($v->validate(J('{"name":"ada"}'))), 'scalar valid true');
ok(! scalar($v->validate(J('{}'))),             'scalar invalid false');

# is_valid
ok(  $v->is_valid(J('{"name":"ada"}')), 'is_valid true');
ok(! $v->is_valid(J('{}')),             'is_valid false');

# errors: always an arrayref
is_deeply($v->errors(J('{"name":"ada"}')), [], 'errors empty when valid');
ok(@{ $v->errors(J('{}')) } >= 1, 'errors populated when invalid');

# engine + schema
is($v->engine, 'interp', 'engine is interp');
is_deeply($v->schema, $schema, 'schema round-trips');

done_testing;
