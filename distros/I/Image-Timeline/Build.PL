use Module::Build;

my $build = Module::Build->new
  (
   module_name => 'Image::Timeline',
   license => 'perl',
   pm_files => { 'Timeline.pm' => 'lib/Image/Timeline.pm' },
   dist_version_from => 'Timeline.pm',
   requires => {
		'GD' => 0,
	       },
   recommends => {
		  'Date::Format' => 0,
		 },
   build_requires => {
		      'Test' => 0,
		     },
   create_makefile_pl => 'traditional',
   add_to_cleanup => [qw(t/testimage.gif t/testimage.png t/testimage_format.gif t/testimage_format.png)],
   sign => 1,
  );

$build->create_build_script;
