
use Tk::MMutil;

Tk::MMutil::TkExtMakefile(
      'NAME' => 'Graphics::VTK::Tk::vtkImageWindow',

    'VERSION'  => $VERSION,
    'XS_VERSION' => $VERSION,
    'DISTNAME' => "VTK",
    'LIBS'    => \@libs,
    'OBJECT'  => '$(O_FILES)',
    @macro,
    'CONFIGURE' => sub { my $configHash = {%vtkConfigMacro};
    			 $configHash->{INC} = "-I../../ -I$ptkPath -I../pTk -I$ptkPath/pTk ".$configHash->{INC};
			 return $configHash; },
    'OPTIMIZE'   => ' ', # Turn optimize off, optimization on cause very large
    			# memory consumption when compiling VTK.c
    'CCFLAGS'   => $CCFLAGS,
    'MYEXTLIB' => '../pTk/libpTk$(LIB_EXT) ../vtkGlue/libvtkGlue$(LIB_EXT)' . ($win_arch =~ /^(open32|pm)$/
					    ? ' pTk/dllInit$(LIB_EXT)'
					    : ''),
      'dynamic_ptk' => 1
      );
