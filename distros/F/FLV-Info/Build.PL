use Module::Build;
Module::Build->new(
   module_name => 'FLV::Info',
   dist_author => 'Clotho Advanced Media, Inc. <cpan@clotho.com>',
   license => 'perl',
   requires => {
      'perl'        => 5.008,
      'AMF::Perl'   => 0.15,
      'List::Util'  => 1.00,
      'List::MoreUtils'  => 0,
      'Digest::MD5' => 2.00,
      'SWF::File'   => 0.033,
      'Readonly'    => 0,
   },
   build_requires => {
      'Test::More'  => 0,
   },
   script_files => ['bin/flvinfo',
                    'bin/swf2flv',
                    'bin/flv2swf',
                    'bin/flv2flv',
                    'bin/flv2mp3'],
   add_to_cleanup => [ 'FLV-Info-*' ],
   create_readme => 1,
   create_makefile_pl => 'traditional',
)->create_build_script;
