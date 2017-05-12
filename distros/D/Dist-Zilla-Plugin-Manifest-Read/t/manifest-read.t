#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/manifest-read.t
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Manifest-Read.
#
#   perl-Dist-Zilla-Plugin-Manifest-Read is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Manifest-Read is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Manifest-Read. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use strict;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use version 0.77;
use warnings;

use POSIX qw{ locale_h };
use Test::Deep qw{ isa re cmp_deeply };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';
with 'Test::Dist::Zilla::BuiltFiles' => { -version => 'v0.3.3' };
    # ^ `Path::Tiny` bug <https://github.com/dagolden/Path-Tiny/issues/152> workarounded.

my $Plugin = 'Manifest::Read';

has manifest => (
    isa         => 'Str',
    is          => 'ro',
);

has extra_plugins => (
    isa         => 'ArrayRef',
    is          => 'ro',
    default     => sub { [] },
);

sub _build_plugins {
    my ( $self ) = @_;
    return [
        [ $Plugin => {
            manifest => $self->manifest
        } ],
        @{ $self->extra_plugins },
    ];
};

sub _build_message_filter {
    my ( $self ) = @_;
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\]]*\] }{}; $r }
            grep( $_ =~ m{^\Q[$Plugin]\E }, @_ )
        );
    };
};

test 'Found files' => sub {
    my ( $self ) = @_;
    my $expected = $self->expected;
    if ( not exists( $expected->{ finders } ) ) {
        plan skip_all => 'no expected finders specified';
    };
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    my $tzil = $self->tzil;
    my $finders = $expected->{ finders };
    for my $finder ( sort( keys( %$finders ) ) ) {
        my $plugin = $tzil->plugin_named( $finder );
        isnt( $plugin, undef, "$finder finder exists" );
        if ( $plugin ) {
            my @files = sort( map( { $_->name } @{ $plugin->find_files() } ) );
            cmp_deeply( \@files, $finders->{ $finder }, "$finder file list" )
                or $self->_anno_text( "Files found by $finder", @files );
        };
    };
};

# --------------------------------------------------------------------------------------------------

#   Some tests check error messages, which expected to be in English.
setlocale( LC_ALL, 'C' )
    or diag "*** Can't set \"C\" locale, some tests may fail! ***";

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

#
#   On MSWin32 platform `Dist::Zilla` rejects filenames containing backslashes with error:
#
#       File name 'source/filename\3' does not seem to be legal on the current OS
#
#   To avoid test failure, let's exclude such names from testing on the problem platform.
#   Cygwin has (another) problem with backslashes too. It silently converts backslashes to slashes,
#   e. g. 'file\name` becomes `file/name`, and file creation fails because directory `file/` does
#   not exists.
#
my $backslash = $^O !~ m{^(cygwin|MSWin32)$};

my %include = ( # Files to include into distribution.
    # filename             # content
    q{README}           => 'Dummy v0.003',          # Name without slashes.
    q{lib/Dummy.pm}     => 'package Dummy; 1;',     # Name with slash.
    q{filename-0}       => '0',                     # Ordinary filenames.
    q{filename-1}       => '1',
    q{filename-2}       => '2',
    q{filename-3}       => '3',
    q{filename-4}       => '4',
    q{filename-5}       => '5',
    q{filename-6}       => '6',
    q{filename-7}       => '7',
    q{filename-8}       => '8',
    q{filename-9}       => '9',
    q{filename-a}       => 'a',
    q{filename-b}       => 'b',
    q{filename-c}       => 'c',
    q{filename-d}       => 'd',
    q{filename-e}       => 'e',
    q{filename-f}       => 'f',
    q{file name 0}      => ' 0',                    # Filenames with spaces.
    q{file name 1}      => ' 1',
    q{file name 2}      => ' 2',
    q{file name 3}      => ' 3',
    q{file'name'0}      => '\'0',                   # Filenames with apostrophes.
    q{file'name'1}      => '\'1',
    q{file'name'2}      => '\'2',
    q{file'name'3}      => '\'3',
    $backslash ? (
        q{file\name\0}  => '\\0',               # Filenames with backslashes.
        q{file\name\1}  => '\\1',
        q{file\name\2}  => '\\2',
        q{file\name\3}  => '\\3',
    ) : (
    ),
);
my %exclude = ( # Source files to exclude from distribution.
    # filename             # content
    q{filename_0}       => '_0',
    q{filename 1}       => '_1',
    q{filename'2}       => '_2',
    $backslash ? (
        q{filename\3}   => '_3',
    ) : (
    ),
);

# --------------------------------------------------------------------------------------------------

plan tests => 7;

run_me 'Successful build' => {
    files => {
        'MANIFEST' => [
            'MANIFEST       -',
            'lib/Dummy.pm   #',
            'README         +',
        ],
        'lib/Dummy.pm'      => 'package Dummy; 1;',
        'README'            => 'Dummy readme',
    },
    expected => {
        files => {
            'lib/Dummy.pm'  => 'package Dummy; 1;',
            'README'        => 'Dummy readme',
            'MANIFEST'      => undef,
        },
        finders => {
            'Manifest::Read' => [
                'MANIFEST',
                'README',
                'lib/Dummy.pm',
            ],
        },
    },
};

run_me 'File finders' => {
    files => {
        'MANIFEST' => [
            'bin/script.pl  +',
            'bin/script.sh  +',
            'lib/Dummy.pm   +',
            'lib/Dummy.pod  +',
            'share/xxx      +',
            't/basic.t      +',
            'xt/author.t    +',
            'xt/release.t   +',
            'COPYING        +',
            'MANIFEST       -',
            'README         +',
            'TODO           +',
        ],
        'bin/script.pl'     => "#!/usr/bin/perl\nexit 0;\n",
        'bin/script.sh'     => "#!/bin/sh\nexit 0\n",
        'lib/Dummy.pm'      => "package Dummy; 1;",
        'lib/Dummy.pod'     => "=head1 NAME\n\nDummy\n\n=cut\n\n",
        'share/xxx'         => "Dummy share",
        't/basic.t'         => "#!perl\nexit 0;\n",
        'xt/author.t'       => "#!perl\nexit 0;\n",
        'xt/release.t'      => "#!perl\nexit 0;\n",
        'COPYING'           => "Dummy license",
        'README'            => "Dummy readme",
        'TODO'              => "Dummy todo",
    },
    extra_plugins => [
        'ExecDir',                      # REQUIRE: Dist::Zilla::Plugin::ExecDir
        'ShareDir',                     # REQUIRE: Dist::Zilla::Plugin::ShareDir
        [ 'PruneFiles' => {
            filename => 'TODO',
        } ],
        [ 'GenerateFile' => 'bin/assa.pl' => {
            filename => 'bin/assa.pl',
            content  => [ '#!perl', 'exit 0;' ],
        } ],
        [ 'GenerateFile' => 'bin/assa.sh' => {
            filename => 'bin/assa.sh',
            content  => [ '#!/bin/sh', 'exit 0' ],
        } ],
        [ 'GenerateFile' => 'lib/Assa.pm' => {
            filename => 'lib/Assa.pm',
            content  => "package Assa; 1;",
        } ],
        [ 'GenerateFile' => 'share/yyy' => {
            filename => 'share/yyy',
            content  => "???",
        } ],
        [ 'GenerateFile' => 't/compile.t' => {
            filename => 't/compile.t',
            content  => [ '#!perl', 'exit 0;' ],
        } ],
        [ 'GenerateFile' => 'xt/critic.t' => {
            filename => 'xt/critic.t',
            content  => [ '#!perl', 'exit 0;' ],
        } ],
    ],
    expected => {
        finders => {
            'Manifest::Read' => [
                'COPYING',
                'MANIFEST',
                'README',
                'TODO',                 # Pruned files are listed.
                'bin/script.pl',
                'bin/script.sh',
                'lib/Dummy.pm',
                'lib/Dummy.pod',
                'share/xxx',
                't/basic.t',
                'xt/author.t',
                'xt/release.t',
            ],
            ':InstallModules' => [
                'lib/Assa.pm',
                'lib/Dummy.pm',
                'lib/Dummy.pod',
            ],
            'Manifest::Read/:InstallModules' => [
                #~ 'lib/Assa.pm',       # Not in `MANIFEST`.
                'lib/Dummy.pm',
                'lib/Dummy.pod',
            ],
            ':TestFiles' => [
                't/basic.t',
                't/compile.t',
            ],
            'Manifest::Read/:TestFiles' => [
                't/basic.t',
                #~ 't/compile.t',       # Not in `MANIFEST`.
            ],
            version->parse( Dist::Zilla->VERSION ) >= 5.038 ? (
                # `:ExtraTestFiles` file finder introduced in `Dist::Zilla` 5.038.
                ':ExtraTestFiles' => [
                    'xt/author.t',
                    'xt/critic.t',
                    'xt/release.t',
                ],
                'Manifest::Read/:ExtraTestFiles' => [
                    'xt/author.t',
                    #~ 'xt/critic.t',   # Not in `MANIFEST`.
                    'xt/release.t',
                ],
            ) : (
            ),
            ':ExecFiles' => [
                'bin/assa.pl',
                'bin/assa.sh',
                'bin/script.pl',
                'bin/script.sh',
            ],
            'Manifest::Read/:ExecFiles' => [
                #~ 'bin/assa.pl',       # Not in `MANIFEST`.
                #~ 'bin/assa.sh',       # Not in `MANIFEST`.
                'bin/script.pl',
                'bin/script.sh',
            ],
            version->parse( Dist::Zilla->VERSION ) >= 5.038 ? (
                # `:PerlExecFiles` file finder introduced in `Dist::Zilla` 5.038.
                ':PerlExecFiles' => [
                    'bin/assa.pl',
                    'bin/script.pl',
                ],
                'Manifest::Read/:PerlExecFiles' => [
                    #~ 'bin/assa.pl',   # Not in `MANIFEST`.
                    'bin/script.pl',
                ],
            ) : (
            ),
            version->parse( Dist::Zilla->VERSION ) >= 5.007 ? (
                ':AllFiles' => [
                    'COPYING',
                    #~ 'TODO',          # Pruned.
                    'README',
                    'bin/assa.pl',      # Not in `MANIFEST`.
                    'bin/assa.sh',      # Not in `MANIFEST`.
                    'bin/script.pl',
                    'bin/script.sh',
                    'lib/Assa.pm',      # Not in `MANIFEST`.
                    'lib/Dummy.pm',
                    'lib/Dummy.pod',
                    'share/xxx',
                    'share/yyy',
                    't/basic.t',
                    't/compile.t',      # Not in `MANIFEST`.
                    'xt/author.t',
                    'xt/critic.t',      # Not in `MANIFEST`.
                    'xt/release.t',
                ],
                'Manifest::Read/:AllFiles' => [
                    'COPYING',
                    #~ 'TODO',          # Pruned.
                    'README',
                    #~ 'bin/assa.pl',   # Not in `MANIFEST`.
                    #~ 'bin/assa.sh',   # Not in `MANIFEST`.
                    'bin/script.pl',
                    'bin/script.sh',
                    #~ 'lib/Assa.pm',   # Not in `MANIFEST`.
                    'lib/Dummy.pm',
                    'lib/Dummy.pod',
                    'share/xxx',
                    #~ 'share/yyy',     # Not in `MANIFEST`.
                    't/basic.t',
                    #~ 't/compile.t',   # Not in `MANIFEST`.
                    'xt/author.t',
                    #~ 'xt/critic.t',   # Not in `MANIFEST`.
                    'xt/release.t',
                ],
            ) : (
            ),
            'Manifest::Read/:NoFiles'       => [],
            ':ShareFiles'                   => [ 'share/xxx', 'share/yyy' ],
            'Manifest::Read/:ShareFiles'    => [ 'share/xxx' ],
        },
    },
};

run_me 'Non-defaul plugin name ' => {
    files => {
        'MANIFEST' => [
            'lib/Dummy.pm   +',
            'lib/Dummy.pod  +',
            't/basic.t      +',
            'README         +',
        ],
        'lib/Dummy.pm'      => "package Dummy; 1;",
        'lib/Dummy.pod'     => "=head1 NAME\n\nDummy\n\n=cut\n\n",
        't/basic.t'         => "#!perl\nexit 0;\n",
        'README'            => "Dummy readme",
    },
    plugins => [
        [ 'Manifest::Read' => 'MR' ],
        #                      ^^ Plugin name.
        [ 'GenerateFile' => 'lib/Assa.pm' => {
            filename => 'lib/Assa.pm',
            content  => "package Assa; 1;",
        } ],
        [ 'GenerateFile' => 't/compile.t' => {
            filename => 't/compile.t',
            content  => [ '#!perl', 'exit 0;' ],
        } ],
    ],
    expected => {
        finders => {
            'MR' => [
            #^^ Plugin name, not moniker.
                'README',
                'lib/Dummy.pm',
                'lib/Dummy.pod',
                't/basic.t',
            ],
            'MR/:InstallModules' => [
            #^^ Plugin name, not moniker.
                #~ 'lib/Assa.pm',       # Not in `MANIFEST`.
                'lib/Dummy.pm',
                'lib/Dummy.pod',
            ],
            'MR/:TestFiles' => [
            #^^ Plugin name, not moniker.
                't/basic.t',
                #~ 't/compile.t',       # Not in `MANIFEST`.
            ],
            version->parse( Dist::Zilla->VERSION ) >= 5.007 ? (
                'MR/:AllFiles' => [
                #^^ Plugin name, not moniker.
                    'README',
                    #~ 'lib/Assa.pm',   # Not in `MANIFEST`.
                    'lib/Dummy.pm',
                    'lib/Dummy.pod',
                    't/basic.t',
                    #~ 't/compile.t',   # Not in `MANIFEST`.
                ],
            ) : (
            ),
        },
    },
};

run_me 'Funny file names' => {
    manifest => 'manifest.txt',
    files => {
        'manifest.txt' => [

            "# Comment line",
            "       # Comment line may have leading spaces",
            "\t# Comment line may have leading tabs",
            "# Comment line may have trailing spaces   ",
            "# Comment line may have trailing tabs\t\t\t",
            "   # Comment line may have leading and trailing spaces   ",

            "",                                 # Empty line.
            "    ",                             # Space-only line.
            " \t ",                             # Whitespace-only line.

            "README",                           # Filename without slashes.
            "lib/Dummy.pm",                     # Filename with slash.

            "filename-0",                       # Just unquoted filename.
            " \t filename-1",                   # … + leading whitespace.
            "filename-2 \t ",                   # … + trailing wwhitespace.
            " \t filename-3 \t ",               # … + leading and trailing whitespace.

            "filename-4    #",                  # … + hash marker.
            " filename-5   # \t ",
            "filename-6    #\tcomment",
            " filename-7   # comment\t",

            "\tfilename-8  +",                  # … + plus delimiter.
            "filename-9    +  ",
            "\tfilename-a  + comment",
            "filename-b    + comment  ",

            "\t'filename-c'\t",                 # Non-funny names can be quoted.
            "'filename-d'    #  ",
            "\t'filename-e'  +",
            "'filename-f'    + yep ",

            "'file name 0'",                    # Filenames with spaces require quoting.
            " 'file name 1'  #",
            "'file name 2'   + ",
            " 'file name 3'  + ",

            "file'name'0",                      # Filenames with apostrophes may be unquoted
            "'file\\'name\\'1'   #",            # or quoted (with escaping the quote marks).
            "\tfile'name'2       + ",
            "\t'file\\'name\\'3' + cmnt",

            $backslash ? (
                "file\\name\\0",                # Filenames with backslashes may be unquoted
                "\t'file\\\\name\\\\1' #",      # or quoted (with
                "'file\\name\\2'       + ",     # or without escaping).
                "\tfile\\name\\3       + ",
            ) : (
            ),

            "filename_0     -",                 # These files should not appear in distro.
            " 'filename 1'  -\t",
            " filename'2    - comment",
            $backslash ? (
                "'filename\\3'  -\tcomment  ",
            ) : (
            ),

            "lib/           / This is a directory.",

        ],
        %include,
        %exclude,
    },
    expected => {
        files => {
            %include,
            map( { $_ => undef } keys( %exclude ) ),
                # ^ `undef` means these files should not be in distro.
        },
        finders => {
            'Manifest::Read' => [
                sort( keys( %include ), keys( %exclude ) ),
            ],
        },
    },
};

run_me 'Syntax error' => {
    manifest => 'Manifest.lst',
    files => {
        'Manifest.lst' => [
            'lib/Assa.pm',
            q{'File'name +},        # Invalid filename.
            q{'File'name' -},       # Invalid filename.
            q{Filename ?},          # `?` is a bad marker
            q{lib/Assa.pm},         # File already listed.
            q{'lib/Assa.pm'},       # File already listed — quoting does not matter.
        ],
    },
    expected => {
        exception => $aborting,
        messages => [
            'Syntax error at Manifest.lst line 2.',
            'Syntax error at Manifest.lst line 3.',
            'Syntax error at Manifest.lst line 4.',
            'lib/Assa.pm at Manifest.lst line 5',
            '    also listed at Manifest.lst line 1.',
            'lib/Assa.pm at Manifest.lst line 6',
            '    also listed at Manifest.lst line 1.',
            'Manifest.lst:',
            '    1: lib/Assa.pm',
            '       ^^^ The file also listed at line 5. ^^^',
            '       ^^^ The file also listed at line 6. ^^^',
            '    2: \'File\'name +',
            '       ^^^ Syntax error at Manifest.lst line 2. ^^^',
            '    3: \'File\'name\' -',
            '       ^^^ Syntax error at Manifest.lst line 3. ^^^',
            '    4: Filename ?',
            '       ^^^ Syntax error at Manifest.lst line 4. ^^^',
            '    5: lib/Assa.pm',
            '       ^^^ The file also listed at line 1. ^^^',
            '    6: \'lib/Assa.pm\'',
            '       ^^^ The file also listed at line 1. ^^^',
        ],
    },
};

run_me 'Bad files' => {
    files => {
        'MANIFEST' => [
            'file1',        # Nonexistent files with various markers.
            'file2 #',
            'file3 +',
            'file4 -',
            '..',           # A directory must be used with marker `/`.
            'README /',     # This marker should be used only with directories.
        ],
        'README' => 'Read me...',
    },
    expected => {
        exception => $aborting,
        messages => [
            'file1 does not exist at MANIFEST line 1.',
            'file2 does not exist at MANIFEST line 2.',
            'file3 does not exist at MANIFEST line 3.',
            'file4 does not exist at MANIFEST line 4.',
            '.. is not a plain file at MANIFEST line 5.',
            'README is not a directory at MANIFEST line 6.',
            'MANIFEST:',
            '    1: file1',
            '       ^^^ file1 does not exist at MANIFEST line 1. ^^^',
            '    2: file2 #',
            '       ^^^ file2 does not exist at MANIFEST line 2. ^^^',
            '    3: file3 +',
            '       ^^^ file3 does not exist at MANIFEST line 3. ^^^',
            '    4: file4 -',
            '       ^^^ file4 does not exist at MANIFEST line 4. ^^^',
            '    5: ..',
            '       ^^^ .. is not a plain file at MANIFEST line 5. ^^^',
            '    6: README /',
            '       ^^^ README is not a directory at MANIFEST line 6. ^^^',
        ],
    },
};

run_me 'No manifest' => {
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^.*?\bMANIFEST\b.*?: No such file or directory} ),
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
