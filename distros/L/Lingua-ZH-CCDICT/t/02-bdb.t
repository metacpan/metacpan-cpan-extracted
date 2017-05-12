use strict;
use warnings;

use lib 't/lib';

use File::Temp qw( tempdir );

use SharedTests qw( BerkeleyDB Storable );

use Lingua::ZH::CCDICT::Storage::BerkeleyDB;


my $dict =
    Lingua::ZH::CCDICT->new( storage  => 'BerkeleyDB',
                             work_dir => tempdir( undef, CLEANUP => 1 ),
                           );

$dict->parse_source_file();

SharedTests::run_tests($dict);
