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
        plan tests => 10;
    };

    use_ok('Handel::Storage::RDBO::Cart');
};

my $storage = Handel::Storage::RDBO::Cart->new;
isa_ok($storage, 'Handel::Storage::RDBO::Cart');

ok($storage->has_column('name'), 'has name column');
ok(!$storage->has_column('quix'), 'does not have quix column');

my $schema = $storage->schema_instance;
ok($storage->has_column('name'), 'has name column');
ok(!$storage->has_column('quix'), 'does not have quix column');

## cheat, and make sure it uses result source
$schema->meta->add_column('quix');
ok($storage->has_column('quix'), 'has quix column');


## check the results too
$ENV{'HandelDBIDSN'} = Handel::Test->init_schema->dsn;
$storage->schema_instance(undef);
my $result = $storage->search->first;
isa_ok($result, 'Handel::Storage::RDBO::Result');
ok($result->has_column('name'), 'has name column');
ok(!$result->has_column('foo'), 'has no foo column');
