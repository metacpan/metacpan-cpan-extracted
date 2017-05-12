use strict;
use warnings;

# This test was generated via Dist::Zilla::Plugin::Test::Compile 2.018

use Test::More 0.88;



use Capture::Tiny qw{ capture };

my @module_files = qw(
EntityModel.pm
EntityModel/App.pm
EntityModel/Async.pm
EntityModel/Cache.pm
EntityModel/Cache/Perl.pm
EntityModel/Collection.pm
EntityModel/DB.pm
EntityModel/Deferred.pm
EntityModel/Definition.pm
EntityModel/Definition/JSON.pm
EntityModel/Definition/Perl.pm
EntityModel/Definition/XML.pm
EntityModel/Entity.pm
EntityModel/Entity/Constraint.pm
EntityModel/EntityCollection.pm
EntityModel/Field.pm
EntityModel/Field/Refer.pm
EntityModel/Gather.pm
EntityModel/Model.pm
EntityModel/Plugin.pm
EntityModel/Query.pm
EntityModel/Query/Base.pm
EntityModel/Query/Condition.pm
EntityModel/Query/Delete.pm
EntityModel/Query/Except.pm
EntityModel/Query/Field.pm
EntityModel/Query/FromTable.pm
EntityModel/Query/GroupField.pm
EntityModel/Query/Insert.pm
EntityModel/Query/InsertField.pm
EntityModel/Query/Intersect.pm
EntityModel/Query/Join.pm
EntityModel/Query/JoinTable.pm
EntityModel/Query/OrderField.pm
EntityModel/Query/ParseSQL.pm
EntityModel/Query/ReturningField.pm
EntityModel/Query/Select.pm
EntityModel/Query/SubQuery.pm
EntityModel/Query/Table.pm
EntityModel/Query/Union.pm
EntityModel/Query/UnionAll.pm
EntityModel/Query/Update.pm
EntityModel/Query/UpdateField.pm
EntityModel/Resolver.pm
EntityModel/Storage.pm
EntityModel/Storage/Perl.pm
EntityModel/Storage/PerlAsync.pm
EntityModel/StorageClass/KVStore.pm
EntityModel/StorageClass/KVStore/Layer.pm
EntityModel/StorageClass/KVStore/Layer/Fake.pm
EntityModel/StorageClass/KVStore/Layer/LRU.pm
EntityModel/StorageClass/KVStore/Layer/Memcached.pm
EntityModel/StorageClass/KVStore/Layer/PostgreSQL.pm
EntityModel/StorageClass/KVStore/Mixin/Deferred.pm
EntityModel/Support.pm
EntityModel/Support/CPP.pm
EntityModel/Support/Javascript.pm
EntityModel/Support/Perl.pm
EntityModel/Support/Perl/Base.pm
EntityModel/Support/Template.pm
EntityModel/Template.pm
EntityModel/Test/Cache.pm
EntityModel/Test/Storage.pm
EntityModel/Transaction.pm
EntityModel/Util.pm
Test/EntityModel.pm
);

my @scripts = qw(
bin/entitymodel
);

# no fake home requested

my @warnings;
for my $lib (@module_files)
{
    my ($stdout, $stderr, $exit) = capture {
        system($^X, '-Mblib', '-e', qq{require q[$lib]});
    };
    is($?, 0, "$lib loaded ok");
    warn $stderr if $stderr;
    push @warnings, $stderr if $stderr;
}

use Test::Script 1.05;
foreach my $file ( @scripts ) {
    script_compiles( $file, "$file compiles" );
}


is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};



done_testing;
