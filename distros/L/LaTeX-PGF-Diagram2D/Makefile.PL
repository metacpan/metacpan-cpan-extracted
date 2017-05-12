use 5.000000;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME              => 'LaTeX::PGF::Diagram2D',
    VERSION_FROM      => 'lib/LaTeX/PGF/Diagram2D.pm', # finds $VERSION
    PREREQ_PM         => {
    			    'PDL' => 0,
			    'Carp' => 0
    			 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/LaTeX/PGF/Diagram2D.pm',
       AUTHOR         => 'Dirk Krause <krause@localdomain>') : ()),
);

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Unfortunately we can not produce the Makefile as shown below because
# it doesn't work on Windows and other systems without a shell!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# sub MY::postamble
# {
#   return "\ndocu:\n\t./build-docu.sh\n\n";
# }
# 
# my @lines;
# my $nlines = 0;
# my $fh = undef;
# my $i;
# if(open($fh, "<Makefile")) {
#   while(<$fh>) {
#     $line = $_;
#     $line =~ s/\r//go;
#     $line =~ s/\n//go;
#     $lines[$nlines++] = $line;
#   }
#   close($fh);
#   $fh = undef;
#   if(open($fh, ">Makefile")) {
#     for($i = 0; $i < $nlines; $i++) {
#       $line = $lines[$i];
#       if($line =~ /^all\s*:.*$/o) {
#         $line = $line . " docu";
#       }
#       print $fh "$line\n";
#     }
#   }
# }

