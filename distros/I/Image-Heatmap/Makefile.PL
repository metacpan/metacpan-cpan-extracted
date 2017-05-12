use 5.008008;
use ExtUtils::MakeMaker;
                                               
WriteMakefile(
    NAME              => 'Image::Heatmap',
    VERSION_FROM      => 'lib/Image/Heatmap.pm',
    PREREQ_PM         => {
        'Image::Magick' => 0,
        'File::Find'    => 0,
    }, 
);

