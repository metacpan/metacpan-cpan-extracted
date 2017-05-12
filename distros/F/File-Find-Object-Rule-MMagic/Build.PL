# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "File::Find::Object::Rule::MMagic",
    license     => 'perl',
    dist_author => 'Shlomi Fish <shlomif@cpan.org>',
    configure_requires =>
    {
        'Module::Build' => 0.36,
    },
    requires    => {
        'Text::Glob' => 0,
        'File::Find::Object::Rule' => 0,
        'File::MMagic' => 0,
        'parent' => 0,
        'perl' => '5.008',
        'strict' => 0,
        'vars'               => 0,
        'warnings'           => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    create_makefile_pl => 'traditional',
    meta_merge =>
    {
        resources =>
        {
            repository => "http://svn.berlios.de/svnroot/repos/web-cpan/File-Find-Object/",
            homepage => "http://www.shlomifish.org/open-source/projects/File-Find-Object/",
        },
        keywords =>
        [
            "file",
            "file extensions",
            "file-find-object-rule",
            "file-find-rule",
            "file types",
            "find",
            "mime",
            "MIME",
            "mime types",
            "mmagic",
            "object",
            "types",
        ],
    },
);

$build->create_build_script;

