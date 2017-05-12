
use strict;
use warnings;
use lib 'lib';
use AnyEvent::CouchDB;
use KiokuDB;

my $kioku = KiokuDB->connect("couchdb::uri=http://localhost:5984/test-db;conflicts=throw");

my $s = $kioku->new_scope;

my $obj = {field => 1};

my($id) = $kioku->store($obj);
my $db = couchdb("http://localhost:5984/test-db");
use Data::Dump "pp";
my $o = $db->get($id)->recv;
pp $o;
$o->{data}{field} = 2;
$db->bulk_docs([$o])->recv;
$obj->{field} = 3;
eval {
  $kioku->store($obj)
};
pp $@->conflicts;
