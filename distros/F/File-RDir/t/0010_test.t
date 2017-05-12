use strict;
use warnings;

use Test::More tests => 4;

use_ok('File::RDir');

my $tdir = 'testdir';

is_deeply( [ sort(File::RDir::read_rdir($tdir)) ],
           [ '/File01.txt',
             '/Sub01/AA_hidden/File07.txt',
             '/Sub01/AA_hidden/Zzz/File08.txt',
             '/Sub01/D01/File04.txt',
             '/Sub01/D02/File05.txt',
             '/Sub01/File02.txt',
             '/Sub01/File03.txt',
             '/Sub02/D03/File06.txt' ],
           "First simple test" );

is_deeply( [ sort(File::RDir::read_rdir($tdir, { prune => 'aa*:i;d01' })) ],
           [ '/File01.txt',
             '/Sub01/D01/File04.txt',
             '/Sub01/D02/File05.txt',
             '/Sub01/File02.txt',
             '/Sub01/File03.txt',
             '/Sub02/D03/File06.txt' ],
           "Pruning works ok" );

is_deeply( [ sort(File::RDir::read_rdir($tdir, { prune => 'aa*:i;d01:i' })) ],
           [ '/File01.txt',
             '/Sub01/D02/File05.txt',
             '/Sub01/File02.txt',
             '/Sub01/File03.txt',
             '/Sub02/D03/File06.txt' ],
           "Pruning with full ignore-case" );
