use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{IOas::CP932},
    'VERSION'   => q{0.08},
    'ABSTRACT'  => q{provides CP932 I/O subroutines for UTF-8 script},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Jacode4e::RoundTrip' => '2.13.81.8',
        'Socket' => '0',
        'Symbol' => '0',
        'lib' => '0',
        'perl' => '5.005_03',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
