#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/manifest-write.t
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Write.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Write is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Write. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use lib 't/lib';
use strict;
use warnings;

use Test::Deep qw{ isa re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'ManifestWriteTester';

#   On MSWin32 platform `Dist::Zilla` rejects filenames containing backslashes with error:
#
#       File name 'FILENAME' does not seem to be legal on the current OS
#
#   To avoid test failure, let's exclude such names from testing on the problem platform.
#   Cygwin has (another) problem with backslashes too. It silently converts backslashes to slashes,
#   e. g. 'file\name` becomes `file/name`, and file creation fails because directory `file/` does
#   not exists.
#
my $backslash = $^O !~ m{^(cygwin|MSWin32)$};

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

# --------------------------------------------------------------------------------------------------

#   No source providers are specified, files will be recognized as "3rd party". However, default
#   metainfo providers work: `MANIFEST` and `META.yml` should be recognized properly.
run_me 'No source provider' => {
    expected => {
        manifest => [
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'dist.ini     # 3rd party file added by GatherDir',
            'lib/Dummy.pm # 3rd party file added by GatherDir',
            # There are no lines "Dummy file added by GatherDir"
        ],
    },
};

#   Source provider is specified, files will should be recognized as "Dummy" (it is name of the
#   distibution).
run_me 'One source provider' => {
    options => {
        source_provider => 'GatherDir',
        #                   ^^^^^^^^^
    },
    expected => {
        manifest => [
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'dist.ini     #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
            'lib/Dummy.pm #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
        ],
    },
};

run_me 'Multiple source providers of different type' => {
    options => {
        source_provider => [
            '',                         # Empty values are allowed.
            'GatherDir',
            '',
            'GenerateFile',
            '',
        ],
    },
    extra_plugins => [
        [ 'GenerateFile' => {           # REQUIRE: Dist::Zilla::Plugin::GenerateFile
            filename => 'README',
            content => 'Yep.',
        } ],
    ],
    expected => {
        manifest => [
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'README       #     Dummy file built by GenerateFile',
            #                   ^^^^^               ^^^^^^^^^^^^
            'dist.ini     #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
            'lib/Dummy.pm #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
        ],
    },
};

run_me 'Multiple source providers of different type in plural form option' => {
    options => {
        source_providers => 'GatherDir GenerateFile',
    },
    extra_plugins => [
        [ 'GenerateFile' => {           # REQUIRE: Dist::Zilla::Plugin::GenerateFile
            filename => 'README',
            content => 'Yep.',
        } ],
    ],
    expected => {
        manifest => [
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'README       #     Dummy file built by GenerateFile',
            #                   ^^^^^               ^^^^^^^^^^^^
            'dist.ini     #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
            'lib/Dummy.pm #     Dummy file added by GatherDir',
            #                   ^^^^^               ^^^^^^^^^
        ],
    },
};

run_me 'Multiple source providers of the same type' => {
    options => {
        source_provider => [
            'README file',      # < Space in plugin name.
            'GenerateFile',
            'GatherDir',
        ],
    },
    extra_plugins => [
        [ 'GenerateFile' => 'README file'  => {     # REQUIRE: Dist::Zilla::Plugin::GenerateFile
        #                    ^^^^^^^^^^^ plugin name
            filename => 'README',
            content => 'doc',
        } ],
        [ 'GenerateFile' => 'COPYING file' => {     # REQUIRE: Dist::Zilla::Plugin::GenerateFile
        #                    ^^^^^^^^^^^^ plugin name
            filename => 'COPYING',
            content => 'license',
        } ],
        [ 'GenerateFile'                   => {     # REQUIRE: Dist::Zilla::Plugin::GenerateFile
        # Default plugin name.
            filename => 'VERSION',
            content => 'v0.1.0',
        } ],
    ],
    # In case of `GatherDir` moniker and name are the same.
    # However, in case of `GenerateFile` we have 3 instances with different names.
    expected => {
        manifest => [
            'COPYING      # 3rd party file built by GenerateFile',
            #               ^^^^^^^^^ *Not* recognized as source.
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'README       #     Dummy file built by GenerateFile',
            #                   ^^^^^ Recognized as source.
            'VERSION      #     Dummy file built by GenerateFile',
            #                   ^^^^^ Recognized as source.
            'dist.ini     #     Dummy file added by GatherDir',
            #                   ^^^^^ GatherDir recognized by name.
            'lib/Dummy.pm #     Dummy file added by GatherDir',
            #                   ^^^^^ GatherDir recognized by name.
        ],
    },
};

run_me 'Empty metainfo provider cancels default' => {
    options => {
        source_provider     => 'GatherDir',
        metainfo_provider   => '',
        #                      ^^
    },
    expected => {
        manifest => [
            'MANIFEST     # 3rd party file built by Manifest::Write',
            #               ^^^^^^^^^^^^^^
            'META.yml     # 3rd party file built by MetaYAML',
            #               ^^^^^^^^^^^^^^
            'dist.ini     #     Dummy file added by GatherDir',
            'lib/Dummy.pm #     Dummy file added by GatherDir',
        ],
    },
};

run_me 'Plugin in custom location' => {
    options => {
        source_provider => [
            'GatherDir',
            '=CustomPlugin',
        ],
    },
    extra_plugins => [
        [ '=CustomPlugin' ],
    ],
    expected => {
        manifest => [
            'GeneratedFile.txt      #     Dummy file built by =CustomPlugin',
            #                                                 ^^^^^^^^^^^^^
            'MANIFEST               #  metainfo file built by Manifest::Write',
            'META.yml               #  metainfo file built by MetaYAML',
            'dist.ini               #     Dummy file added by GatherDir',
            'lib/Dummy.pm           #     Dummy file added by GatherDir',
            'lib/GeneratedModule.pm #     Dummy file built by =CustomPlugin',
            #                                                 ^^^^^^^^^^^^^
            'lib/InlineModule.pm    #     Dummy file built by =CustomPlugin',
            #                                                 ^^^^^^^^^^^^^^
        ],
    },
};

run_me 'Named plugin in custom location' => {
    options => {
        source_provider => [
            'GatherDir',
            'custom plugin',
        ],
    },
    extra_plugins => [
        [ '=CustomPlugin' => 'custom plugin' ],
    ],
    expected => {
        manifest => [
            'GeneratedFile.txt      #     Dummy file built by =CustomPlugin',
            #                                                 ^^^^^^^^^^^^^ Plugin moniker, not name.
            'MANIFEST               #  metainfo file built by Manifest::Write',
            'META.yml               #  metainfo file built by MetaYAML',
            'dist.ini               #     Dummy file added by GatherDir',
            'lib/Dummy.pm           #     Dummy file added by GatherDir',
            'lib/GeneratedModule.pm #     Dummy file built by =CustomPlugin',
            'lib/InlineModule.pm    #     Dummy file built by =CustomPlugin',
            #                                                 ^^^^^^^^^^^^^^
        ],
    },
};

run_me 'Special characters in file names' => {
    files => {
        q{#filename}        => 'contains hash in the first position',
        q{file name}        => 'contains space',
        q{file#name}        => 'contains hash',
        q{file'name}        => 'contains apostrophe',
        $backslash ? (
            q{file\name}    => 'contains backslash',
        ) : (
        ),
        # In single-quoted string `\n` is two characters, `\` and `n`, not a newline,
        # so real file name would be `file\name`.
        # This test may fail on Windows. TODO: Check test results, fix the test if needed.
    },
    expected => {
        manifest => [
            q{'#filename'  # 3rd party file added by GatherDir},
            q{MANIFEST     #  metainfo file built by Manifest::Write},
            q{META.yml     #  metainfo file built by MetaYAML},
            q{dist.ini     # 3rd party file added by GatherDir},
            q{'file name'  # 3rd party file added by GatherDir},
            q{'file#name'  # 3rd party file added by GatherDir},
            q{'file\'name' # 3rd party file added by GatherDir},
            $backslash ? (
                q{'file\\\\name' # 3rd party file added by GatherDir},
                #      ^^^^ In single-quoted string denotes two backslashes, so real line in
                #   manifest is expected to be `'file\\name #...`. Two backslashes is ok.
            ) : (
            ),
        ],
    },
};

{
    run_me 'strict = 1' => {
        options => {
            source_provider   => [
                'XXX',                  # Not a plugin at all.
                'MetaJSON',             # Not loaded plugin.
                'GatherDir',
            ],
            metainfo_provider => [
                'PkgVersion',           # Plugin but not injector.
                'GatherDir',
            ],
            strict            => 1,
        },
        extra_plugins => [
            'PkgVersion',               # REQUIRE: Dist::Zilla::Plugin::PkgVersion
        ],
        expected => {
            exception => $aborting,
            messages => [
                "XXX is not a plugin",
                "MetaJSON is not a plugin",
                "PkgVersion does not do FileInjector role",
                "GatherDir cannot be a source provider and a metainfo provider simultaneously",
            ],
        },
    };
    run_me 'strict = 0' => {
        options => {
            source_provider   => [
                'XXX',                  # Not a plugin at all.
                #~ 'GatherDir',
            ],
            metainfo_provider => [
                'MetaJSON',             # Not loaded plugin.
                #~ 'PkgVersion',        # Not used — it would be a fatal error.
                #~ 'GatherDir',         # Not used — it would be a fatal error too.
            ],
            strict            => 0,
        },
        extra_plugins => [
            'PkgVersion',               # REQUIRE: Dist::Zilla::Plugin::PkgVersion
        ],
        expected => {
            exception => undef,
            messages => [
                "XXX is not a plugin",
                "MetaJSON is not a plugin",
            ],
        },
    };
    run_me 'strict = -1' => {
        options => {
            source_provider   => [
                'XXX',                  # Not a plugin at all.
                'MetaJSON',             # Not loaded plugin.
            ],
            metainfo_provider => [
                'PkgVersion'            # Plugin but not injector.
            ],
            strict            => -1,
        },
        extra_plugins => [
            'PkgVersion',               # REQUIRE: Dist::Zilla::Plugin::PkgVersion
        ],
        expected => {                   # Checking is disabled:
            exception => undef,         # no exception,
            messages  => [],            # no error messages.
        },
    };
};

run_me 'show_munger = 1' => {
    options => {
        source_provider => 'GatherDir',
        show_mungers    => '1',
    },
    extra_plugins => [
        'PkgVersion',                   # REQUIRE: Dist::Zilla::Plugin::PkgVersion
    ],
    expected => {
        manifest => [
            'MANIFEST     #  metainfo file built by Manifest::Write',
            'META.yml     #  metainfo file built by MetaYAML',
            'dist.ini     #     Dummy file added by GatherDir',
            'lib/Dummy.pm #     Dummy file added by GatherDir and munged by PkgVersion',
            #                                                 ^^^^^^^^^^^^^^^^^^^^^^^^
        ],
    },
};

run_me 'Renamed plugins' => {
    name    => 'Renamed',
    plugins => [
        [ 'GatherDir' => 'G/a/t/h/e/r/D/i/r' ],     # REQUIRE: Dist::Zilla::Plugin::GatherDir
            #            ^^^^^^^^^^^^^^^^^^^ Renamed.
        [ '=CustomPlugin' => 'Custom Plugin' ],
            #                 ^^^^^^^^^^^^^ Also renamed.
        [ 'Manifest::Write' => 'Renamed' => {
            #                   ^^^^^^^ Renamed too.
            source_provider => [
                'G/a/t/h/e/r/D/i/r',            # < Name, not moniker.
                'Custom Plugin',                # < Name, not moniker.
            ],
        } ],
    ],
    expected => {
        manifest => [
            'GeneratedFile.txt      #     Dummy file built by =CustomPlugin',
            #                             ^^^^^               ^^^^^^^^^^^^^ Moniker, not name.
            #                             Recognized as source.
            'MANIFEST               #  metainfo file built by Manifest::Write',
            #                          ^^^^^^^^               ^^^^^^^^^^^^^^^ Moniker, not name.
            #                          Recognized as metainfo, even renamed.
            'dist.ini               #     Dummy file added by GatherDir',
            #                             ^^^^^               ^^^^^^^^^ Moniker, not name.
            #                             Recognized as source, even renamed.
            'lib/Dummy.pm           #     Dummy file added by GatherDir',
            # Ditto.
            'lib/GeneratedModule.pm #     Dummy file built by =CustomPlugin',
            # Ditto.
            'lib/InlineModule.pm    #     Dummy file built by =CustomPlugin',
            # Ditto.
        ],
    },
};

run_me 'exclude_files' => {
    options => {
        source_provider => 'GatherDir',
        exclude_files   => ':InstallModules',
    },
    extra_plugins => [
        'PkgVersion',                   # REQUIRE: Dist::Zilla::Plugin::PkgVersion
    ],
    expected => {
        manifest => [
            'MANIFEST #  metainfo file built by Manifest::Write',
            'META.yml #  metainfo file built by MetaYAML',
            'dist.ini #     Dummy file added by GatherDir',
            # 'lib/Dummy.pm' — Excluded by `exclude_files` option.
        ],
        files => {
            'lib/Dummy.pm' => [     # Make sure the module is built.
                'package Dummy.pm;',
                '$Dummy::VERSION = \'0.003\';',
                '1;',
            ],
        },
        archive => {
            exist => [
                'MANIFEST',
                'META.yml',
                'dist.ini',
            ],
            not_exist => [
                'lib/Dummy.pm'
            ],
        },
    },
};

run_me 'multiple exclude_files' => {
    options => {
        source_provider => 'GatherDir',
        exclude_files   => [ ':InstallModules', 'IniFiles' ],
    },
    extra_plugins => [
        'PkgVersion',                   # REQUIRE: Dist::Zilla::Plugin::PkgVersion
        [ 'FileFinder::ByName/IniFiles' => {
            file => '*.ini',
        } ],
    ],
    expected => {
        manifest => [
            'MANIFEST #  metainfo file built by Manifest::Write',
            'META.yml #  metainfo file built by MetaYAML',
            # 'dist.ini      # Excluded by `exclude_files` option.
            # 'lib/Dummy.pm' # Excluded by `exclude_files` option.
        ],
        files => {
            'lib/Dummy.pm' => [     # Make sure the module is built.
                'package Dummy.pm;',
                '$Dummy::VERSION = \'0.003\';',
                '1;',
            ],
        },
        archive => {
            exist => [
                'MANIFEST',
                'META.yml',
            ],
            not_exist => [
                'dist.ini',
                'lib/Dummy.pm',
            ],
        },
    },
};

run_me 'default manifest_skip' => {
    options => {
        source_provider => 'GatherDir',
        exclude_files   => [ ':InstallModules' ],
    },
    expected => {
        files => {
            'MANIFEST.SKIP' => re( qr{
                \A
                \# \Q This file was generated with Dist::Zilla::Plugin::Manifest::Write \E v\S* \n
                \n
                \^ lib\\/Dummy\\\.pm  \$ \n     # Excluded files are listed.
                \^ MANIFEST\\\.SKIP \$ \n       # MANIFEST.SKIP should include itself.
                \n
                \# \Q The rest is a copy of \E
            }x ),
        },
    },
};

run_me 'default manifest_skip' => {
    options => {
        source_provider => 'GatherDir',
        manifest_skip   => 'skip_it.lst',       # manifest_skip option does work.
    },
    expected => {
        files => {
            'skip_it.lst' => re( qr{
                \A
                \# \Q This file was generated with Dist::Zilla::Plugin::Manifest::Write \E v\S* \n
                \n
                \^ skip_it\\\.lst \$ \n         # MANIFEST.SKIP should include itself.
                \n
                \# \Q The rest is a copy of \E
            }sx ),
        },
    },
};

run_me 'empty manifest_skip' => {
    options => {
        source_provider => 'GatherDir',
        manifest_skip   => '',              # empty manifest_skip disables it.
    },
    expected => {
        files => {
            'MANIFEST.SKIP' => undef,
        },
    },
};

done_testing;

exit( 0 );

# end of file #
