use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W=1;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'      => q{Jacode4e::RoundTrip},
    'VERSION'   => q{2.13.81.14},
    'ABSTRACT'  => q{Converts JIS X 0213 Encodings with Round-Trip},
    'PREREQ_PM' => {
        'ExtUtils::MakeMaker' => '5.4302',
        'File::Basename' => '2.6',
        'File::Copy' => '2.02',
        'File::Path' => '1.0401',
        'FindBin' => '1.42',
        'Socket' => '0',
        'lib' => '0',
        'perl' => '5.00503',
        'strict' => '1.01',
        'vars' => '0',
    },
    'AUTHOR'    => q{ina <ina@cpan.org>},
);

__END__
