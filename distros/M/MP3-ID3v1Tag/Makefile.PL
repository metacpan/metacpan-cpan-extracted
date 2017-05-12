#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# $Id: Makefile.PL,v 2.8 2000/03/14 18:29:05 sander Exp $
# $Source: /cvs/root/packages/perl/id3v1/Makefile.PL,v $
#
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
require 5.004;
use strict;
use ExtUtils::MakeMaker;

$| = 1;
my $missing_modules = 0;

print "Checking for IO::File....";
eval {
   require IO::File;
};
if ($@) {
   print " failed\n";
   $missing_modules++;
   print <<"EOT";
$@
The IO package must be installed. Just get the latest IO package.
 
EOT
   sleep(2);
} else {
   print " ok\n";
}

print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN.  Visit
<URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

Or use the handy Bundle::CPAN by Andreas Konig.

EOT

# Ok, now it is time to really generate the Makefile

sub MY::postamble {

  return <<'EOT';
ck_version :
	@perl -MExtUtils::MakeMaker -le 'print "Version: " . MM->parse_version(shift)' $(VERSION_FROM)

cvs_export :
	cvs export -r$(NAME_SYM)_$(VERSION_SYM) -d$(DISTVNAME) $(CVS_PACKAGE)

cvs_tag :
	cvs tag $(NAME_SYM)_$(VERSION_SYM) .
	@echo tagged all files with $(NAME_SYM)_$(VERSION_SYM)

EOT
}

WriteMakefile(
   NAME          => 'MP3::ID3v1Tag',
   VERSION_FROM  => 'lib/MP3/ID3v1Tag.pm',
   macro         => {
        CVS_PACKAGE => 'id3v1'
                    },
   'dist'        => { 
        COMPRESS    => 'gzip -9f', 
        SUFFIX      => 'gz', 
        CI          => 'cvs commit'
                    },
);

