use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::EditableTable',
    AUTHOR              => 'Andy Espenscheid <aespen@swbell.net>',
    VERSION_FROM        => 'lib/HTML/EditableTable.pm',
    ABSTRACT_FROM       => 'lib/HTML/EditableTable.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-EditableTable-*' },
);
