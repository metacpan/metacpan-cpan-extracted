use strict;
use Module::Build;

Module::Build->new(
   module_name => 'GD::SecurityImage::AC',
   license     => 'perl',
   requires    => { 
                     'GD::SecurityImage' => '1.60',
                     'Digest::MD5'       => 0,
   },
   recommends    => {},
   dist_author   => 'Benjamin Franz <snowhare@nihongo.org>',
   dist_abstract => 'A drop-in replacement for Authen::Captcha.'
)->create_build_script;
