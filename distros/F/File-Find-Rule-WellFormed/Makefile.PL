use strict;

use ExtUtils::MakeMaker;

my %PREREQ_PM = (
    'File::Find::Rule'  => 0.07,
    'XML::Parser'       => undef,
);

my %clean = (
    FILES => '$(DISTVNAME).tar$(SUFFIX)',
);

WriteMakefile(
    NAME        => "File::Find::Rule::WellFormed",
    VERSION     => "0.01",
    PREREQ_PM   => \%PREREQ_PM,
    clean       => \%clean,
);

