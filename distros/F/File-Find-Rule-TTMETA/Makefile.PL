use strict;

use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'File::Find::Rule' => undef,
    'Template'         => 2.00,
);

my %clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

WriteMakefile(
    NAME        => "File::Find::Rule::TTMETA",
    VERSION     => "0.02",
    PREREQ_PM   => \%PREREQ_PM,
    clean       => \%clean,
);

