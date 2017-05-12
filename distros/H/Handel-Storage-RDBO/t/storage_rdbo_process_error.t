#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 8;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

$ENV{'HandelDBIDSN'} = Handel::Test->init_schema->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart'
});


## pass an exception object right on through
try {
    local $ENV{'LANG'} = 'en';
    Handel::Storage::RDBO->process_error(Handel::Exception->new);

    fail('no exception thrown');
} catch Handel::Exception with {
    my $e = shift;
    isa_ok($e, 'Handel::Exception');
    like($e, qr/unspecified error/i, 'unspecified in message');
} otherwise {
    fail('other exception caught');
};


## catch 'is not unique' DBIC errors
try {
    local $ENV{'LANG'} = 'en';
    $storage->create({
        id      => '11111111-1111-1111-1111-111111111111',
        shopper => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Constraint with {
    pass('caught constraint exception');
    like(shift, qr/id value already exists/i, 'value exists in message');
} otherwise {
    fail('other exception caught');
};


## catch other DBIC errors
try {
    local $ENV{'LANG'} = 'en';
    $storage->create({
        fabo => '11111111-1111-1111-1111-111111111111'
    });

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('caught storage exception');
    like(shift, qr/can't locate object method/i, 'source in massage');
} otherwise {
    fail('other exception caught');
};
