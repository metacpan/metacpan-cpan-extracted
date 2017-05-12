require 5.006001;
use ExtUtils::MakeMaker;

my $clean = {};

if (-f "Util.xs") {
    print STDERR "Making header files for XS...\n";
    do 'mkheader' or die $@ || "mkheader: $!";
    $clean = { FILES => 'lkhutmp.h' };
}

WriteMakefile(
    'NAME'		=> 'Lingua::KO::Hangul::Util',
    'VERSION_FROM'	=> 'Util.pm',
    'ABSTRACT_FROM'	=> 'Util.pm',
    'AUTHOR'		=> 'SADAHIRO Tomoyuki <SADAHIRO@cpan.org>',
    'LICENSE'		=> 'perl',
    'clean'		=> $clean,
    'PREREQ_PM'	  	=> {
	bytes		=> 0,
	Carp		=> 0,
	constant	=> 0,
	DynaLoader	=> 0,
	Exporter	=> 0,
	File::Copy	=> 0,
	strict		=> 0,
	warnings	=> 0,
    },
);
