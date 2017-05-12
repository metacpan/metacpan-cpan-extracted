use strict;
require 5.008001;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                =>  'Encode::JP::Emoji',
    VERSION_FROM        =>  'lib/Encode/JP/Emoji.pm',
    LICENSE             =>  'apache',
    PREREQ_PM           =>  {
        'Test::More'        =>  '0',
        'Test::Harness'     =>  '3.04',
        'Encode'            =>  '2.12', # 2.23 or later recommended
    },
};

WriteMakefile( %$opt );
