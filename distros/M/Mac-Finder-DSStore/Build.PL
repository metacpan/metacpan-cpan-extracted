use Module::Build 0.19;

Module::Build->new
    (
     module_name => 'Mac::Finder::DSStore',
     dist_author => 'Wim Lewis <wiml@hhhh.org>',
     dist_abstract => "Manipulates the Macintosh Finder's .DS_Store files.",
     license => 'perl',
     
     pm_files => {
         'DSStore.pm' => 'lib/Mac/Finder/DSStore.pm',
         'BuddyAllocator.pm' => 'lib/Mac/Finder/DSStore/BuddyAllocator.pm'
         },
     pod_files => {
         'DSStoreFormat.pod' => 'lib/Mac/Finder/DSStore/Format.pod'
         },
     dist_version_from => 'DSStore.pm',

     requires => {
         perl => '5.6.1',
         Encode => '1.20'
     },
     recommends => {
         'Mac::Files' => 0,
         'Mac::Memory' => 0,
         'Mac::PropertyList' => '1.39',
     },
     build_requires => {
	'Test::More' => '0.61',
	'Test::NoWarnings' => 0
     },

     sign => 1,
     dynamic_config => 0

    )
    ->create_build_script;
