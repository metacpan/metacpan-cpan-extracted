
my %configHash = %vtkConfigMacro;

$configHash{INC} = '-I../ '.$configHash{INC}; # Add another dir to include path


WriteMakefile(
    'NAME'	=> 'Graphics::VTK::Filtering',
    'CCFLAGS'   => $CCFLAGS,
    'OPTIMIZE'   => ' ', # Turn optimize off, optimization on cause very large
    			# memory consumption when compiling VTK.c
    'VERSION_FROM' => '../VTK.pm',
    'TYPEMAPS' => [ qw[ ../typemap typemapFiltering ../Common/typemapCommon ../Imaging/typemapImaging] ],
    %configHash,
    
);
