use strict;
use Module::Build;

Module::Build->new(
    module_name => "Mail::Thread::Arc",
    license     => 'perl',
    requires    => {
        'Class::Accessor::Chained' => 0,
        'Date::Parse'  => 0,
        'SVG'          => 0,
        'Mail::Thread' => '2.41',
        'Test::More'   => 0,
    },
    create_makefile_pl => 'passthrough',
   )
  ->create_build_script;
