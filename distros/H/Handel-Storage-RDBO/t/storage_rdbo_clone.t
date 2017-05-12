#!perl -wT
# $Id$
use strict;
use warnings;

BEGIN {
    use lib 't/lib';
    use Handel::Test;
    use Scalar::Util qw/refaddr/;

    eval 'require DBD::SQLite';
    if($@) {
        plan skip_all => 'DBD::SQLite not installed';
    } else {
        plan tests => 10;
    };

    use_ok('Handel::Storage::RDBO');
    use_ok('Handel::Exception', ':try');
};

$ENV{'HandelDBIDSN'} = Handel::Test->init_schema(no_populate => 1)->dsn;

my $storage = Handel::Storage::RDBO->new({
    schema_class    => 'Handel::Schema::RDBO::Cart',
});


## not a class method
try {
    local $ENV{'LANG'} = 'en';

    Handel::Storage::RDBO->clone;

    fail('no exception thrown');
} catch Handel::Exception::Storage with {
    pass('storage exception caught');
    like(shift, qr/class method/i, 'class method in name');
} otherwise {
    fail('other exception caught');
};


## clone w/ disconnected schema
my $clone = $storage->clone;
is_deeply($storage, $clone, 'storage is a copy of clone');
isnt(refaddr $storage, refaddr $clone, 'clone is not the original');


## clone w/connected schema
my $schema = $storage->schema_instance;
is($storage->_schema_instance, $schema, 'clone is a full copy');
my $cloned = $storage->clone;
is($cloned->_schema_instance, undef, 'unset clone schema instance');
is($storage->schema_instance, $schema, 'original schema in tact');

$storage->_schema_instance(undef);
is_deeply($storage, $cloned, 'cloned schema a copy when connected');
