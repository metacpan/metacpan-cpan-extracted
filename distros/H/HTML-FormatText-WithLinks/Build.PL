use strict;
use Module::Build;

Module::Build
    ->new(
        module_name =>  "HTML::FormatText::WithLinks",
        license     =>  'perl',
        requires    =>  {
                            'HTML::FormatText'    =>  2,
                            'HTML::TreeBuilder'   =>  0,
                            'URI::WithBase'       =>  0,  
        },
        build_requires  =>  {
                            'Test::More'          =>  0,
                            },
        create_makefile_pl  =>  'traditional',
        meta_merge => {
                           resources => {
                                   repository => 'https://github.com/struan/html-formattext-withlinks'
                           }
        },
        )
    ->create_build_script;

