use Module::Build;
Module::Build->new
    ( module_name => 'MetaStore',
    license => 'perl',
   prereq => {
       'Collection'=>'0.49',
       'Data::UUID'=>'0.11',
       'WebDAO'=>'2.20',
       'MIME::Base64'=>'3.07',
       'Archive::Zip'=>'1.16',
       'IO::Zlib'=>'1.04',
       'Template'=>'2.14',
       'XML::Flow'=>'0.86',
       'JSON'=>2.07
	     },
   dist_version_from=>'lib/MetaStore.pm',
   dist_author=>'Zahatski Aliaksandr zag@cpan.org',
    create_makefile_pl=>$ENV{DO_OUTCPAN} ? 'traditional':'passthrough'
    )->create_build_script;
