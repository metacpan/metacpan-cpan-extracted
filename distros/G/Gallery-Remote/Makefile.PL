use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'	=> 'Gallery::Remote',
    'VERSION_FROM' => 'Remote.pm', # finds $VERSION
);

if (open (IN, "Remote.pm")) {
    while (<IN>) {
	if ($_ =~ /^\$VERSION/) {
	    eval $_;
	} elsif ($_ =~ /^\$REVISION/) {
	    eval $_;
	}
    }
    close (IN);
}

if (open (IN, "Gallery-Remote.spec.in")) {
    if (open (OUT, ">Gallery-Remote.spec")) {
	while (<IN>) {
	    $_ =~ s/\@version\@/$VERSION/g;
	    $_ =~ s/\@release\@/$REVISION/g;
	    print OUT $_;
	}
	close (OUT);
    }
    close (IN);
}
