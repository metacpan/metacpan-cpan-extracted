#!perl
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/error-logger.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-Role-ErrorLogger.
#
#   perl-Dist-Zilla-Role-ErrorLogger is free software: you can redistribute it and/or modify it
#   under the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Role-ErrorLogger is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Role-ErrorLogger. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use autodie ':all';
use lib 't/lib';
use namespace::autoclean;
use strict;
use warnings;

use Dist::Zilla::File::InMemory;
use Test::Deep qw{ isa re };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );

has hook => (
    is          => 'ro',
    isa         => 'CodeRef',
    default     => sub {},
);

sub _build_plugins {
    my ( $self ) = @_;
    return [
        'GatherDir',
        '=FileGatherer',
    ];
};

sub _build_message_filter {
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r; }
            grep( { $_ =~ m{^\[=FileGatherer\] } } @_ )
        );
    };
};

around build => sub {
    my ( $orig, $self, @args ) = @_;
    no warnings 'once';
    local $FileGatherer::Hook = $self->hook;
    return $self->$orig( @args );
};

# --------------------------------------------------------------------------------------------------

plan tests => 10;

run_me 'Successful build' => {
    hook => sub {
        my ( $self ) = @_;
        my $rc;
        subtest 'inner' => sub {
            plan tests => 6;
            is( $self->error_count, 0, 'error count inited to zero' );
            $self->abort_if_error();
            pass( 'not yet aborted' );
            $rc = $self->log_error( 'the first error' );
            ok( $rc, 'log_error returns true value' );
            is( $self->error_count, 1, 'error count bumped' );
            $rc = $self->log_error( 'another error' );
            ok( $rc, 'log_error returns true value again' );
            is( $self->error_count, 2, 'error count bumped again' );
            done_testing;
        };
    },
    expected => {
        messages => [
            'the first error',
            'another error',
        ],
    },
};

run_me 'Abort' => {
    #   `abort` with no arguments does not add messages to the log, it just dies.
    hook => sub {
        my ( $self ) = @_;
        $self->abort();
    },
    expected => {
        exception => $aborting,
        messages  => [],        # No messages.
    },
};

run_me 'Abort with arg' => {
    #   `abort` with an argument logs it, and then dies.
    hook => sub {
        my ( $self ) = @_;
        $self->abort( 'Oops!' );                            # Abort message.
    },
    expected => {
        exception => $aborting,
        messages  => [
            'Oops!',                                        # Abort message was logged
        ],
    },
};

#   This time we expect exception. If an exception is generated within subtest, it considered
#   failed, so do not organize subtest here.
run_me 'Abort if error' => {
    hook => sub {
        my ( $self ) = @_;
        $self->abort_if_errors();
        pass( 'not yet aborted' );
        $self->log_error( 'error' );                        # Error message
        $self->abort_if_errors();
        fail( 'must be aborted before this point' );
    },
    expected => {
        exception => $aborting,
        messages  => [
            'error',                                        # Error message was logged
        ],
    },
};

run_me 'Abort if error with arg' => {
    hook => sub {
        my ( $self ) = @_;
        $self->log_error( 'error' );                        # Error message
        $self->abort_if_errors( 'Custom abort' );           # Custom abort message
        fail( 'must be aborted before this point' );
    },
    expected => {
        exception => $aborting,
        messages => [
            'error',                                        # Error message was logged.
            'Custom abort',                                 # Custom abort message was logged too
        ],
    },
};

run_me 'Log arguments' => {
    hook => sub {
        my ( $self ) = @_;
        my ( $args, $orig );
        subtest 'inner' => sub {
            plan tests => 2;
            $args = { prefix => 'pfx1: ' };
            $orig = { %$args };
            $self->log_error( $args, 'error' );                 # Error message with custom prefix.
            is_deeply( $args, $orig, 'args are not changed' );
            $args = { prefix => 'pfx2: ', level => 'info' };
            $orig = { %$args };
            $self->log_error( $args, 'another' );               # With custom prefix and level.
            is_deeply( $args, $orig, 'args are not changed again' );
            done_testing;
        };
    },
    expected => {
        messages => [
            'pfx1: error',                                      # Error message with custom prefix.
            'pfx2: another',                                    # With custom prefix and level.
        ],
    },
};

my $file = Dist::Zilla::File::InMemory->new( {
    name => 'lib/Assa.pm',
    content => join( "\n",
        'package Assa;',             #  1
        '',                          #  2
        'use strict;',               #  3
        'use warnings;',             #  4
        'our $VERSION = "0.001";',   #  5
        '',                          #  6
        'sub assa {',                #  7
        '    return 1;',             #  8
        '};',                        #  9
        '',                          # 10
        '1;',                        # 11
        '',                          # 12
        '__END__',                   # 13
    ),
} );

run_me 'No errors in file' => {
    hook => sub {
        my ( $self ) = @_;
        subtest 'inner' => sub {
            plan tests => 1;
            my $rc = $self->log_errors_in_file( $file );
            is( $rc, 0 );
        };
    },
    expected => {
        messages => [
            'No errors at lib/Assa.pm.',
        ],
    },
};

run_me 'One error in file' => {
    hook => sub {
        my ( $self ) = @_;
        subtest 'inner' => sub {
            plan tests => 1;
            my $rc = $self->log_errors_in_file( $file, 5 => 'Error message' );
            ok( $rc > 0 );
        };
        $self->abort_if_error();
    },
    expected => {
        exception => $aborting,
        messages => [
            'lib/Assa.pm:',
            '        ... skipped 2 lines ...',
            '    03: use strict;',
            '    04: use warnings;',
            '    05: our $VERSION = "0.001";',
            '        ^^^ Error message ^^^',
            '    06: ',
            '    07: sub assa {',
            '        ... skipped 6 lines ...',
        ],
    },
};

run_me 'Multiple messages + do not skip one line' => {
    hook => sub {
        my ( $self ) = @_;
        subtest 'inner' => sub {
            plan tests => 1;
            my $rc = $self->log_errors_in_file(
                $file,
                8  => 'One more message',       # No need in sorting messages.
                2  => 'Error message',
                2  => 'Another message',        # More than one message for line 1.
                2  => [ 'third message', 'and fourth message' ],
            );
            ok( $rc > 0 );
        };
        $self->abort_if_error();
    },
    expected => {
        exception => $aborting,
        messages => [
            'lib/Assa.pm:',
            '    01: package Assa;',
            '    02: ',
            '        ^^^ Error message ^^^',
            '        ^^^ Another message ^^^',   # Messages are logged in order of appearance.
            '        ^^^ third message ^^^',
            '        ^^^ and fourth message ^^^',
            '    03: use strict;',
            '    04: use warnings;',
            '    05: our $VERSION = "0.001";',   # One line is not skipped.
            '    06: ',
            '    07: sub assa {',
            '    08:     return 1;',
            '        ^^^ One more message ^^^',
            '    09: };',
            '    10: ',
            '        ... skipped 3 lines ...',
        ],
    },
};

run_me 'Invalid line numbers' => {
    hook => sub {
        my ( $self ) = @_;
        subtest 'inner' => sub {
            plan tests => 1;
            my $rc = $self->log_errors_in_file(
                $file,
                14 => 'Beyond the last line',
                25 => 'Far beyond the eof',
                5  => 'Error message',
                -1 => 'Minus one',
                0  => 'Zero',
            );
            ok( $rc < 0 );
        };
        $self->abort_if_error();
    },
    expected => {
        exception => $aborting,
        messages => [
            'lib/Assa.pm:',
            '        ... skipped 2 lines ...',
            '    03: use strict;',
            '    04: use warnings;',
            '    05: our $VERSION = "0.001";',
            '        ^^^ Error message ^^^',
            '    06: ',
            '    07: sub assa {',
            '        ... skipped 6 lines ...',
            'Following errors are reported against non-existing lines of the file:',
            '    Minus one at lib/Assa.pm line -1.',
            '    Zero at lib/Assa.pm line 0.',
            '    Beyond the last line at lib/Assa.pm line 14.',
            '    Far beyond the eof at lib/Assa.pm line 25.',
        ],
    },
};

done_testing;

# --------------------------------------------------------------------------------------------------

exit( 0 );

# end of file #
