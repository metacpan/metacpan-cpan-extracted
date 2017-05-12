use ExtUtils::MakeMaker;
use 5.008;
my $module_file = 'lib/Image/EXIF.pm';
WriteMakefile(
    NAME          => 'Image::EXIF',
    VERSION_FROM  => $module_file,
    PREREQ_PM     => {},
    ABSTRACT_FROM => $module_file,
    AUTHOR        => 'sergey s prozhogin <ccpro@rrelaxo.org.ru>',
    OBJECT        => '$(O_FILES)',
    XS            => { 'Image-EXIF.xs' => 'Image-EXIF.c' },
);
