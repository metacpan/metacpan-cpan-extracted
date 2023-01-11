use strict;
use warnings;

use ExtUtils::MakeMaker;

my %options = (
    NAME => "IO::Zlib",
    VERSION_FROM => "Zlib.pm",
    PREREQ_PM => { "Compress::Zlib" => 2.000 },
    SIGN => 1,
    INSTALLDIRS  => ($] >= 5.009003 && $] < 5.012000) ? "perl" : "site",
    dist => { COMPRESS => "gzip", SUFFIX => "gz" }
);

if ($ExtUtils::MakeMaker::VERSION >= 6.50)
{
    $options{META_MERGE} = {
        resources => {
            repository => "https://github.com/tomhughes/IO-Zlib.git",
            bugtracker => "https://github.com/tomhughes/IO-Zlib/issues"
        }
    };
}

WriteMakefile(%options);
