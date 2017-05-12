use Test::More;
use warnings;
use strict;

use MongoDB;
use Try::Tiny;
use Test::Moose;
use Document::Transform;
use Digest::SHA1('sha1_hex');
use Document::Transform::Backend::MongoDB;

my $HOST = $ENV{MONGOD} || "localhost";
my $document_key;
my $transform_key;
my $dbname = sha1_hex(time().rand().'mtfnpy'.$$);

my $doc =
{
    foo => 'bar',
    blarg =>
    [qw/
        one
        two
        three
    /],
    yarp =>
    {
        pluf => [1,2,3]
    }
};

my $tran1 =
{
    operations =>
    [
        {
            path => '/foo',
            value => 'BAR',
        },
    ],
};

my $tran2 =
{
    operations =>
    [
        {
            path => '/blarg/*[1]',
            value => 'TWO',
        },
    ],
};

my $tran3 =
{
    operations =>
    [
        {
            path => '/yarp/pluf/*[2]',
            value => 300,
        },
    ],
};

my $tran4 =
{
    operations =>
    [
        {
            path => '/sup/dawg/liek/mudkips',
            value => 'YES',
        },
    ],
};

try
{
    my $con = MongoDB::Connection->new( host => $HOST );
    my $db = $con->get_database($dbname);
    my $trans = $db->get_collection('transforms');
    my $docs = $db->get_collection('documents');
    $db->drop();

    $document_key = $docs->insert($doc, {safe => 1});
    $tran1->{source} = {'$db' => $dbname, '$ref' => 'documents', '$id' => $document_key};
    my $tran1_id = $trans->insert($tran1, {safe => 1});
    $tran2->{source} = {'$db' => $dbname, '$ref' => 'transforms', '$id' => $tran1_id};
    my $tran2_id = $trans->insert($tran2, {safe => 1});
    $tran3->{source} = {'$db' => $dbname, '$ref' => 'transforms', '$id' => $tran2_id};
    my $tran3_id = $trans->insert($tran3, {safe => 1});
    $tran4->{source} = {'$db' => $dbname, '$ref' => 'transforms', '$id' => $tran3_id};
    $transform_key = $trans->insert($tran4, {safe => 1});
}
catch
{
    plan skip_all => $_ if $_;
};

my $backend = Document::Transform::Backend::MongoDB->new
(
    host => $HOST,
    database_name => $dbname,
    document_collection => 'documents',
    transform_collection => 'transforms'
);

isa_ok($backend, 'Document::Transform::Backend::MongoDB', 'Backend is the right class');
does_ok($backend, 'Document::Transform::Role::Backend', 'Implements the backend interface');

my $transform = $backend->fetch_transform_from_key($transform_key);
ok($backend->transform_constraint->check($transform), 'We got back an actual transform');
$transform = $backend->fetch_transform_from_key($transform_key);
ok($backend->transform_constraint->check($transform), 'We got back an actual transform again');
my $document = $backend->fetch_document_from_key($document_key);
ok($backend->document_constraint->check($document), 'We got back an actual document');

$transform->{operations}[0]{value} = 'YES RLY';

try
{
    $backend->store_transform($transform, 1); #synchronous store
}
catch
{
    fail('Storing a transformation failed: ' . $_);
};

$document->{farfop} = 1;

try
{
    $backend->store_document($document, 1); #synchronous store
}
catch
{
    fail('Storing a transformation failed: ' . $_);
};

my $source = Document::Transform->new(backend => $backend);
my $altered = $source->fetch($transform_key);

my $altered_check =
{
    _id => $altered->{_id},
    foo => 'BAR',
    blarg =>
    [qw/
        one
        TWO
        three
    /],
    yarp =>
    {
        pluf => [1,2,300]
    },
    sup => { dawg => { liek => { mudkips => 'YES RLY' } } },
    farfop => 1,
};

is_deeply($altered, $altered_check, 'The altered document is complete and correct');

done_testing();
