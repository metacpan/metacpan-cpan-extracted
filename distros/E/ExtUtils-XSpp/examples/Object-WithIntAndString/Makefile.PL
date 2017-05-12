use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $CC = 'g++';

WriteMakefile(
    NAME              => 'Object::WithIntAndString',
    VERSION_FROM      => 'lib/Object/WithIntAndString.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::XSpp' => '0.01',
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Object/WithIntAndString.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
    OBJECT            => '$(O_FILES)', # link all the C files too
    XSOPT             => '-C++ -hiertype',
    #TYPEMAPS          => ['other_xs_typemap_files_here'],
    CC                => $CC,
    LD                => '$(CC)',
);

