# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use lib "./inc";

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "File::Find::Object::Rule",
    license     => 'perl',
    script_files => [ 'scripts/findorule' ],
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires    => {
        'Carp'               => 0,
        'Class::XSAccessor'  => 0,
        'Cwd'                => 0,
        'File::Basename'     => 0,
        'File::Find::Object' => '0.2.1',
        'File::Spec'         => 0,
        'Number::Compare'    => 0,
        'perl'               => '5.008',
        'strict'             => 0,
        'Text::Glob'         => 0,
        'vars'               => 0,
        'warnings'           => 0,
    },
    build_requires => {
        'Test::More'      => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/perl-file-find-object-rule",
            homepage => "http://www.shlomifish.org/open-source/projects/File-Find-Object/",
        },
        keywords =>
        [
            "directories",
            "directory",
            "directory-traversal",
            "directory-tree",
            "file",
            "file-find-rule",
            "find",
            "instance",
            "instantiated",
            "instantiation",
            "interface",
            "iterative",
            "object",
            "rule",
            "traversal",
            "tree",
            "wrapper",
        ],
    },

   );

$build->create_build_script;
