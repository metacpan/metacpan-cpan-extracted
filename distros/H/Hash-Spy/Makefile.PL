
use 5.010;

use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Hash::Spy',
               VERSION_FROM  => 'lib/Hash/Spy.pm',
               PREREQ_PM     => { 'Test::More' => 0 },
               ABSTRACT_FROM => 'lib/Hash/Spy.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
               LIBS          => [''],
               DEFINE        => '',
               INC           => '-I.' );
