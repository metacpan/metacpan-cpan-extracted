use 5.008005;
use ExtUtils::MakeMaker;
use File::Copy;

my $srcdir = 'src';
my @srccode = qw(cov.c ranlib.c com.c linpack.c spectrum.c fft.c hosking.c circulant.c apprcirc.c paxson.c);
my $srccode = join(" ", @srccode);

foreach( @srccode )
{
 copy("$srcdir/$_",".");
}

WriteMakefile(
    NAME              => 'Math::Random::Brownian',
    VERSION_FROM      => 'lib/Math/Random/Brownian.pm', # finds $VERSION
    PREREQ_PM         => {Params::Validate => 0.72}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Math/Random/Brownian.pm', # retrieve abstract from module
       AUTHOR         => 'Walter Szeliga <walter@geology.cwu.edu>') : ()),
    LIBS              => ['-lm'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I. -I./src',
    C                 => [@srccode, 'Brownian.c'],
	# Un-comment this if you add C files to link with later:
    OBJECT            => '$(O_FILES)',
    clean             => {FILES => $srccode},
);

if  (eval {require ExtUtils::Constant; 1}) {
  # If you edit these definitions to change the constants used by this module,
  # you will need to use the generated const-c.inc and const-xs.inc
  # files to replace their "fallback" counterparts before distributing your
  # changes.
  my @names = (qw());
  ExtUtils::Constant::WriteConstants(
                                     NAME         => 'Math::Random::Brownian',
                                     NAMES        => \@names,
                                     DEFAULT_TYPE => 'IV',
                                     C_FILE       => 'const-c.inc',
                                     XS_FILE      => 'const-xs.inc',
                                  );
 
}
else {
  use File::Copy;
  use File::Spec;
  foreach my $file ('const-c.inc', 'const-xs.inc') {
    my $fallback = File::Spec->catfile('fallback', $file);
    copy ($fallback, $file) or die "Can't copy $fallback to $file: $!";
  }
}
