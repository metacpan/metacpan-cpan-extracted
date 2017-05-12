use 5.008000;
use ExtUtils::MakeMaker;

my $bits_are_64 = unpack("L!", pack("LL", 0x12345678, 0x9ABCDEF)) >= 2**32;

if ($bits_are_64) {
    die "x86_64 damn, this probably won't work!";
}

WriteMakefile(
    NAME              => 'Mac::MotionSensor',
    VERSION_FROM      => 'lib/Mac/MotionSensor.pm', # finds $VERSION
    PREREQ_PM         => {
        'Test::More' => 0,
        'XSLoader' => 0,
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mac/MotionSensor.pm', # retrieve abstract from module
       AUTHOR         => 'Robin Edwards <rge@cpan.org>') : ()),
    LIBS              => [''],
	LDDLFLAGS         => '-bundle -flat_namespace -undefined dynamic_lookup -framework CoreFoundation -framework IOKit -arch i386',
    OBJECT            => '$(O_FILES)',
);
