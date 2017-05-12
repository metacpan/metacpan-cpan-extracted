use ExtUtils::MakeMaker;

$CC =  'g++';

WriteMakefile(
    'NAME'		=> 'Device::QuickCam',
    'VERSION_FROM'	=> 'QuickCam.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?   
      (ABSTRACT_FROM    => 'QuickCam.pm', 
       AUTHOR           => 'Hendrik Van Belleghem <beatnik@quickndirty.org>') : ()),
    'LIBS'		=> ['-lm -lcqcam -ljpeg'], 
    'DEFINE'		=> '-DLINUX -DJPEG -DLOCKING', 
    'CC'                => $CC,
    'LD'                => '$(CC)',
    # Now, this part is tricky
    # In the libcqcam are a number of C header files
    # I expect you to build libcqcam yourself.
    # I still didn't figure out how to have the make included in this process
    # Copy the output libcqcam.a (or however it is called), in a library path
    # that is available by ld.
    'INC'		=> '-Ilibcqcam -Llibcqcam',
    'XSOPT'             => '-C++',
    'TYPEMAPS'          => ['perlobject.map'],
    'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
);