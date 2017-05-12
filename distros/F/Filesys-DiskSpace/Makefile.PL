# -*- mode: Perl -*-

use ExtUtils::MakeMaker;

WriteMakefile(NAME         => "Filesys::DiskSpace",
              VERSION_FROM => "lib/Filesys/DiskSpace.pm",
              dist         => { COMPRESS => "gzip", SUFFIX => "gz" },
              clean        => { FILES => '*.bak *.old mibs/*.dump lib/*/*~' },
);
