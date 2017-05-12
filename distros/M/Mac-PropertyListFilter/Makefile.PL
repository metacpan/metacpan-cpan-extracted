use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    NAME              => 'Mac::PropertyListFilter',
    VERSION_FROM      => 'PropertyListFilter.pm', # finds $VERSION
    PREREQ_PM         => { 'Mac::PropertyList' => 0.1 },
);
