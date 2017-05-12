BEGIN {
   eval { require Storable; };
   if ($@) {
       print <<EOT;
Storable.pm NOT installed (!?). You'll have to do something useful using
data/cedict.b5.utf8 yourself.
EOT
    } else {
        print "Trying to parse CEDICT - please wait...\n";
        eval { require "bin/import_storable.pl"; };
        print <<EOT if $@;
An error occured while trying to parse the CEDICT file.
$@
EOT
    }
    
    print "\n";
}

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'ABSTRACT'     => 'Interface for CEDICT, a Chinese-English dictionary',
    'AUTHOR'       => 'Christian Renz <crenz@web42.com>',
    'NAME'         => 'Lingua::ZH::CEDICT',
    'PREREQ_PM'    => {Test::More => 0}, # e.g., Module::Name => 1.1
    'VERSION_FROM' => 'lib/Lingua/ZH/CEDICT.pm', # finds $VERSION
);
