use 5.008000;
use ExtUtils::MakeMaker;

$BUILD_REQ = {'ExtUtils::PkgConfig' => '1.03','Test::More' => 0.32};
eval { require ExtUtils::PkgConfig; };
unless ($@)
{
	%opencv_info   = ExtUtils::PkgConfig -> find('opencv');
	$opencv_cflags = $opencv_info{cflags};
	$opencv_libs   = $opencv_info{libs};	
}

WriteMakefile(
    NAME              => 'Image::Resize::OpenCV',
    VERSION_FROM      => 'lib/Image/Resize/OpenCV.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.56 ? 
        (BUILD_REQUIRES    => $BUILD_REQ) :
        (PREREQ_PM         => $BUILD_REQ)     
    ),
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Image/Resize/OpenCV.pm',
       AUTHOR         => 'Dmitry Kosenkov <junker@front.ru>') : ()),
    LIBS              => $opencv_libs,
    DEFINE            => '',
    ($] >= 5.014 ? (INC  => $opencv_cflags) : (CCFLAGS => $opencv_cflags)),
);
