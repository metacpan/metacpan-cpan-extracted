use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Jacode4e::RoundTrip},
    'VERSION'   => q{2.13.81.8},
    'ABSTRACT'  => q{Jacode4e for round-trip conversion in JIS X 0213},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'lib' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
    },
    'AUTHOR'    => q{ina <ina@cpan.org> in a CPAN},
);

__END__
