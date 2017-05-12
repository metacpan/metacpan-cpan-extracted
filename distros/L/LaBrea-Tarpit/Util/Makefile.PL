use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $name       = 'LaBrea::Tarpit::Util';
@_ = split('::',$name);
my $src        = $_[$#_] . '.pm';
my $pod        = $_[$#_] . '.3';

WriteMakefile(
   'NAME'         => $name,
   'VERSION_FROM' => $src,		# finds $VERSION
   'PM'           => {$src	=> '$(INST_LIBDIR)/' .$src},
   'dist'         => {COMPRESS	=> 'gzip', SUFFIX => 'gz'}
);
