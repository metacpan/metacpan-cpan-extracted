#!/usr/bin/perl
use ExtUtils::MakeMaker;

# Do our own prerequisite checking
# Stolen from Net::FTPServer which stole from libwww-perl
my %modules =
(
 #'Test::More' =>     { min_version => "0" },
 'MIME::Base64' =>   { min_version => "2.20",
		       rec_version => "3.03" },
 );

my($m, $foundit, $foundrec, @missing);
@missing = ();
foreach $m (sort keys %modules) {
    $foundit = 0;
    $foundrec = 0;
    my $min_ver = $modules{$m}{min_version};
    my $rec_ver = $modules{$m}{rec_version};
    if (defined($rec_ver)) {
	print "Checking for module $m (version $rec_ver)... ";
	my $eval = "require $m; $m->VERSION >= $rec_ver;";
	my $r = eval($eval);
	if ($@ || !$r) {
	    print "not found.\n --- Fallback: ";
	} else {
	    $foundit = 1;
	    $foundrec = 1;
	    print "ok.\n";
	}
    }
    if (!$foundit) {
	print "Checking for module $m (version $min_ver)... ";
	my $eval = "require $m; $m->VERSION >= $min_ver;";
	my $r = eval($eval);
	if ($@ || !$r) {
	    print "not found.\n";
	} else {
	    $foundit = 1;
	    print "ok.\n";
	}
    }
    if (defined($rec_ver) and $foundit and !$foundrec) {
	print "\n   *** Warning: We can work with version $min_ver of $m, but\n   *** we recommend that you upgrade to version $rec_ver.\n\n";
	if ($m eq "MIME::Base64") {
	    print "   *** Note that if you type 'make test', then tests\n   *** 4, 5 and 7-11 of t/Misc.t may fail because of the old version\n   *** of $m\n";
	}
    }

    push @missing, "$m: At least version $min_ver" unless $foundit;
}

if ($#missing >= 0) {
    print "\n\n   *** The following required modules are missing:\n";
    foreach $m (@missing) {
	print "$m\n";
    }
    print "   *** Please install them before attempting to use MIME::Tools.\n";
}

# Why the PREREQ_PM below?  For automated tools like CPAN that try to be
# smart about following dependencies.
WriteMakefile(
      NAME         => "MIME-AltWords",
      VERSION_FROM => "lib/MIME/AltWords.pm",
      PREREQ_PM    => {
	               "MIME::Base64"      => 2.20,
                       "Test::More"        => 0,
		      },
      AUTHOR => 'Péter Szabó <pts@fazekas.hu>',
      ABSTRACT => 'Tools to manipulate MIME messages',
      'dist'       => {
	  COMPRESS     =>'gzip -f',
	  SUFFIX       =>'gz',
      },
);
