use Module::Build;

Module::Build->new
    (
     module_name => 'Mac::Alias::Parse',
     dist_author => 'Wim Lewis <wiml@hhhh.org>',
     dist_abstract => "Pure-Perl parser/constructor for Macintosh alias records.",
     license => 'perl',
     
     pm_files => {
         'Parse.pm' => 'lib/Mac/Alias/Parse.pm'
         },
     dist_version_from => 'Parse.pm',

     requires => {
         perl => '5.7.1',
         'Math::BigInt' => 0,
         'Math::BigFloat' => 0,
         Encode => 0,
     },
     build_requires => {
         'Test::NoWarnings' => 0,
         'MIME::Base64' => 0,
     },

     meta_merge => {
         resources => {
             repository  => 'http://www.hhhh.org/src/hg/parsealias/',
         }
     },

     sign => 1,
     dynamic_config => 0

    )
    ->create_build_script;
