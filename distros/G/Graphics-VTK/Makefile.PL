
use ExtUtils::MakeMaker;
use Config;

$CCFLAGS = ' ';
require "./VTK.config";

my $dynamic_lib;
# Solaris seems to need these flags when running 
#   Suns C++ Compiler
if( $Config{'osname'} eq 'solaris' &&
	$vtkConfigMacro{CC} eq 'CC'){
	
	$CCFLAGS .= ' -DHAS_BOOL ';
	$vtkConfigMacro{LIBS}[0] .= ' -lCrun -lCstd ';
}
	
$VERSION = '4.0.001';

WriteMakefile(
    'NAME' => 'Graphics::VTK',
    'CCFLAGS' => $CCFLAGS,
    'DISTNAME' => 'PerlVTK',
    'OPTIMIZE'   => ' ', # Turn optimize off, optimization on cause very large
    			# memory consumption when compiling VTK.c
    'VERSION_FROM'  => 'VTK.pm',
    'CONFIGURE' => sub { return \%vtkConfigMacro },
   );



