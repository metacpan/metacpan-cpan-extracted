use strict;
BEGIN {
	require 5.005;
}
use ExtUtils::MakeMaker;
use Config;

my @libs = ();
unless ( $Config{d_inetaton} or $^O eq 'MSWin32' ) {
	push @libs, '-lresolv';
}

WriteMakefile(
	NAME	     => 'IO::Socket::Multicast',
	ABSTRACT     => 'Send and receive multicast messages',
	VERSION_FROM => 'lib/IO/Socket/Multicast.pm',
	LIBS	     => \@libs, # e.g., '-lm' 
	DEFINE	     => '',     # e.g., '-DHAVE_SOMETHING' 
	INC	     => '',     # e.g., '-I/usr/include/other'
	PREREQ_PM    => {
		$^O eq 'MSWin32' ? () : ( 'IO::Interface' => 0.94 ),
	},
	($ExtUtils::MakeMaker::VERSION ge '6.30_00' ? (
		LICENSE => 'perl',
	) : ()),
);
