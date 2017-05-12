use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Embedix::ECD',
    'VERSION_FROM' => 'ECD.pm',
    'EXE_FILES'    => [ qw(bin/checkecd bin/ecd2xml) ],
    'PREREQ_PM'    => {
        'Parse::RecDescent' => 0,
        'Data::Dumper'      => 0,
        'Tie::IxHash'       => 0,
        'Pod::Usage'        => 0,
    },
);
