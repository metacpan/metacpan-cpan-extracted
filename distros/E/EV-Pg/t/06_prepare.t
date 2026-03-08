use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 12;

# prepare + query_prepared
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->prepare("test_add", "select \$1::int + \$2::int as sum", sub {
        my ($data, $err) = @_;
        ok(!$err, 'prepare: no error');
        ok(defined $data, 'prepare: got cmd_tuples');

        $pg->query_prepared("test_add", [10, 20], sub {
            my ($rows, $err2) = @_;
            ok(!$err2, 'query_prepared: no error');
            is($rows->[0][0], '30', 'query_prepared: 10+20=30');
            EV::break;
        });
    });
});

# describe_prepared
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->prepare("desc_stmt", "select \$1::int as val", sub {
        my ($data, $err) = @_;
        ok(!$err, 'prepare for describe');

        $pg->describe_prepared("desc_stmt", sub {
            my ($meta, $err2) = @_;
            ok(!$err2, 'describe_prepared: no error');
            is($meta->{nparams}, 1, 'describe_prepared: 1 param');
            is($meta->{nfields}, 1, 'describe_prepared: 1 field');
            is($meta->{fields}[0]{name}, 'val', 'describe_prepared: field name');
            ok($meta->{fields}[0]{type} > 0, 'describe_prepared: field type OID');
            is(ref $meta->{paramtypes}, 'ARRAY', 'describe_prepared: paramtypes is array');
            ok($meta->{paramtypes}[0] > 0, 'describe_prepared: param type OID');
            EV::break;
        });
    });
});
