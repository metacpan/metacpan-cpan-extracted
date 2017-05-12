use ExtUtils::MakeMaker;

$| = 1;
print "Checking for Logfile::Base ... ";
eval { require Logfile::Base; };
if ($@) {
    print STDERR "\nYou must have installed the 'Logfile::Base' module.\n";
    print STDERR "You get it at the CPAN. See 'man CPAN' or 'perldoc CPAN'";
    print STDERR "for more info.\n";
    exit 10;
}
print "ok\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Logfile::Radius',
    'VERSION_FROM' => 'Radius.pm', # finds $VERSION
    'PREREQ_PM' => { 'Logfile::Base' => 0 ,
                     'File::Copy' => 2.02 }, # requires the Logfile module
    'dist'         => {
		COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
    },
);
