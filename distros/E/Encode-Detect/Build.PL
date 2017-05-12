use Module::Build;
my $build = Module::Build->new
    (
     module_name => 'Encode::Detect',
     license => 'mozilla',
     requires => { 'Module::Build' => 0,
                   'ExtUtils::CBuilder' => 0,
               },
     create_makefile_pl => 'passthrough',
     c_source => 'src',
     pm_files => { 'Detect.pm' => 'lib/Encode/Detect.pm',
		   'Detector.pm' => 'lib/Encode/Detect/Detector.pm',
	       },
     xs_files => { 'Detector.xs' => 'lib/Encode/Detect/Detector.xs' },
     dist_version_from => 'Detect.pm',
     extra_compiler_flags => ['-x', 'c++', '-Iinclude'],
     extra_linker_flags => ['-lstdc++'],
    );
$build->create_build_script;

