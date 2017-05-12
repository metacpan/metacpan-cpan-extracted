# This -*- perl -*- script makes the Makefile

require 5.008; # 5.006_002 fails

use ExtUtils::MakeMaker;

#push @Safe, OPTIMIZE => '-Wall' if 1;

# Parasoft's Insure++!
push @Safe, OPTIMIZE => '-g' if 0;
push @Safe, CC => 'insure', LD => 'insure', OPTIMIZE => '-g' if 0;

my @opt=(PREREQ_PM => { Test => 1 },
	 MIN_PERL_VERSION  => 'v5.8.0',
	 VERSION_FROM	=> "./lib/Event.pm",
	 NAME      	=> "Event",
	 TYPEMAPS       => ['./lib/Event/typemap'],
	 INC		=> '-Ic -Ilib/Event',
	 H		=> [glob("c/*"), glob("*.h"), "lib/Event/EventAPI.h"],
	 @Safe,
	 'clean'   	=> {FILES => join(" ",
					  map { "$_ */$_ */*/$_" }
					  qw(*% *.html *.b[ac]k *.old *.orig))
			   },
	 META_MERGE => {
	   "meta-spec" => { version => 2 },
	   resources => {
	     repository => {
	       type => 'git',
	       url => 'https://github.com/mohawk2/cpan-Event.git',
	       web => 'https://github.com/mohawk2/cpan-Event',
	     },
	   },
	 },
	);

WriteMakefile(@opt);
