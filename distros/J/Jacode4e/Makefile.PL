use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Jacode4e},
    'VERSION'   => q{2.13.6.16},
    'ABSTRACT'  => q{jacode.pl-like program for enterprise},
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
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
