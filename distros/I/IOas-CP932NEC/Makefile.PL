use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{IOas::CP932NEC},
    'VERSION'   => q{0.04},
    'ABSTRACT'  => q{provides CP932NEC I/O subroutines for UTF-8 script},
    'PREREQ_PM' => {
        'Encode' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Jacode4e::RoundTrip' => '2.13.81.7',
        'Socket' => '0',
        'Symbol' => '0',
        'lib' => '0',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org> in a CPAN},
);

__END__
