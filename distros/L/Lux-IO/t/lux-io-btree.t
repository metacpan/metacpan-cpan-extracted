use strict;
use Test::More qw(no_plan);
use File::Temp;
use Lux::IO;
use Lux::IO::Btree;

my $bt = Lux::IO::Btree->new;
isa_ok $bt, 'Lux::IO::Btree';
can_ok $bt, qw(open close get put del);

my $fh = File::Temp->new;
my $filename = $fh->filename;

ok  $bt->open($filename, Lux::IO::DB_CREAT);
ok  $bt->put('key', 'value');
is  $bt->get('key'), 'value';
ok  $bt->del('key');
ok !$bt->get('key');
ok  $bt->close();

$fh->close;
