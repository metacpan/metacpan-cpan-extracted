#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/templates.t
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Templates.
#
#   perl-Dist-Zilla-Plugin-Templates is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Templates is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Templates. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use lib 't/lib';
use strict;
use version 0.77;
use warnings;
use utf8;

use POSIX qw{ locale_h };
use Test::Deep qw{ re isa };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'TemplatesTester';

## REQUIRE: Dist::Zilla::Role::TextTemplater v0.8.0
    # ^ Error messages changed in v0.8.0. With earlier version the test fails.

#   Some tests check error messages, which expected to be in English.
setlocale( LC_ALL, 'C' )
    or diag "*** Can't set \"C\" locale, some tests may fail! ***";

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    ## REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0
my $E = qr{^\s*\^\^\^ };

# --------------------------------------------------------------------------------------------------

{
    package MY;
    our $name    = "Assa";
    our $package = "Assa";
    our $version = "0.007";
}

my $files = {
    'README' => [
            '{{$MY::name}} is an example of...',
    ],
    'lib/Assa.pm' => [
        'package {{$MY::package}};',
        '# ABSTRACT: Yoohoo',
        '1;',
    ],
    'lib/Assa/Manual.pod' => [
        '=head1 NAME',
        '',
        '{{$name}} - Err... Aahh...',       # Note: `$name`, not `$MY::name`.
        '/* $version */',
        '',
        '=cut',
    ],
    't/assa.t' => '# This is a part of {{$MY::name}}',
};

run_me 'InstallModules' => {
    files => $files,
    options => {
        templates => ':InstallModules',
    },
    expected => {
        messages => [
        ],
        files => {
            'README' => [
                '{{$MY::name}} is an example of...',
                #^^^^^^^^^^^^^ Not replaced because not an install module.
            ],
            'lib/Assa.pm' => [
                'package Assa;',
                #        ^^^^ Replaced.
                '# ABSTRACT: Yoohoo',
                '1;',
            ],
            'lib/Assa/Manual.pod' => [
                '=head1 NAME',
                '',
                ' - Err... Aahh...',
                #^^^ Replaced with empty string: there is no variable `$name`.
                '/* $version */',
                '',
                '=cut',
            ],
            't/assa.t' => '# This is a part of {{$MY::name}}',
                #                              ^^^^^^^^^^^^^ Not replaced — not an install module.
        },
    },
};

{
    local $MY::name = $MY::name;
    run_me 'AllFiles' => {
        files => $files,
        options => {
            'package' => 'MY',
            'prepend' => '$MY::name = "hohoho";',   # Note: We change the variable value
            'templates' => [
                ':AllFiles',            ## REQUIRE: Dist::Zilla 5.000
            ],
        },
        expected => {
            messages => [
            ],
            files => {
                'README' => [
                    'hohoho is an example of...',
                    #^^^^^^ Replaced, not `Assa` because of `prepend` effect.
                ],
                'lib/Assa.pm' => [
                    'package Assa;',
                    #        ^^^^ Replaced.
                    '# ABSTRACT: Yoohoo',
                    '1;',
                ],
                'lib/Assa/Manual.pod' => [
                    '=head1 NAME',
                    '',
                    'hohoho - Err... Aahh...',
                    #^^^^^^ Replaced because of `MY` package context (and `prepend` effect).
                    '/* $version */',
                    '',
                    '=cut',
                ],
            },
        },
    };
}

run_me 'Non-standard delimiters' => {
    files => $files,
    options => {
        'delimiters' => '/* */',
        'package'    => 'MY',
        'templates' => [
            ':AllFiles',                ## REQUIRE: Dist::Zilla 5.000
        ],
    },
    expected => {
        messages => [
        ],
        files => {
            'README' => [
                '{{$MY::name}} is an example of...',
                #^^^^^^^^^^^^^ Not replaced.
            ],
            'lib/Assa.pm' => [
                'package {{$MY::package}};',
                #        ^^^^^^^^^^^^^^^^ Not replaced.
                '# ABSTRACT: Yoohoo',
                '1;',
            ],
            'lib/Assa/Manual.pod' => [
                '=head1 NAME',
                '',
                '{{$name}} - Err... Aahh...',
                #^^^^^^^^^ Not replaced.
                '0.007',
                #^^^^^ Replaced.
                '',
                '=cut',
            ],
        },
    }
};

run_me 'Multiple finders' => {
    files => $files,
    options => {
        'templates' => [
            ':InstallModules',      # Multiple file finders work.
            ':TestFiles',
        ],
    },
    expected => {
        files => {
            'lib/Assa.pm'   => [
                'package Assa;',
                #        ^^^^ Replaced because an install module.
                '# ABSTRACT: Yoohoo',
                '1;',
            ],
            't/assa.t'      => '# This is a part of Assa',
            #                                       ^^^^ Replaced because test file.
        },
    },
};

run_me 'Include + fill_in' => {
    files => {
        'lib/Assa.pm' => 'A {{ include( "include.txt" ); }} B',
        'lib/Foo.pm'  => 'A {{ include( "include.txt" )->fill_in; }} B',
        'lib/Bar.pm'  => 'A {{ include( "include.txt" )->fill_in->indent; }} B',
        #                                              ^^       ^^ Chaining.
        'include.txt' => 'As{{ 2 + 2 }}sa',
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => 'A As{{ 2 + 2 }}sa B',
            #                     ^^^^^^^^^^^ `include` does not expand templates.
            'lib/Foo.pm'  => 'A As4sa B',
            #                    ^^^ but `include()->fill_in` does.
            'lib/Bar.pm'  => 'A     As4sa B',
        },
    },
};

run_me 'fill_in args' => {
    files => {
        'lib/Assa.pm' => '{{ include( "include.txt" )->fill_in( { A => "X", B => "Y" } ); }}',
        'include.txt' => '{{$A}}-{{$B}}',
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => 'X-Y',
        },
    },
};

run_me 'Indent + trim' => {
    files => {
        'lib/Assa.pm' => '{{ include( "indent.txt" )->indent; }}',
        #                                                  ^^^ Default indent size.
        'lib/Foo.pm'  => '{{ include( "indent.txt" )->indent( 2 ); }}',
        #                                                    ^^^ Custom indent size.
        'indent.txt' => [
            'line 1',
            '',                         # Empty line should not be indented.
            'line 3',
        ],
        'lib/Bar.pm' => '{{ include( "trim.txt" )->trim; }}',
        'trim.txt'   => [
            "  line 1  ",
            "line2",
            "\tline3\t",
            " \t ",
            "\t\t\t",
            "",
            "",
        ],
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => [
                '    line 1',           # Default indent size is 4 spaces.
                '',                     # Empty line is not indented.
                '    line 3',
            ],
            'lib/Foo.pm' => [
                '  line 1',             # Custom indent size.
                '',                     # Empty line is not indented.
                '  line 3',
            ],
            'lib/Bar.pm' => [
                "  line 1",             # Trailing spaces trimmed.
                "line2",
                "\tline3",              # Trailing tab trimmed.
                "",                     # All whitespace trimmed.
                "",                     # Ditto.
                "",                     # Empty line left intact.
                "",
            ],
        },
    },
};

run_me 'Chomp' => {
    files => {
        'lib/Assa.pm' => '{{ include( "include.txt" )->chomp; }}',
        'lib/Foo.pm'  => '{{ include( "include.txt" )->chomp( 2 ); }}',
        #                                                    ^^^ Custom chomp count.
        'include.txt' => "line1\n \n\n\n",
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => "line1\n ",    # Should chomp all the trailing newlines.
            'lib/Foo.pm'  => "line1\n \n",  # Should chomp only two trailing newlines.
        },
    },
};

run_me 'Munge' => {
    files => {
        'lib/Assa.pm' =>
            '{{  include( "include.txt" )->munge( sub { $_ =~ s{l}{L}g; return 1; } ); }}',
            #                                  Return value is ignored. ^^^^^^^^
        'include.txt' => "line1\nline2\nline3\n\n",
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => "Line1\nLine2\nLine3\n\n",
        },
    },
};

run_me 'Pod2text' => {
    files => {
        'lib/Assa.pm' => '{{ include( "include.pod" )->pod2text->chomp; }}',
        #   On some machines `pod2text` returns 5 lines, on some — 6 lines (including the last
        #   empty line). Let us chomp it to avoid accidental test failure.
        'include.pod' => [
            '=head1 DESCRIPTION',
            '',
            'Text C<code> B<bold> I<italics>.',
            '',
            '    Verbatim text.',
            '    No C<code> B<bold> I<italics>.',
            '',
            '=cut',
        ],
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        files => {
            'lib/Assa.pm' => [
                'DESCRIPTION',
                '    Text "code" bold *italics*.',
                '',
                '        Verbatim text.',
                '        No C<code> B<bold> I<italics>.',
            ],
        },
    },
};

run_me 'Include error reporting' => {
    files => {
        'lib/Assa.pm' => [
            '{{',
            '    include( "include.pod" )->pod2text;',
            '}}{{',
            '    include();',
            '}}{{',
            '    include( $dist );',
            '}}',
        ],
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^Error open .* on 'include.pod': No such file or directory at } ),
            # TODO: This error message is still not very good.
            '    Bad code fragment begins at lib/Assa.pm line 1.',
            'Can\'t include undefined file at lib/Assa.pm line 4.',
            '    Bad code fragment begins at lib/Assa.pm line 3.',
            re( qr{^Can't include object of .* class at lib/Assa\.pm line 6\.} ),
            '    Bad code fragment begins at lib/Assa.pm line 5.',
            'lib/Assa.pm:',
            '    1: {{',
            '       ^^^ Bad code fragment begins at lib/Assa.pm line 1. ^^^',
            '    2:     include( "include.pod" )->pod2text;',
            '    3: }}{{',
            '       ^^^ Bad code fragment begins at lib/Assa.pm line 3. ^^^',
            '    4:     include();',
            '       ^^^ Can\'t include undefined file at lib/Assa.pm line 4. ^^^',
            '    5: }}{{',
            '       ^^^ Bad code fragment begins at lib/Assa.pm line 5. ^^^',
            '    6:     include( $dist );',
            re( qr{${E}Can't include object of .* class at lib/Assa\.pm line 6\.} ),
            '    7: }}',
        ],
    },
};

run_me 'Pod2text error reporting' => {
    files => {
        'lib/Assa.pm' => '{{ include( "include.pod" )->pod2text; }}',
        'include.pod' => [
            '=h ead1 DESCRIPTION',
            #^^ Bad directive.
            '',
            'Text A<code> B<bold> I<italics>.',
            #     ^^^^^^^ Badformatting code.
            '',
            '=cut',
        ],
    },
    options => { 'templates' => ':InstallModules' },
    expected => {
        exception => $aborting,
        messages => [
            'Unknown directive: =h at include.pod line 1.',
            'Deleting unknown formatting code A<> at include.pod line 3.',
            'POD errata found at include.pod.',
            '    Bad code fragment begins at lib/Assa.pm line 1.',
            'lib/Assa.pm:',
            '    1: {{ include( "include.pod" )->pod2text; }}',
            '       ^^^ Bad code fragment begins at lib/Assa.pm line 1. ^^^',
        ],
    },
};

run_me 'Expanded once' => {
    files => {
        'lib/Assa.pm' => 'A {{ "{{ 2 + 2 }}" }} B',
        # ^ The file falls to both categories: ":InstallModules" and ":AllFiles".
    },
    options => {
        templates => [
            ':InstallModules',
            ':AllFiles',                ## REQUIRE: Dist::Zilla 5.000
        ],
    },
    expected => {
        files => {
            'lib/Assa.pm' => 'A {{ 2 + 2 }} B',
            #                   ^^^^^^^^^^^ Expanded only once.
        },
    },
};

{
    #   `include` works in nested templates. Nested templates are evaluated in the same package.
    local @MY::Packages;
    run_me 'Recursive include' => {
        files => {
            'lib/Assa.pm' => 'A {{ push( @MY::Packages, __PACKAGE__ ); include( "outer.txt" )->fill_in; }} B',
            'outer.txt'   => 'Y {{ push( @MY::Packages, __PACKAGE__ ); include( "inner.txt" )->fill_in; }} Z',
            'inner.txt'   => 'P {{ push( @MY::Packages, __PACKAGE__ ); 2 + 2 }} Q',
        },
        options => { 'templates' => ':InstallModules' },
        expected => {
            files => {
                'lib/Assa.pm' => 'A Y P 4 Q Z B',
            },
        },
    };
    is( @MY::Packages + 0, 3 );
    is( $MY::Packages[ 0 ], $MY::Packages[ 1 ], 'package 1' );
    is( $MY::Packages[ 0 ], $MY::Packages[ 2 ], 'package 2' );
}

#   Generated files are first-class citizens: they can be templates and can be included.
run_me 'Generated files' => {
    files => {
        'README' => '{{ include( \'include.txt\' ) }}',
        #                          ^^^^^^^^^^^ Including a generated file.
    },
    plugins => [
        'GatherDir',
        [ 'GenerateFile', 'lib/Assa.pm' => {    # Main module is a generated file.
            filename => 'lib/Assa.pm',          # It is a template.
            content  => $files->{ 'lib/Assa.pm' },
        } ],
        [ 'GenerateFile', 'include.txt' => {    # This generated file will be included.
            filename => 'include.txt',
            content  => 'include body',
        } ],
        [ 'Templates' => {
            templates => ':AllFiles',   ## REQUIRE: Dist::Zilla 5.000
        } ],
    ],
    expected => {
        files => {
            'README' => [
                'include body'
                #^^^^^^^^^^^^ Perl code fragment evaluated.
            ],
            'lib/Assa.pm' => [
                'package Assa;',
                #        ^^^^ Perl code fragment evaluated.
                '# ABSTRACT: Yoohoo',
                '1;',
            ],
        },
    },
};

run_me 'Including a Dist::Zilla::File object' => {
    files => {
        'include.txt' => 'file content',
        'README' =>
            '{{ include( ' .
                'Dist::Zilla::File::OnDisk->new( { ' .  ## REQUIRE: Dist::Zilla::File::OnDisk
                #^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Including a file object.
                    'name => \'include.txt\' ' .
                '} ) ' .
            ') }}',

    },
    options => {
        templates => ':AllFiles',       ## REQUIRE: Dist::Zilla 5.000
    },
    expected => {
        files => {
            'README' => [
                'file content'
                #^^^^^^^^^^^^ File included.
            ],
        },
    },
};


run_me 'Unicode characters' => {
    files => {
        'a' => "©",
        'b' => "{{ include( 'a' ); }}",
        'c' => [
            '=encoding UTF-8',
            '',
            '©',
            '',
            '=cut'
        ],
        'lib/A.pm' => "{{ include( 'a' ); }}",
        'lib/B.pm' => "{{ include( 'b' ); }}",
        'lib/C.pm' => "{{ include( 'b' )->fill_in; }}",
        'lib/D.pm' => "{{ include( 'c' ); }}",
    },
    options => {
        templates => ':InstallModules',
    },
    expected => {
        files => {
            'a' => "©",
            'b' => "{{ include( 'a' ); }}",
            'lib/A.pm' => "©",
            'lib/B.pm' => "{{ include( 'a' ); }}",
            'lib/C.pm' => "©",
            'lib/D.pm' => [
                '=encoding UTF-8',
                '',
                '©',
                '',
                '=cut'
            ],
        },
    },
};

{
    require Pod::Simple;
    my $ver = version->parse( $Pod::Simple::VERSION );
    my ( $bad, $good ) = qw{ 3.20 3.28 };
    # Simple `local $TODO = "reason";` does not work.
    local $Test::Dist::Zilla::BuiltFiles::TODO;
    if ( $ver <= $bad ) {
        $Test::Dist::Zilla::BuiltFiles::TODO = "Known failure if Pod::Simple <= $bad";
    } elsif ( $ver < $good ) {
        diag( "Pod::Simple $ver" );
        diag( "Test may fail if Pod::Simple > $bad, < $good" );
    };
    run_me 'Unicode characters, pod2text' => {
        files => {
            'c' => [
                '=encoding UTF-8',
                '',
                '©',
                '',
                '=cut'
            ],
            'lib/E.pm' => "{{ include( 'c' )->pod2text; }}",
        },
        options => {
            templates => ':InstallModules',
        },
        expected => {
            files => {
                'lib/E.pm' => re( qr{\A *©\n+} ),
            },
        },
    };
}

done_testing;

exit( 0 );

# end of file #
