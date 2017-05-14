
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Language::Indonesia',
    VERSION_FROM      => 'lib/Language/Indonesia.pm',
    PREREQ_PM         => {Filter::Simple => 0},
    AUTHOR            => 'Daniel Sirait <dns@cpan.org>'
);