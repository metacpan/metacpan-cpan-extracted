use strict; use warnings;
use Test::More;
use JSON::Schema::Fast;
use File::Raw::JSON;
sub J { File::Raw::JSON::file_json_decode($_[0]) }
sub V { JSON::Schema::Fast->compile($_[0]) }
sub by_kw { my ($e, $kw) = @_; for (@$e) { return $_ if $_->{keyword} eq $kw } undef }

# leaf error: instanceLocation + keyword + schemaLocation
{
    my $v = V({ type => 'object', required => ['name'],
                properties => { age => { type => 'integer' } } });
    my $e = $v->errors(J('{"age":"x"}'));

    my $req = by_kw($e, 'required');
    ok($req, 'required error present');
    is($req->{instanceLocation}, '',           'required instanceLocation is the object root');
    is($req->{schemaLocation},   '/required',   'required schemaLocation');

    my $typ = by_kw($e, 'type');
    ok($typ, 'type error present');
    is($typ->{instanceLocation}, '/age',                  'nested instanceLocation');
    is($typ->{schemaLocation},   '/properties/age/type',  'nested schemaLocation');
}

# array index in the instanceLocation
{
    my $v = V({ type => 'array', items => { type => 'integer' } });
    my $e = $v->errors(J('[1,"x",3]'));
    is($e->[0]{instanceLocation}, '/1', 'array element index in pointer');
}

# JSON Pointer escaping: '/' -> ~1, '~' -> ~0
{
    my $v = V({ properties => { 'a/b' => { type => 'integer' } } });
    my $e = $v->errors(J('{"a/b":"x"}'));
    is(by_kw($e, 'type')->{instanceLocation}, '/a~1b', 'slash escaped as ~1');
}
{
    my $v = V({ properties => { 'm~n' => { type => 'integer' } } });
    my $e = $v->errors(J('{"m~n":"x"}'));
    is(by_kw($e, 'type')->{instanceLocation}, '/m~0n', 'tilde escaped as ~0');
}

# collect-all: multiple independent failures are all reported
{
    my $v = V({ type => 'object',
                properties => { a => { type => 'integer' }, b => { type => 'integer' } } });
    my $e = $v->errors(J('{"a":"x","b":"y"}'));
    is(scalar(@$e), 2, 'both property errors collected');
}

done_testing;
