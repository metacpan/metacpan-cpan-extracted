use ExtUtils::MakeMaker;

# NOTE! Change this line if we write any new scripts!
my @scripts = qw(basic.pl basic2pl.pl termbasic.pl);
my $dir = "scripts";
my $exe_files = [map {"$dir/$_"} @scripts];

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Language::Basic',
    'VERSION_FROM' => 'lib/Language/Basic.pm', # finds $VERSION
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz'}, # use gzip, not compress
    'EXE_FILES' => $exe_files, # executable files to install in bin
);
