use 5.006001;
use Inline::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::Backgammon',
    'VERSION_FROM'	=> 'Backgammon.pm', # finds $VERSION
    'PREREQ_PM'		=> {
        List::Util        => 1.07,
        Inline            => 0.44,
        Carp              => 0,
        Data::Dumper      => 0,

        Test::More        => 0,
        Test::Differences => 0.45,
        Test::Exception   => 0.12,
        Test::Warn        => 0.05,
        Set::Scalar       => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Backgammon.pm', # retrieve abstract from module
       AUTHOR     => 'Janek Schleicher <bigj@kamelfreund.de>') : ()),
);
__END__
print "Sorry, I have to compile the gnubg program, that can need some time :-(\n";

if (-d gnubg) {
   print "gnubg seems to be already uncompressed\n";
} else {
   print "Un-Tarring gnubg\n";
   use Archive::Tar;
   Archive::Tar->extract_archive('gnubg.tar');
}

chdir 'gnubg';

print "Configuring gnubg\n";
system("./configure") == 0 or warn "Couldn't configure gnubg";

print "Making gnubg\n";
system("make") == 0 or warn "Couldn't make gnubg";

chdir '..';

