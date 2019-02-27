use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'MikroTik::Client',
    VERSION_FROM => 'lib/MikroTik/Client.pm',
    ABSTRACT     => 'Non-blocking MikroTik API client',
    AUTHOR       => 'Andre Parker <andreparker@gmail.com>',
    LICENSE      => 'artistic_2',
    META_MERGE   => {
        dynamic_config => 0,
        'meta-spec'    => {version => 2},
        no_index       => {directory => ['t']},
        prereqs        => {runtime => {requires => {perl => '5.012000'}}},
        resources      => {
            bugtracker =>
                {web => 'https://github.com/anparker/mikrotik-client/issues'},
            license =>
                ['http://www.opensource.org/licenses/artistic-license-2.0'],
            repository => {
                type => 'git',
                url  => 'https://github.com/anparker/mikrotik-client.git',
                web  => 'https://github.com/anparker/mikrotik-client',
            },
        },
    },
    PREREQ_PM => {'AnyEvent' => '7.00'},
    test      => {TESTS      => 't/*.t'},
);

