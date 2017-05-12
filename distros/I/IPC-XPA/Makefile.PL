use ExtUtils::MakeMaker;
use Config;

qx{ pkg-config --exists xpa };

if ( $? )
{
    $CCFLAGS= $ENV{XPA_CFLAGS} || '';
    $INC  = $ENV{XPA_INC} || '-I/soft/saord/include';
    $LIBS = $ENV{XPA_LIBS} || '-L/soft/soard/lib -lxpa';
}
else
{
    chomp( $INC = qx{ pkg-config --cflags-only-I xpa } );
    chomp( $CCLAGS = qx{ pkg-config --cflags-only-other xpa } );
    chomp( $LIBS =  qx{ pkg-config --libs xpa } );
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'IPC::XPA',
    'VERSION_FROM' => 'XPA.pm',
    'CCFLAGS'	=> $CCFLAGS,
    'INC'	=> $INC,
    'LIBS'	=> [$LIBS],
    'OBJECT'	=> 'XPA.o util.o',
    'PREREQ_PM' => { Test::More => 0 },
);
