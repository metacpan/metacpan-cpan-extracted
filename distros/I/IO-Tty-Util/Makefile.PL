use strict ;

use ExtUtils::MakeMaker ;
use Config ;

my $ccflags = $Config{ccflags} ;
my @C_INC = ($Config{usrinc}) ;
while ($ccflags =~ /-I(\S+)/g){
	push @C_INC, $1	;
}

foreach my $header (qw(pty.h utmp.h)){
	my $found = 0 ;
	foreach my $dir (@C_INC){
		if (-f "$dir/$header"){
			$found = 1 ;
			print "Found $header in $dir.\n" ;
			last ;
		}
	}
	die("Can't find $header in any of " . join(', ', @C_INC)) unless $found ;
}

WriteMakefile(
    NAME              => 'IO::Tty::Util',
    VERSION_FROM      => 'lib/IO/Tty/Util.pm',
    PREREQ_PM         => {}, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/IO/Tty/Util.pm', # retrieve abstract from module
       AUTHOR         => 'Patrick LeBoutillier <patl@cpan.org>') : ()),
    LIBS              => ['-lutil'], # e.g., '-lm'
);
