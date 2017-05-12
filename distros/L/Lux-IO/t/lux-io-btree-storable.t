use strict;
use Test::More qw(no_plan);
use File::Temp;
use Lux::IO;
use Lux::IO::Btree;

use Storable qw/nfreeze thaw/;

my $bt = Lux::IO::Btree->new;
my $fh = File::Temp->new;
my $filename = $fh->filename;

ok  $bt->open($filename, Lux::IO::DB_CREAT);
ok  $bt->put('key', nfreeze([qw/1 2 3 4 5/]));

is_deeply( thaw($bt->get('key')), [qw/1 2 3 4 5/] );

$bt->close();
$fh->close;
