require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

$MCRYPT_LDFLAGS = $ENV{MCRYPT_LDFLAGS} ;
$MCRYPT_CPPFLAGS = $ENV{MCRYPT_CPPFLAGS} ;

WriteMakefile(
	NAME		=> 'Mcrypt',
	VERSION_FROM	=> 'Mcrypt.pm',
	LIBS		=> [ "$MCRYPT_LDFLAGS -lltdl -lmcrypt" ],
	INC		=> " $MCRYPT_CPPFLAGS" ,
	);
