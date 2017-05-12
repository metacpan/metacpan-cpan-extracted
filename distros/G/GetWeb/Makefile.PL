use ExtUtils::MakeMaker;

$VERSION="1.11";

# borrowed from libwww-perl

require 5.002;

$| = 1;
my $missing_modules = 0;

print "Checking for LWP.";
eval {
    require LWP;
    LWP->require_version('5.04');
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The GetWeb server relies on LWP (libwww-perl) 5.04 or later.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print "Checking for MIME-tools.";
eval {
    require MIME::Entity;
};
if ($@) {
    print " failed\n";
    $missing_modules++;
    print <<EOT;
$@
The GetWeb server relies on MIME-tools 2.04 or later.

EOT
    sleep(2);  # Don't hurry too much
} else {
    print " ok\n";
}

print <<EOT if $missing_modules;
The missing modules can be obtained from CPAN.  Visit
<URL:http://www.perl.com/CPAN/> to find a CPAN site near you.

EOT


@programs_to_install = (); # qw( getweb.pl );

WriteMakefile(
	NAME => "GetWeb",
	DISTNAME => "GetWeb",
	VERSION => $VERSION,
     PL_FILES      => { map {("bin/$_.PL" => "bin/$_")} @programs_to_install },
     EXE_FILES     => [ map {"bin/$_"} @programs_to_install ],
     'clean'       => { FILES => '$(EXE_FILES)' },
	# EXE_FILES => [ qw( getweb.pl ) ],
	dist => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
);

sub MY::test {
    q(
test:
	-ln -s ../../pub t/testRoot/ 2> /dev/null
	-ln -s ../../pub t/quotaTestRoot/ 2> /dev/null
	@echo making sure there is no AutoLoader.pm cleanup bug...
	@$(FULLPERL) getweb.pl -r t/testRoot -i -s 'test' -b 'help' | grep DESTROY.al 2> /dev/null; \
	if [ $$? -eq "0" ]; then \
		echo "You must use AutoLoader.patch; see README file. Test failed!" 1>&2; \
		exit 1; \
		fi
	$(FULLPERL) t/TEST
);
}
