use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'MikroTik::Client',
    VERSION_FROM => 'lib/MikroTik/Client.pm',
    ABSTRACT     => 'Non-blocking MikroTik API client',
    AUTHOR       => 'Andre Parker <anparker@cpan.org>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.016'}}},
        resources      => {
            bugtracker =>
                {web => 'https://codeberg.org/anparker/mikrotik-client/issues'},
            license =>
                ['https://www.perlfoundation.org/artistic-license-20.html'],
            repository => {
                type => 'git',
                url  => 'https://codeberg.org/anparker/mikrotik-client.git',
                web  => 'https://codeberg.org/anparker/mikrotik-client',
            },
        },
    },
    PREREQ_PM => {'Mojolicious' => '7.054'},
    test      => {TESTS         => 't/*.t'},
);

