use 5.006;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $author1 = 'Sam Henry <henryst@vcu.edu'; 
my $author2 = 'Bridget McInnes <btmcinnes@vcu.edu';


WriteMakefile(
    'NAME'                => 'MetaMap::DataStructures',
    'VERSION_FROM'        => 'lib/MetaMap/DataStructures.pm',
    'PREREQ_PM' => {
        'Test::More' => '0',
    }, 

    'EXE_FILES'            => [("utils/MetaMapDataStructures.pl")], 
    'dist'              => {'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz'},
    ($] >= 5.005 ?
     ('ABSTRACT'   => 'lib/MetaMap/DataStructures.pm', 
      'AUTHOR'          => "$author1, $author2") : ())); 
 

