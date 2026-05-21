use strict;
use warnings;
use Test::More;
use EV;
use EV::Pg;
use lib 't';
use TestHelper;

require_pg;
plan tests => 21;

# prepare + query_prepared
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->prepare("test_add", "select \$1::int + \$2::int as sum", sub {
        my ($data, $err) = @_;
        ok(!$err, 'prepare: no error');
        is($data, '', 'prepare: empty cmd_tuples');

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

# describe_prepared with zero params and zero fields
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->query("create temp table desc_zero (id int)", sub {
        my (undef, $err) = @_;
        die $err if $err;
        $pg->prepare("zero_stmt", "insert into desc_zero values (1)", sub {
            my (undef, $err) = @_;
            die $err if $err;
            $pg->describe_prepared("zero_stmt", sub {
                my ($meta, $err) = @_;
                ok(!$err, 'describe zero-field: no error');
                is($meta->{nparams}, 0, 'describe zero-field: 0 params');
                is($meta->{nfields}, 0, 'describe zero-field: 0 fields');
                ok(!exists $meta->{fields}, 'describe zero-field: no fields key');
                ok(!exists $meta->{paramtypes}, 'describe zero-field: no paramtypes key');
                EV::break;
            });
        });
    });
});

# describe_prepared("") -- the unnamed/anonymous prepared statement
with_pg(cb => sub {
    my ($pg) = @_;
    $pg->prepare("", "select \$1::int as anon_n", sub {
        my (undef, $err) = @_; die $err if $err;
        $pg->describe_prepared("", sub {
            my ($meta, $e) = @_;
            ok(!$e, 'describe anonymous: no error');
            is($meta->{nparams}, 1, 'describe anonymous: 1 param');
            is($meta->{nfields}, 1, 'describe anonymous: 1 field');
            is($meta->{fields}[0]{name}, 'anon_n',
               'describe anonymous: field name');
            EV::break;
        });
    });
});
