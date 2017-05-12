use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mac::SleepEvent',
    VERSION_FROM      => 'lib/Mac/SleepEvent.pm',
    PREREQ_PM         => {Foundation => 0},
    ($] >= 5.005 ?     
      (ABSTRACT_FROM  => 'lib/Mac/SleepEvent.pm',
       AUTHOR         => 'Lee Aylward <leedo@cpan.org>') : ()),
    LIBS              => [''],
    DEFINE            => '',
    INC               => '-I. -ObjC',
);
