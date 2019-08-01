use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{IOas::CP932X},
    'VERSION'   => q{0.02},
    'ABSTRACT'  => q{provides CP932X I/O subroutines for UTF-8 script},
    'PREREQ_PM' => {
        'Archive::Tar' => '0.072',
        'Compress::Zlib' => '1.03',
        'Config' => '0',
        'Encode' => '0',
        'ExtUtils::MakeMaker' => '5.4302',
        'Fcntl' => '1.03',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Jacode4e::RoundTrip' => '0',
        'Socket' => '0',
        'Symbol' => '0',
        'lib' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org> in a CPAN},
);

__END__
