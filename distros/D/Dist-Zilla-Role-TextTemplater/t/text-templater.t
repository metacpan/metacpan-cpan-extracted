#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/text-templater.t
#
#   Copyright © 2015, 2016, 2018 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Role-TextTemplater.
#
#   perl-Dist-Zilla-Role-TextTemplater is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Role-TextTemplater is distributed in the hope that it will be useful, but
#   WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#   PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Role-TextTemplater. If not, see <http://www.gnu.org/licenses/>.
#
#   SPDX-License-Identifier: GPL-3.0-or-later
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use lib 't/lib';        # Make TextTemplaterTestPlugin accessible.
use strict;
use version 0.77;
use warnings;

use Dist::Zilla::File::FromCode ();
use Dist::Zilla::File::InMemory ();
use Dist::Zilla                 ();     # Will check the version.
use Path::Class                 ();
use Path::Tiny                  ();
use Test::Deep qw{ re isa };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'TextTemplaterTester';

# --------------------------------------------------------------------------------------------------

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    ## REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0
my $E        = qr{^\s*\^\^\^ };

run_me 'Nothing to substitute' => {
    text     => [ 'assa' ],         #   Nothing to expand.
    expected => {
        text => [ 'assa' ],         #   Output is the same as output
        messages => [],
    },
};

run_me 'Simple substitution' => {
    text     => [ '2 + 2 = {{ 2 + 2 }}' ],
    #                      ^^^^^^^^^^^
    expected => {
        text => [ '2 + 2 = 4'           ],
        #                 ^^^
        messages => [],
    },
};

#   Variable `$dist` can be used.
run_me 'Var $dist' => {
    text     => [ 'name = {{ $dist->name }}' ],
    #                        ^^^^^^^^^^^
    expected => {
        text => [ 'name = Dummy'             ],
        #                 ^^^^^
        messages => [],
    },
};

#   Variable `$plugin` can be used.
run_me 'Var $plugin' => {
    text     => [ 'generated with {{ $plugin->plugin_name }}' ],
    #                                ^^^^^^^^^^^^^^^^^^^^
    expected => {
        text => [ 'generated with =TextTemplaterTestPlugin'   ],
        #                         ^^^^^^^^^^^^^^^^^^^^^^^^
        messages => [],
    },
};

{
    local $MY::assa;            # Avoid warning "Name "MY::assa" used only once".
    $MY::assa = 'qwerty';
    #^^^^^^^^^^^^^^^^^^^
    #   Global variable can be used.
    run_me 'Global var full name' => {
        text     => [ '{{ $MY::assa }}' ],
        #                 ^^^^^^^^^
        expected => {
            text => [ 'qwerty'          ],
            #          ^^^^^^
            messages => [],
        },
    };
    #   Global variable can be used with short name if `package` specified.
    run_me 'Global var short name + package' => {
        package  => 'MY',
        #            ^^
        text     => [ '{{ $assa }}' ],
        #                 ^^^^^ not $MY::assa
        expected => {
            text => [ 'qwerty'      ],
            #          ^^^^^^
            messages => [],
        },
    };
}

#   `package` does not break `$plugin` and `$dist` variables.
run_me '$dist + $plugin + package' => {
    package  => 'MY',
    text     => [
        '# Generated with {{ $plugin->plugin_name }}',
        '{{ $dist->name . " " . $dist->version }}',
    ],
    expected => {
        text => [
            '# Generated with =TextTemplaterTestPlugin',
            'Dummy 0.003'
        ],
        messages => [],
    },
};

#   `prepend` works.
run_me 'Prepend' => {
    prepend  => [ 'my $yep = "nope";' ],                # Define a variable in the fragment.
    text     => [ '{{ $yep = "yep"; }}/{{ $yep }}' ],   # Note: Variable is reset to its original
    expected => {
        text => [ 'yep/nope'                       ],   # value in the beginning of each fragment.
        messages => [],
    },
};

#   Syntax error in template: no closing delimiter.
run_me 'Unmatched opening delimiter' => {
    text          => [
        '1    line',
        '2 {{ line',
        #  ^^
        '3    line',
    ],
    expected => {
        exception => $aborting,
        messages  => [
            'Unmatched opening delimiter at template line 2.',
            'template:',
            '    1: 1    line',
            '    2: 2 {{ line',
            re( qr{$E\QUnmatched opening delimiter at template line 2.\E} ),
            '    3: 3    line',
        ]
    },
};

#   Syntax error in template: no open delimiter.
run_me 'Unmatched closing delimiter' => {
    text => [
        '1    line',
        '2    line',
        '3 }} line'
        #  ^^
    ],
    expected => {
        exception => $aborting,
        messages  => [
            'Unmatched closing delimiter at template line 3.',
            'template:',
            '    1: 1    line',
            '    2: 2    line',
            '    3: 3 }} line',
            re( qr{$E\QUnmatched closing delimiter at template line 3.\E} ),
        ],
    },
};

#   Code fragment dies. Line numbers are reported correctly.
run_me 'Die' => {
    text => [
        # `Dist::Zilla` configuration parser strips leading and trailing spaces!
        '1        template line 1',
        '2        template line 2',
        '{{     # template line 3, code line 1',
        'die;   # template line 4, code line 2',
        '2 + 3; # template line 5, code line 3 }}',
        '6        template line 6'
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Died at template line 4\b} ),
            '    Bad code fragment begins at template line 3.',
            'template:',
            '    1: 1        template line 1',
            '    2: 2        template line 2',
            '    3: {{     # template line 3, code line 1',
            re( qr{$E\QBad code fragment begins at template line 3.\E} ),
            '    4: die;   # template line 4, code line 2',
            re( qr{$E\QDied at template line 4\E\b} ),
            '    5: 2 + 3; # template line 5, code line 3 }}',
            '    6: 6        template line 6',
        ],
    },
};

#   Code fragment dies in long template. Error message must include beginning of the template
#   and line where die occurs, as well as two lines above and below. Other lines should be
#   skipped to keep error message reasonable small.
run_me 'Long template' => {
    text => [
        '1         template line  1',
        '2         template line  2',
        '3         template line  3',
        '4         template line  4',
        '5         template line  5',
        '{{      # template line  6, code line  1',
        '$OUT .= # template line  7, code line  2',
        '8 .     # template line  8, code line  3',
        '9 .     # template line  9, code line  4',
        '10 .    # template line 10, code line  5',
        '11 .    # template line 11, code line  6',
        '12 .    # template line 12, code line  7',
        '13;     # template line 13, code line  8',
        'die;    # template line 14, code line  9',
        '$OUT .= # template line 15, code line 10',
        '16 .    # template line 16, code line 11',
        '17 .    # template line 17, code line 12',
        '18 .    # template line 18, code line 13',
        '19;     # template line 19, code line 14 }}',
        '20        template line 20'
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Died at template line 14\b} ),
            '    Bad code fragment begins at template line 6.',
            'template:',
            '        ... skipped 3 lines ...',
            '    04: 4         template line  4',
            '    05: 5         template line  5',
            '    06: {{      # template line  6, code line  1',
            re( qr{$E\QBad code fragment begins at template line 6.\E} ),
            '    07: $OUT .= # template line  7, code line  2',
            '    08: 8 .     # template line  8, code line  3',
            '        ... skipped 3 lines ...',
            '    12: 12 .    # template line 12, code line  7',
            '    13: 13;     # template line 13, code line  8',
            '    14: die;    # template line 14, code line  9',
            re( qr{$E\QDied at template line 14\E\b} ),
            '    15: $OUT .= # template line 15, code line 10',
            '    16: 16 .    # template line 16, code line 11',
            '        ... skipped 4 lines ...',
        ],
    },
};

#   The same as above, but single line should be never skipped: message "... skipped 1 line ..."
#   anyway occupies one line, so it is better to show template line rather than "skip" message.
#   This template shortened so skips should not occur.
run_me 'Not so long template' => {
    text => [
        '1         template line  1',                    # Should not be skipped.
        '2         template line  2',
        '3         template line  3',
        '{{      # template line  4, code line  1',
        '$OUT .= # template line  5, code line  2',
        '6 .     # template line  6, code line  3',
        '7 .     # template line  7, code line  4',      # Should not be skipped.
        '8 .     # template line  8, code line  5',
        '9;      # template line  9, code line  6',
        'die;    # template line 10, code line  7',
        '$OUT .= # template line 11, code line  8',
        '12;     # template line 12, code line  9 }}',
        '13        template line 13'                     # Should not be skipped.
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Died at template line 10\b} ),
            '    Bad code fragment begins at template line 4.',
            'template:',
            '    01: 1         template line  1',
            '    02: 2         template line  2',
            '    03: 3         template line  3',
            '    04: {{      # template line  4, code line  1',
            re( qr{$E\QBad code fragment begins at template line 4.\E} ),
            '    05: $OUT .= # template line  5, code line  2',
            '    06: 6 .     # template line  6, code line  3',
            '    07: 7 .     # template line  7, code line  4',
            '    08: 8 .     # template line  8, code line  5',
            '    09: 9;      # template line  9, code line  6',
            '    10: die;    # template line 10, code line  7',
            re( qr{$E\QDied at template line 10\E\b} ),
            '    11: $OUT .= # template line 11, code line  8',
            '    12: 12;     # template line 12, code line  9 }}',
            '    13: 13        template line 13',
        ],
    },
};

{
    package MY;
    sub oops {
        die;
    };
}

#   Program fragment dies, but `die` is buried in the calling code.
run_me 'Deep die' => {
    text => [ '{{ MY::oops(); }}' ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Died at t/text-templater\.t line \d+\b} ),
            '    Bad code fragment begins at template line 1.',
            'template:',
            '    1: {{ MY::oops(); }}',
            '       ^^^ Bad code fragment begins at template line 1. ^^^',
        ],
    },
};

#   Call undefined subroutine. It is a fatal error.
run_me 'Undefined subroutine' => {
    text => [ '{{ MY::undefined(); }}' ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Undefined subroutine &MY::undefined called at template line 1\b} ),
            '    Bad code fragment begins at template line 1.',
            'template:',
            '    1: {{ MY::undefined(); }}',
            re( qr{$E\QUndefined subroutine &MY::undefined called at template line 1\E\b} ),
        ],
    },
};

#   Use undefined variable. It causes warning, wich should appear in the log, but build should
#   complete successfuly.
run_me 'Prepend + warnings' => {
    prepend  => [ 'use warnings;' ],
    text     => [ '{{ $MY::assa + 2 }}' ],
    expected => {
        text => [ '2' ],
        messages  => [
            re( qr{^Use of uninitialized value.* at template line 1\b} ),
            #   Regular expression should not be very specific! Error message varies depending on
            #   Perl version.
        ],
    },
};

run_me 'Custom variables' => {
    hook => sub {
        my ( $self, $string ) = @_;
        $self->fill_in_string( $string, { assa => 'Yahoo' } );
    },
    text         => [ '{{ $assa }}' ],
    expected => {
        messages => [],
        text     => [ 'Yahoo' ],
    },
};

#   Two fragments die. Execution does not stop on the first.
run_me 'Double die' => {
    text => [
        '1 {{ die; }}',
        '2 {{ die; }}',
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^Died at template line 1\b} ),
            '    Bad code fragment begins at template line 1.',
            re( qr{^Died at template line 2\b} ),
            '    Bad code fragment begins at template line 2.',
            'template:',
            '    1: 1 {{ die; }}',
            re( qr{$E\QDied at template line 1\E\b} ),
            '    2: 2 {{ die; }}',
            re( qr{$E\QDied at template line 2\E\b} ),
        ],
    },
};

run_me 'Tt_broken_limit' => {
    hook => sub {
        my ( $self, $string ) = @_;
        local $self->{ tt_broken_limit } = 3;
        $self->fill_in_string( $string );
    },
    text => [
        '{{ die }}',
        '{{ die }}',
        '{{ die }}',
        '{{ die }}',
        '{{ die }}',
    ],
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^Died at template line 1\b} ),
            '    Bad code fragment begins at template line 1.',
            re( qr{^Died at template line 2\b} ),
            '    Bad code fragment begins at template line 2.',
            re( qr{^Died at template line 3\b} ),
            '    Bad code fragment begins at template line 3.',
            'Too many errors in template, only first 3 are reported.',
            'template:',
            '    1: {{ die }}',
            re( qr{$E\QDied at template line 1\E\b} ),
            '    2: {{ die }}',
            re( qr{$E\QDied at template line 2\E\b} ),
            '    3: {{ die }}',
            re( qr{$E\QDied at template line 3\E\b} ),
            '    4: {{ die }}',
            '    5: {{ die }}',
        ],
    },
};

#   Explicitly specified $plugin and $dist overrides default definition.
run_me 'Explicit $plugin and $dist' => {
    hook => sub {
        my ( $self, $string ) = @_;
        $self->fill_in_string( $string, { plugin => 'Mooo', dist => 'Yep' } );
        #                                 ^^^^^^            ^^^^
    },
    text => [ '{{ $plugin . " " . $dist }}' ],
    expected => {
        text     => [ 'Mooo Yep' ],
        messages => [],
    },
};

{
    local ( $MY::assa, $ME::assa );
    $MY::assa = 'qwerty';
    $ME::assa = 'ytrewq';
    #   Explicitly specified lowercase option overrides the attribute.
    run_me 'Explicit package' => {
        hook => sub {
            my ( $self, $string ) = @_;
            $self->fill_in_string( $string, undef, { package => 'ME' } );
        },
        text         => [ '{{ $assa }}' ],
        package      => 'MY',
        expected => {
            text     => [ 'ytrewq' ],
            messages => [],
        },
    };
    #   Explicitly specified uppercase option does not override the attribute.
    run_me 'Explicit PACKAGE' => {
        hook => sub {
            my ( $self, $string ) = @_;
            $self->fill_in_string( $string, undef, { PACKAGE => 'ME' } );
        },
        text         => [ '{{ $assa }}' ],
        package      => 'MY',
        expected => {
            text     => [ 'qwerty' ],
            messages => [],
        },
    };
}

run_me 'Non-standard delimiters' => {
    delimiters    => '(* *)',
    text          => [ '(* 3 * 3 *)' ],
    expected => {
        text      => [ '9' ],
        messages  => [],
    },
};

run_me 'Bad delimiters' => {
    delimiters    => '(**)',
    text          => [ '(* 3 * 3 *)' ],
    expected => {
        exception => re( qr{^"delimiters" value must be Str of \*two\* whitespace-separated words} ),
        messages  => [],
    },
};

#   If `package` is explicitly specified, nested `fill_in_string` use the same explicitly
#   specified package.
run_me 'Explict nested packages' => {
    package => 'ASSA',
    text => [
        q{ {{ $plugin->log( [ "outer %s", __PACKAGE__ ] ); }} },
        q{ {{ $plugin->fill_in_string( '{{ $plugin->log( [ "inner %s", __PACKAGE__ ] ); }}' ); }} },
    ],
    expected => {
        messages => [
            'outer ASSA',
            'inner ASSA',
        ],
    },
};

{
    #   If `package` is not explicitly specified, outer `fill_in_string` should use some private
    #   package. Nested `fill_in_string` should use the same private package.
    local @MY::Packages;
    run_me 'Implicit nested packages, part 1' => {
        text => [
            q{ {{ push( @MY::Packages, __PACKAGE__ ); }} },
            q{ {{ $plugin->fill_in_string( '{{ push( @MY::Packages, __PACKAGE__ ); }}' ); }} },
        ],
        expected => {
        },
    };
    run_me 'Implicit nested packages, part 2' => {
        text => [
            q{ {{ push( @MY::Packages, __PACKAGE__ ); }} },
        ],
        expected => {
        },
    };
    is( @MY::Packages + 0, 3 );
    is( $MY::Packages[ 0 ], $MY::Packages[ 1 ], 'inner fill_in_string reuses outer package' );
    isnt( $MY::Packages[ 0 ], $MY::Packages[ 2 ], 'but another fill_in_string uses another package' );
}

run_me 'Filename extra argument' => {
    hook => sub {
        my ( $self, $string ) = @_;
        $self->fill_in_string( $string, undef, { filename => 'Assa.txt' } );
        #                                        ^^^^^^^^^^^^^^^^^^^^^^
    },
    text => [
        '{{ die; }}',
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^\QDied at Assa.txt line 1\E\b} ),
            #               ^^^^^^^^
            '    Bad code fragment begins at Assa.txt line 1.',
            #                                   ^^^^^^^^
            'Assa.txt:',
            '    1: {{ die; }}',
            re( qr{$E\QDied at Assa.txt line 1\E\b} ),
        ],
    },
};

#   Mutable file: content changed.
SKIP: {
    if ( Dist::Zilla->VERSION() < version->parse( '5.000' ) ) {
        skip 'no MutableFile role in Dist::Zilla < 5.000';
    };
    run_me 'Mutable file, content' => {
        hook => sub {
            my ( $self, $string ) = @_;
            my $file = Dist::Zilla::File::InMemory->new( {
                name    => 'Assa.3d',
                content => $string,
            } );
            $self->fill_in_file( $file );
            return $file->content;  # Return file content, not result of `fill_in_file`.
        },
        text     => [ '2 + 3 = {{ 2 + 3 }};' ],
        expected => {
            text => [ '2 + 3 = 5;' ],
        },
    };
};

#   Mutable file: result of `fill_in_file`.
run_me 'Mutable file, fill_in_file result' => {
    hook => sub {
        my ( $self, $string ) = @_;
        my $file = Dist::Zilla::File::InMemory->new( {
            name    => 'Assa.3e',
            content => $string,
        } );
        return $self->fill_in_file( $file );    # Return result of `fill_in_file`.
    },
    text     => [ '2 * 3 = {{ 2 * 3 }};' ],
    expected => {
        text => [ '2 * 3 = 6;' ],
    },
};

run_me 'Fill_in_file error message + filename has no effect' => {
    hook => sub {
        my ( $self, $string ) = @_;
        my $file = Dist::Zilla::File::InMemory->new( {
            name => 'Assa.3f',
            content => $string,
        } );
        return $self->fill_in_file( $file, undef, { filename => 'QWERTY.TXT' } );
    },
    text => [
        'line   1',
        '{{   # 2',
        'die; # 3',
        '}}     4',
        'line   5',
        'line   6',
        'line   7',
    ],
    expected => {
        exception => $aborting,
        messages  => [
            re( qr{^\QDied at Assa.3f line 3\E\b} ),
            '    Bad code fragment begins at Assa.3f line 2.',
            'Assa.3f:',
            '    1: line   1',
            '    2: {{   # 2',
            re( qr{$E\QBad code fragment begins at Assa.3f line 2.\E} ),
            '    3: die; # 3',
            re( qr{$E\QDied at Assa.3f line 3\E\b} ),
            '    4: }}     4',
            '    5: line   5',
            '       ... skipped 2 lines ...',
        ],
    },
};

#   Non-mutable file.
run_me 'Non-mutable file' => {
    hook => sub {
        my ( $self, $string ) = @_;
        my $file = Dist::Zilla::File::FromCode->new( {
            # This is non-mutable file.
            name                => 'FileFromCode',
            code_return_type    => 'text',
            code                => sub {
                return $string;
            },
        } );
        return $self->fill_in_file( $file );
    },
    text     => [ '2 + 3 = {{ 2 + 3 }};' ],
    expected => {
        text => [ '2 + 3 = 5;' ],
        # No exceptions => `fill_in_file` does not try to modify the file.
    },
};

#   File is an object of `Path::Tiny` class.
{
    my $file = Path::Tiny->tempfile();
    my $name = "$file";
    run_me 'Path::Tiny' => {
        hook => sub {
            my ( $self, $string ) = @_;
            $file->append_utf8( $string );
            return $self->fill_in_file( $file );
        },
        prepend  => [ 'use warnings;' ],
        text     => [ '2 + 3 = {{ 2 + 3 }};{{ $OUT .= $a; }}' ],
        #                                             ^^^ Undefined variable causes warning.
        expected => {
            text => [ '2 + 3 = 5;' ],
            messages => [
                re( qr{^Use of uninitialized value.* at \Q$name\E line 1\b} ),
                #                                         ^^^^^ Check file name.
            ],
        },
    };
}

#   File is an object of `Path::Class::File` class.
{
    my $dir  = Path::Class::tempdir( CLEANUP => 1 );
    my $file = $dir->file( 'assa.txt' );
    my $name = "$file";
    run_me 'Path::Class::File' => {
        hook => sub {
            my ( $self, $string ) = @_;
            $file->spew( iomode => '>:encoding(UTF-8)', $string );
            return $self->fill_in_file( $file );
        },
        prepend  => [ 'use warnings;' ],
        text     => [ '2 + 3 = {{ 2 + 3 }};{{ $OUT .= $a; }}' ],
        #                                             ^^^ Undefined variable causes warning.
        expected => {
            text => [ '2 + 3 = 5;' ],
            messages => [
                re( qr{^Use of uninitialized value.* at \Q$name\E line 1\b} ),
                #                                         ^^^^^ Check file name.
            ],
        },
    };
}

#   File is a string — a file name.
{
    my $file = Path::Tiny->tempfile();
    my $name = "$file";
    run_me 'fill_in_file with string' => {
        hook => sub {
            my ( $self, $string ) = @_;
            $file->append_utf8( $string );
            my $ret =  $self->fill_in_file( $name );
            #                               ^^^^^ File specified by its name.
            is( $file->slurp_utf8(), $string, 'File on disk is not changed' );
            return $ret;
        },
        prepend  => [ 'use warnings;' ],
        text     => [ '2 + 3 = {{ 2 + 3 }};{{ $OUT .= $a; }}' ],
        #                                             ^^^ Undefined variable causes warning.
        expected => {
            text => [ '2 + 3 = 5;' ],
            messages => [
                re( qr{^Use of uninitialized value.* at \Q$name\E line 1\b} ),
                #                                         ^^^^^ Check file name.
            ],
        },
    };
}

done_testing;

exit( 0 );

# end of file #
