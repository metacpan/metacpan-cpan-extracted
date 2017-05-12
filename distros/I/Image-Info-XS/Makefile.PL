use 5.008001;
use ExtUtils::MakeMaker;


WriteMakefile(
    NAME              => 'Image::Info::XS',
    VERSION_FROM      => 'lib/Image/Info/XS.pm', 
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Image/Info/XS.pm', 
       AUTHOR         => 'Dmitry Kosenkov <junker@front.ru>') : ()),
    LIBS              => [''], 
    DEFINE            => '', 
    INC               => '-I.', 
);
