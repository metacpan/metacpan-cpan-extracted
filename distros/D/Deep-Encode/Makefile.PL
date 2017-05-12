use ExtUtils::MakeMaker;
use constant { MIN_PERL_VERSION => '5.008000' };
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
unless( $] >= MIN_PERL_VERSION ){
	my $ver = MIN_PERL_VERSION;
	for ( $ver ){
	    s/(\d\d\d)/print ".".(0+$1), "\n"; ".".(0+$1)/ge;
	    s/\.\./\./;
	};	
	print STDERR "perl $ver required. would not build\n";	
	exit 0;
}
WriteMakefile(
    NAME              => 'Deep::Encode',
    VERSION_FROM      => 'lib/Deep/Encode.pm', # finds $VERSION
    PREREQ_PM         => {
	Encode => 0,
	utf8   => 0,
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Deep/Encode.pod', # retrieve abstract from module
    AUTHOR         => 'A. G. Grishaev <grian@cpan.org>' ,
    $ExtUtils::MakeMaker::VERSION >= 6.48 ?  (MIN_PERL_VERSION => MIN_PERL_VERSION) : (),
    $ExtUtils::MakeMaker::VERSION >= 6.31 ?  ( LICENSE => 'perl') : (),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
