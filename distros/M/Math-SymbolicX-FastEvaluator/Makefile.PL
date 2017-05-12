use 5.006002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

#my $obj_files = join ' ', map {
#  my $c = $_;
#  $c =~ s/\.cc$/$Config::Config{_o}/;
#  $c;
#} glob("*.cc");

my $CC = 'g++';

WriteMakefile(
    NAME              => 'Math::SymbolicX::FastEvaluator',
    VERSION_FROM      => 'lib/Math/SymbolicX/FastEvaluator.pm', # finds $VERSION
    PREREQ_PM         => {
      'aliased' => '0.22',
      'Math::Symbolic' => '0.510',
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/SymbolicX/FastEvaluator.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '-O2', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
     OBJECT            => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++ -hiertype',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => $CC,
    'LD'                => '$(CC)',

);
