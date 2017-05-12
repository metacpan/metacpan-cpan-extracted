#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/die-hard.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Tester-DieHard.
#
#   perl-Dist-Zilla-Tester-DieHard is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Tester-DieHard is distributed in the hope that it will be useful, but WITHOUT
#   ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Tester-DieHard. If not, see <http://www.gnu.org/licenses/>.
#
#   ---------------------------------------------------------------------- copyright and license ---

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use lib 't/lib';
use strict;
use warnings;
use autodie;
use version 0.77;

use DistZillaPlugin;
use File::Temp ();
use Test::DZil qw{ dist_ini };
use Test::More;

#   `AutoPrereqs` hints:
use Software::License::GPL_3::or_later ();
use Path::Tiny 0.059 ();
    # ^ We do not use `Path::Tiny` directly, it is used by `Dist::Zilla` internally. However, the
    #   test may fail with pre-0.59 `Path::Tiny` due to exception
    #       Can't locate Unicode/UTF8.pm in @INC
    #   trown from it.

my $ini_head = {
    name                => 'Dummy',
    version             => '0.007',
    author              => 'John Doe',
    license             => 'GPL_3::or_later',
    copyright_holder    => 'John Doe',
    copyright_year      => '2007',
};

my @ini_body = (
    [ '=DistZillaPlugin' ],     # This plugin dies in constructor.
);

my $args = {
    dist_root => File::Temp->newdir(),
};

my $tester_args = {
    add_files => {
        'source/lib/Dummy.pm' =>
            "package Dummy;\n" .
            "\n" .                  # Blank line for `PkgVersion`.
            "# ABSTRACT: Dummy\n" .
            "# VERSION\n" .
            "1;\n",
        'source/dist.ini' => dist_ini( $ini_head, @ini_body ),
    },
};

my $error = qr{Died at t/lib/DistZillaPlugin\.pm line };

# --------------------------------------------------------------------------------------------------

subtest 'regular' => sub {

    package Regular;                    # Localize `use Dist::Zilla::Tester` effect.

    use Dist::Zilla::Tester;
    use Test::Fatal;
    use Test::More;

    my ( $tzil, $exception );

    $exception = exception { $tzil = Builder->from_config( $args, $tester_args ); };
    like( $exception, qr{^$error}, 'exception' );
    is( $tzil, undef, '$tzil undefined' );

    #   Ok, we have exception and can check it. That's all. `DistZillaPlugin` logged a message
    #   before dying, but we cannot check it: all the messages are lost.

    #   `Dist::Zilla::Tester` starting from 5.040 provides function `most_recent_log_events` which
    #   can be used for retrieving messages. But it is out of my interest.

    done_testing;

};

# --------------------------------------------------------------------------------------------------

for my $method ( qw{ build release } ) {
    subtest "die hard in $method" => sub {

        package DieHard;                # Localize `use Dist::Zilla::Tester::DieHard` effect.

        use Dist::Zilla::Tester::DieHard;
        use Scalar::Util qw{ blessed };
        use Test::Deep qw{ cmp_deeply };
        use Test::Fatal;
        use Test::More;

        my ( $tzil, $exception, $messages );

        $exception = exception { $tzil = Builder->from_config( $args, $tester_args ); };
        is( $exception, undef, 'no exception' );
        isnt( $tzil, undef, '$tzil defined' );
        ok( blessed( $tzil ), '$tzil blessed' );

        #   No exception. `$tzil` is defined, we can retrieve messages.

        my @messages = @{ $tzil->log_messages };    # Create a copy.
        cmp_deeply( \@messages, [ '[=DistZillaPlugin] before die' ], 'messages' )
            or diag( "Log:\n" . join( '', map( "    $_\n", @messages ) ) );

        #   Saved exception will be rethrown by the method. Messages are still available.

        $exception = exception { $tzil->$method(); };
        like( $exception, qr{^$error}, 'exception' );
        cmp_deeply( $tzil->log_messages, \@messages, 'messages are not changed' )
            or diag( "Log:\n" . join( '', map( "    $_\n", @messages ) ) );

        done_testing;

    };
};

# --------------------------------------------------------------------------------------------------

subtest "die hard before ctor" => sub {

    #   `from_config` can die before constructing a builder (usually it occurs when
    #   `Dist::Zilla::Tester` prepares source files). It is a special case.

    package DieHardBeforeCtor;          # Localize `use Dist::Zilla::Tester::DieHard` effect.

    use autodie;
    use version 0.77;

    use Dist::Zilla::Tester::DieHard;
    use Scalar::Util qw{ blessed };
    use Test::Deep qw{ cmp_deeply cmp_details deep_diag };
    use Test::Fatal;
    use Test::More;

    my ( $tzil, $exception, $expected_error );
    my $tmp_root = File::Temp->newdir();
    my $bad_tester_args = {         # Not bad at this moment, will make them really bad later.
        tempdir_root => "$tmp_root",
        add_files => {
            %{ $tester_args->{ add_files } },
        },
    };

    #   Throwing an exception before `Dist::Zilla` constructor is not an easy deal, especially if
    #   do it portably. The only method I could think out is doing something wrong at populating
    #   distro source tree.
    #
    #   My first attempt was to make the temp directory (where the distribution source tree would
    #   be creared) read-only. It worked good for Linux and other Unix-like systems, but did not
    #   work for Windows (I do not remeber details), so I had to do something different for that
    #   OS.
    #
    #   On Windows I tried to use invalid file name. On Windows `Dist::Zilla::Tester` died if
    #   filename contains backslash. However, it worked only if `Dist::Zilla` >= 5.023. Also, in
    #   `Dist::Zilla` >= 6.0 they changed the error message. Also, it did not work  on Cygwin.
    #   Considering all these condition made the code too complicated.
    #
    #   So I continued attempts to die `Dist::Zilla::Tester` portably. Next try was using an empty
    #   file name: `Path::Tiny` did with message "Path::Tiny paths require defined, positive-length
    #   parts". However, it works only in `Dist::Zilla` >= 6.0.
    #
    #   My current favorite is `..`. It seems this names cause the same trouble on all systems (do
    #   not have test results on Cygwin yet).
    #
    $bad_tester_args->{ add_files }->{ '..' } = 'Bad file';
    $expected_error = qr{^Error rename on };

    $exception = exception { $tzil = Builder->from_config( $args, $bad_tester_args ); };
    is( $exception, undef, 'no exception' );
    isnt( $tzil, undef, '$tzil defined' );
    ok( blessed( $tzil ), '$tzil blessed' );

    #   No exception. `$tzil` is defined, we can retrieve messages.

    my @messages = @{ $tzil->log_messages };    # Create a copy.
    cmp_deeply( \@messages, [], 'messages' )
        or diag( "Log:\n" . join( '', map( "    $_\n", @messages ) ) );

    #   Saved exception will be rethrown by the method. Messages are still available.

    $exception = exception { $tzil->build(); };
    like( $exception, $expected_error, 'exception' );
    cmp_deeply( $tzil->log_messages, \@messages, 'messages are not changed' )
        or diag( "Log:\n" . join( '', map( "    $_\n", @messages ) ) );

    done_testing;

};

done_testing;

exit( 0 );

# end of file #
