require 5.004;
use ExtUtils::MakeMaker;

if ("foo" !~ /\Afoo\z/) {
    for $file ("Query") {
	print "\\z not supported by this perl.  Fixing $file.pm...\n";
	rename("$file.pm", "$file.pm.bak") || die;
	open( IN, "<$file.pm.bak" ) || die;
	open( OUT, ">$file.pm" ) || die;
	while( <IN> ) {
	    $_ =~ s/\\z/\\Z/g;
	    print OUT;
	}
	close( OUT ) || die;
	close( IN ) || die;
    }
}

WriteMakefile(
    'NAME'	   => 'Games::Quakeworld::Query',
    'VERSION_FROM' => 'Query.pm',
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
