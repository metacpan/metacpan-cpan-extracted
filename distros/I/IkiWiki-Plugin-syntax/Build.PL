#!/usr/bin/perl

use strict;
use warnings;
use Module::Build::IkiWiki;

my $builder = Module::Build::IkiWiki->new(
    module_name         => 'IkiWiki::Plugin::syntax',
    license             => 'gpl',
    dist_author         => '"Victor Moral" <victor@taquiones.net>',
    dist_version_from   => 'lib/IkiWiki/Plugin/syntax.pm',
    requires => {
        'Module::Build::IkiWiki'            =>  0,
        'Class::Accessor::Fast'             =>  0,
        'Test::More'                        =>  0,
        'Exception::Class'                  =>  0,
        'File::Basename'                    =>  0,
        'File::Spec'                        =>  0,
        'HTML::Entities'                    =>  0,
        'HTML::Template'                    =>  0,
        'IO::Dir'                           =>  0,
        'IO::File'                          =>  0,
        'URI::Escape'                       =>  0,
    },
    recommends  =>  {
        'Test::Pod'                         =>  '1.14',
        'Test::Exception'                   =>  0,
        'Test::Distribution'                =>  0,
        'Syntax::Highlight::Engine::Kate'   =>  0,
        'Text::VimColor'                    =>  0,
    },
    auto_features   =>  {
        kate_engine     =>  {
            description =>  q(Syntax::Highlight::Engine::Kate as external engine),
            requires    =>  {
                'Syntax::Highlight::Engine::Kate'   =>  0,
            },
        },
        vim_engine  =>  {
            description =>  q(Text::VimColor as external engine),
            requires    =>  {
                'Text::VimColor'    =>  0,
            },
        },
    },
    add_to_cleanup      => [ 
        'IkiWiki-Plugin-syntax-*',
        'ikiwiki-plugin-syntax*' 
        ],
    create_packlist     =>  0,
    installdirs         =>  q(vendor),
    meta_merge          =>  {
        resources   =>  {
            homepage    =>  q(http://taquiones.net/software/factory/syntax.html),
        },
    },
    meta_add            =>  {
        no_index        =>  {
            directory   =>  [ qw(t/lib examples) ],
        },
    },
    ikiwiki_templates   =>  [ glob "extras/*.tmpl" ],
    ikiwiki_css         =>  [ glob "extras/*.css" ],
);

$builder->create_build_script();
