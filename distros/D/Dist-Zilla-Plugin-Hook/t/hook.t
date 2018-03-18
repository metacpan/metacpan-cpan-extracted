#!perl
#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/hook.t
#
#   Copyright © 2015, 2016, 2018 Van de Bugger.
#
#   This file is part of perl-Dist-Zilla-Plugin-Hook.
#
#   perl-Dist-Zilla-Plugin-Hook is free software: you can redistribute it and/or modify it under
#   the terms of the GNU General Public License as published by the Free Software Foundation,
#   either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-Hook is distributed in the hope that it will be useful, but WITHOUT ANY
#   WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-Hook. If not, see <http://www.gnu.org/licenses/>.
#
#   SPDX-License-Identifier: GPL-3.0-or-later
#
#   ---------------------------------------------------------------------- copyright and license ---

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use lib 't/lib';

use Test::Deep qw{ re isa };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'HookTester';

sub hook($$) {
    my ( $name, $text )  = @_;
    $text =~ s{\A\n}{};
    $text =~ s{\n +\z}{\n};
    return [ $name, { 'hook' => [ split( "\n", $text ) ] } ];
};

sub skip_if_missed($) {
    my ( $module ) = @_;
    local $@;
    eval "require $module;";
    if ( $@ ) {
        note( $@ );
        if ( not $ENV{ AUTHOR_TESTING } ) {
            skip "Can't load $module", 1;
        };
    };
};

my $abort = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    ## REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0

#   `$self` and `$zilla` variables are defined.
run_me '$self and $zilla' => {
    plugins => [
        hook( 'Hook::Init', q{
            $self->log( $zilla->name );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::Init] Dummy'
        ],
    }
};

#   `$plugin` variable is defined too.
run_me '$plugin == $self' => {
    plugins => [
        hook( 'Hook::Init', q{
            $self->log( $plugin == $self ? "OK" : "NOT OK" );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::Init] OK',
        ],
    },
};

#   `$dist` variable is defined too.
run_me '$dist == $zilla' => {
    plugins => [
        hook( 'Hook::Init', q{
            $self->log( $dist == $zilla ? "OK" : "NOT OK" );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::Init] OK',
        ],
    },
};

#   `$arg` variable is defined if method is called with an argument.
run_me '$arg defined' => {
    plugins => [
        # `Dist::Zilla` provides an argument for `LicenseProvider`.
        hook( 'Hook::LicenseProvider', q{
            $plugin->log( [
                "Copyright (C) %d %s", $arg->{ copyright_year }, $arg->{ copyright_holder }
            ] );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::LicenseProvider] Copyright (C) 2007 John Doe',
        ],
    },
};

SKIP: {
    skip 'Not yet decided', 1;      # TODO: Should I declare the variable and let it undefined or
                                    #   not declare variable at all? What about warnings?
    run_me '$arg not defined' => {
        #   Check $arg variable is not defined if plugin does receives an argument.
        plugins => [
            hook( 'Hook::BeforeBuild', q{
                $plugin->log( $arg );
            } ),
            'GatherDir',
        ],
        expected => {
            exception => $abort,
            messages => [
                re( qr{^\[Hook::BeforeBuild\] Global symbol "\$arg" requires explicit package name.* at Hook::BeforeBuild line 1\b} ),
            ],
        },
    };
};

#   `@_` variable defined, if method is called with argument.
#   `provide_license` method of `LicenseProvider` role is called with `HashRef` with two keys:
#   `copyright_holder` and `copyright_year`. Let us check it.
run_me '@_' => {
    plugins => [
        hook( 'Hook::LicenseProvider', q{
            my ( $args ) = @_;
            my ( $holder, $year ) = map( $args->{ "copyright_$_" }, qw{ holder year } );
            $plugin->log( [ "Copyright (C) %d %s", $year, $holder ] );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::LicenseProvider] Copyright (C) 2007 John Doe',
        ],
    },
};

#   `use strict;` is in effect (thanks to `Moose`).
run_me '"use strict;" is in effect' => {
    plugins => [
        hook( 'Hook::BeforeBuild', q{
            $assa = 123;
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages => [
            re( qr{^\[Hook::BeforeBuild\] Global symbol "\$assa" requires explicit package name.* at Hook::BeforeBuild line 1\b} ),
        ],
    },
};

#   `use warnings;` is in effect (thanks to `Moose`).
run_me '"use warnings;" is in effect' => {
    #   Using undefined variable causes warning in log, but does not break execution.
    plugins => [
        hook( 'Hook::BeforeBuild', q{
            my $assa;
            my $qwerty = $assa + 1;
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            re( qr{^\[Hook::BeforeBuild\] Use of uninitialized value (\$assa )?in addition \(\+\) at Hook::BeforeBuild line 2\.} ),
            # ^ Perl 5.8 does not print variable name.               ^^^^^^^^^^
        ],
    },
};

#   Semicolon (without preceeding space) works as statement separator.
run_me 'semicolon not preceeded by space' => {
    plugins => [
        hook( 'Hook::Init', q{
            $plugin->log( "Assa" ); $plugin->log( "Qwerty" );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::Init] Assa',
            '[Hook::Init] Qwerty',
        ],
    },
};

#   Semicolon (with preceeding space) works as comment starter.
run_me 'semicolon preceeded by space' => {
    plugins => [
        hook( 'Hook::Init', q{
            $plugin->log( "Assa" ) ; $plugin->log( "Qwerty" );
        } ),
        'GatherDir',
    ],
    expected => {
        messages => [
            '[Hook::Init] Assa',    # Only one message, no "Qwerty".
        ],
    },
};

my $hook = '
    $plugin->log( "hook" );
    if ( $plugin->plugin_name eq "Hook::MetaProvider" ) {
        return {};
    } else {
        return undef;
    };
';

SKIP: {
    my $dzil_ver = version->parse( Dist::Zilla->VERSION );
    # ^Dist::Zilla output differs a bit depending on version.
    skip_if_missed( 'Dist::Zilla::Plugin::ReportPhase' );
    run_me 'Phases' => {
        message_filter => sub { grep( { $_ =~ m{^\[(?:Hook::|Phase)} } @_ ) },
        plugins => [
            'ReportPhase/Phase_Begins',
            hook( 'Hook::AfterBuild',            $hook ),
            hook( 'Hook::AfterMint',             $hook ),
            hook( 'Hook::AfterRelease',          $hook ),
            hook( 'Hook::BeforeArchive',         $hook ),
            hook( 'Hook::BeforeBuild',           $hook ),
            hook( 'Hook::BeforeMint',            $hook ),
            hook( 'Hook::BeforeRelease',         $hook ),
            hook( 'Hook::FileGatherer',          $hook ),
            hook( 'Hook::FileMunger',            $hook ),
            hook( 'Hook::FilePruner',            $hook ),
            hook( 'Hook::Init',                  $hook ),
            hook( 'Hook::InstallTool',           $hook ),
            hook( 'Hook::LicenseProvider',       $hook ),
            hook( 'Hook::MetaProvider',          $hook ),
            hook( 'Hook::ModuleMaker',           $hook ),
                # ^ This hook is called at `dzil new` and not called at `dzil build`, so it does not
                #   appears in the log.
            hook( 'Hook::NameProvider',          $hook ),   # This is not shown in the log because
            hook( 'Hook::PrereqSource',          $hook ),
            hook( 'Hook::Releaser',              $hook ),
            hook( 'Hook::ReleaseStatusProvider', $hook ),
            hook( 'Hook::VersionProvider',       $hook ),
            'GatherDir',
            'ReportPhase/Phase_Ends',
        ],
        message_grepper => sub {
            return $_ =~ m{^\[(?:Phase_(?:Begins|Ends)|Hook::.+?)\] };
        },
        expected => {
            messages => [
                '[Hook::Init] hook',
                '[Phase_Begins] ########## Before Build ##########',
                '[Hook::BeforeBuild] hook',
                '[Phase_Ends] ########## Before Build ##########',
                '[Phase_Begins] ########## Gather Files ##########',
                '[Hook::FileGatherer] hook',
                '[Phase_Ends] ########## Gather Files ##########',
                '[Phase_Begins] ########## Prune Files ##########',
                '[Hook::FilePruner] hook',
                '[Phase_Ends] ########## Prune Files ##########',
                '[Phase_Begins] ########## Provide Version ##########',
                '[Hook::VersionProvider] hook',
                '[Phase_Ends] ########## Provide Version ##########',
                '[Phase_Begins] ########## Munge Files ##########',
                '[Hook::FileMunger] hook',
                '[Phase_Ends] ########## Munge Files ##########',
                '[Phase_Begins] ########## Bundle Config ##########',   # TODO: Support `PluginBundle`?
                '[Hook::PrereqSource] hook',
                '[Phase_Ends] ########## Bundle Config ##########',
                $dzil_ver < v6.0.0 ? (
                    # Dist::Zilla pre-6.0 prints these lines before Metadata phase:
                    '[Hook::LicenseProvider] hook',
                    '[Hook::ReleaseStatusProvider] hook',
                ) : (),
                '[Phase_Begins] ########## Metadata ##########',
                '[Hook::MetaProvider] hook',
                '[Phase_Ends] ########## Metadata ##########',
                $dzil_ver >= v6.0.0 ? (
                    # Dist::Zilla 6.0+ prints these lines after Metadata phase:
                    '[Hook::LicenseProvider] hook',
                    '[Hook::ReleaseStatusProvider] hook',
                ) : (),
                '[Phase_Begins] ########## Setup Installer ##########',
                '[Hook::InstallTool] hook',
                '[Phase_Ends] ########## Setup Installer ##########',
                '[Phase_Begins] ########## After Build ##########',
                '[Hook::AfterBuild] hook',
                '[Phase_Ends] ########## After Build ##########',
            ],
        },
    };
};

#   Hook dies, line number reported correctly.
run_me 'die in hook' => {
    plugins => [
        hook( 'Hook::Init', q{
            #     this is line 1
            die "oops"; # line 2
            #     this is line 3
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            re( qr{^\[Hook::Init\] oops at Hook::Init line 2\b} ),  # Verify the line.
        ],
    },
};

#   Hook dies, but throws not a string but an object.
SKIP: {
    skip_if_missed( 'Throwable' );
    run_me 'die with object' => {
        plugins => [
            hook( 'Hook::Init', q{
                use strict;
                {   package Exception;
                    use Moose;
                    with 'Throwable';
                    has message => ( is => 'ro' );
                    sub string { shift->message };
                    use overload q{""} => \\&string;
                }
                Exception->throw( { message => 'Assa' } );
            } ),
            'GatherDir',
        ],
        expected => {
            exception => $abort,
            messages  => [
                re( qr{^\[Hook::Init\] Assa\b} ),   # Object stringified.
            ],
        },
    };
};

#   Named hook dies, line number reported correctly.
run_me 'die in named hook' => {
    plugins => [
        #   Hook name must include "hook" word,
        #   otherwise messages will be filtered out by `HookTester`.
        hook( 'Hook::Init/HookName', q{
            #     this is line 1
            #     this is line 2
            die "oops"; # line 3
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            re( qr{^\[HookName\] oops at HookName line 3\b} ),  # Verify the line.
        ],
    },
};

#   Named hook dies, hook name contains spaces.
run_me 'hook name contains space' => {
    plugins => [
        #   Hook name must include "hook" word,
        #   otherwise messages will be filtered out by `HookTester`.
        hook( 'Hook::Init/hook name', q{
            #     this is line 1
            #     this is line 2
            die "oops"; # line 3
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            re( qr{^\[hook name\] oops at hook name line 3\b} ),  # Verify the line.
        ],
    },
};

#   Named hook dies, hook name contains quote.
#   Perl `#line` directive does not allow (escaped) quotes in filename. Following directive is
#   incorrect and will be ignored by Perl:
#       #line 1 "hook \"name\""
#   To avoid totally wrong line numbers, `Hooker` replaces quotes with apostrophes.
run_me 'hook name contains quote' => {
    plugins => [
        #                     vvv  vvv Note quotes
        hook( 'Hook::Init/hook "name"', q{
            #     this is line 1
            #     this is line 2
            die "oops"; # line 3
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            re( qr{^\[hook "name"\] oops at hook 'name' line 3\b} ),
            #             ^^^  ^^^              ^^^  ^^^ Note apostrophes.
        ],
    },
};

#   Prologue is executed in the beginning of every hook.
run_me 'prologue' => {
    plugins => [
        hook( 'Hook/prologue',     '$self->log( "prologue" );' ), # !!!! TODO: !!!!
        hook( 'Hook::Init',        '$self->log( "hook" );'     ),
        hook( 'Hook::BeforeBuild', '$self->log( "hook" );'     ),
        'GatherDir',
    ],
    expected => {
        messages  => [
            '[Hook::Init] prologue',            # Prologue before `Hook::Init`.
            '[Hook::Init] hook',
            '[Hook::BeforeBuild] prologue',     # Prologue before `Hook::BeforeBuild`.
            '[Hook::BeforeBuild] hook',
        ],
    },
};

#   Hook dies in prologue. Message printed from the appropriate plugin, but error location
#   is inn prologue.
run_me 'prologue dies' => {
    plugins => [
        hook( 'Hook/prologue', q{
            $self->log( "prologue" );
            die "oops";
        } ),
        hook( 'Hook::Init', q{
            $self->log( "init" );
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            '[Hook::Init] prologue',
            re( qr{\[Hook::Init\] oops at prologue line 2\b} ),
            #       ^^^^^^^^^^^^^         ^^^^^^^^
        ],
    },
};

#   Hook dies in "main body", prologue does not affect line numbers.
run_me 'prologue + body dies' => {
    plugins => [
        hook( 'Hook/prologue', q{
            $self->log( "prologue" );
        } ),
        hook( 'Hook::Init', q{
            $self->log( "init" );
            die "oops";
        } ),
        'GatherDir',
    ],
    expected => {
        exception => $abort,
        messages  => [
            '[Hook::Init] prologue',
            '[Hook::Init] init',
            re( qr{\[Hook::Init\] oops at Hook::Init line 2\b} ),
            #                             ^^^^^^^^^^
        ],
    },
};

done_testing;
exit( 0 );

# end of file #
