use inc::Module::Install 0.68;
use Devel::AssertOS 'Linux';
use Devel::CheckLib;
use Config;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/Linux/Input/Wiimote.pm > README' );

    include 'Devel::CheckLib';
    include 'Devel::CheckOS';
    include 'Devel::AssertOS';
    include 'Devel::AssertOS::Linux';
}

my @libs = ( 'cwiimote', 'bluetooth' );
my $libpath = [ grep { -d } split( / /, $Config{'libpth'} ) ];
check_lib_or_exit( lib => \@libs, libpath => $libpath ); 

name 'Linux-Input-Wiimote';
all_from 'lib/Linux/Input/Wiimote.pm';

test_requires 'Test::More';

makemaker_args
    INC    => '-Isrc/libwiimote-0.4/src',
    LIBS   => join( ' ', map { "-l${_}" } @libs ),
    DEFINE => '-D_ENABLE_TILT -D_ENABLE_FORCE';

auto_install;
WriteAll;
