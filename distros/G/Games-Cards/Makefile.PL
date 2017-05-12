use ExtUtils::MakeMaker;

# Get installable scripts (i.e., all .pl files) from script directory
my $dir = "script";
opendir SCRIPTDIR, $dir or die "There's supposed to be a 'script' directory!\n";
my @scripts = map {"$dir/$_"} grep /.*\.pl$/, readdir SCRIPTDIR;
my $exe_files = \@scripts;
closedir SCRIPTDIR;

# Create the Makefile
WriteMakefile(
    'NAME'	=> 'Games::Cards',
    'VERSION_FROM' => 'lib/Games/Cards.pm', # finds $VERSION
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz'},
    'EXE_FILES' => $exe_files, # executable files to install in bin
);

