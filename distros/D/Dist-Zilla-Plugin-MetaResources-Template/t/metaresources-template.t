#!perl
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
#   file: t/metaresources-template.t
#
#   Copyright © 2015 Van de Bugger
#
#   This file is part of perl-Dist-Zilla-Plugin-MetaResources-Template.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is free software: you can redistribute it and/or
#   modify it under the terms of the GNU General Public License as published by the Free Software
#   Foundation, either version 3 of the License, or (at your option) any later version.
#
#   perl-Dist-Zilla-Plugin-MetaResources-Template is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#   FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   perl-Dist-Zilla-Plugin-MetaResources-Template. If not, see <http://www.gnu.org/licenses/>.
#
#   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#   The test is written using `Moose`-based `Test::Routine`. It is not big deal, because we are
#   testing plugin for `Dist::Zilla`, and `Dist-Zilla` is also `Moose`-based.

use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC';
use autodie ':all';                     # REQUIRE: IPC::System::Simple
use namespace::autoclean;
use strict;
use version 0.77;
use warnings;

use Dist::Zilla;
use Software::License::Perl_5;
use Test::Deep qw{ re isa cmp_deeply };
use Test::More;
use Test::Routine;
use Test::Routine::Util;

with 'Test::Dist::Zilla::Build';

# REQUIRE: Dist::Zilla::Role::TextTemplater v0.8.0
    # ^ Error messages changed in v0.8.0. With earlier version the test fails.

my $Plugin = 'MetaResources::Template';

#   `MetaResources::Template` plugin options, in form acceptable by `Builder->from_config`.
has resources => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);

sub _build_message_filter {
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r; }
            grep( { $_ =~ m{^\[$Plugin\] } } @_ )
        );
    };
};

sub _build_plugins {
    my ( $self ) = @_;
    return [
        'GatherDir',                    # REQUIRE: Dist::Zilla::Plugin::GatherDir
        'Manifest',                     # REQUIRE: Dist::Zilla::Plugin::Manifest
        'MetaYAML',                     # REQUIRE: Dist::Zilla::Plugin::MetaYAML
        [ $Plugin => $self->resources ],
    ];
};

test 'Resources' => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;

    if ( not exists( $expected->{ resources } ) ) {
        plan skip_all => 'no expected resources';
    };
    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };

    plan tests => 1;

    my $resources = $self->tzil->distmeta->{ resources };
    cmp_deeply( $resources, $expected->{ resources }, 'resources' );

};

# --------------------------------------------------------------------------------------------------

my $aborting = isa( 'Dist::Zilla::Role::ErrorLogger::Exception::Abort' );
    # REQUIRE: Dist::Zilla::Role::ErrorLogger v0.9.0
my $license = Software::License::Perl_5->new( { holder => 'John Doe', year => '2007' } );
my $E = qr{^\s*\^\^\^ };

# --------------------------------------------------------------------------------------------------

plan tests => 8;

run_me 'Successful build' => {
    resources => {
        #   Check various datatypes of resources:
        'homepage'          => 'http://example.org/{{ $dist->name }}',              # String.
        'bugtracker.web'    => 'https://example.org/{{ $dist->name }}/bugs',        # Hash.
        'license'           => [ '{{ $dist->license->url }}' ],                     # Array.
        'bugtracker.mailto' => 'mailto:bugs+{{ $dist->name }}@example.org',
        'x_plugin'          => '{{ $plugin->plugin_name }}',
    },
    expected => {
        resources => {
            homepage   => 'http://example.org/Dummy',
            bugtracker => {
                web    => 'https://example.org/Dummy/bugs',
                mailto => 'mailto:bugs+Dummy@example.org',
            },
            license => [ $license->url ],   # REQUIRE: Dist::Zilla::Plugin::MetaResources 4.300039
                #   License resource in `Dist::Zilla::MetaResources` 4.300039 converted from `Str`
                #   to `ArrayRef[Str]`. Attemp to tune test behavior to work with both variants
                #   failed: old `Dist::Zilla` with moderm `CPAN::Meta` causes error:
                #       [MetaYAML] Invalid META structure.  Errors found:
                #       [MetaYAML] Expected a list structure (license) [Validation: 2]
                #   I see no point in complicating the test, so let me just require appropriate
                #   `Dist::Zilla` version.
            x_plugin => 'MetaResources::Template',
        },
    },
};

{
    #   `MetaResources` has `BUILDARGS` method wich mangles all the options.
    #   Make sure `TextTemplater` options are not mangled.
    local ( $MY::name, $MY::bt_web, $MY::bt_mail );
    $MY::name    = "Foo";
    $MY::bt_web  = "https://example.org/$MY::name/bugs";
    $MY::bt_mail = "mailto:bugs+$MY::name\@example.org";
    run_me 'package works' => {
        resources => {
            package             => 'MY',
            'bugtracker.web'    => '{{$bt_web}}',
            'bugtracker.mailto' => '{{$bt_mail}}',
        },
        expected => {
            resources => {
                bugtracker => {
                    web    => 'https://example.org/Foo/bugs',
                    mailto => 'mailto:bugs+Foo@example.org',
                },
            },
        },
    };
    run_me 'prepend works' => {
        resources => {
            prepend             => 'package MY;',
            'bugtracker.web'    => '{{$bt_web}}',
            'bugtracker.mailto' => '{{$bt_mail}}',
        },
        expected => {
            resources => {
                bugtracker => {
                    web    => 'https://example.org/Foo/bugs',
                    mailto => 'mailto:bugs+Foo@example.org',
                },
            },
        },
    };
    run_me 'delimiters work' => {
        resources => {
            delimiters          => '(* *)',
            'bugtracker.web'    => '(*$MY::bt_web*)',
            'bugtracker.mailto' => '(*$MY::bt_mail*)',
        },
        expected => {
            resources => {
                bugtracker => {
                    web    => 'https://example.org/Foo/bugs',
                    mailto => 'mailto:bugs+Foo@example.org',
                },
            },
        },
    };
}

run_me 'Error in string' => {
    resources => {
        'prepend'           => 'use strict;',
        'homepage'          => '{{$home}}',
        #^^^^^^^^
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^Global symbol "\$home" requires explicit package name.* at homepage line 1\b} ),
            '    Bad code fragment begins at homepage line 1.',
            #                                ^^^^^^^^
            'homepage:',
            #^^^^^^^^
            '    1: {{$home}}',
            re( qr{${E}Global symbol "\$home" requires explicit package name.* at homepage line 1\b} ),
        ],
    },
};

run_me 'Error in hash' => {
    resources => {
        'prepend'           => 'use strict;',
        'bugtracker.web'    => '{{$bt_web}}',
        #^^^^^^^^^^^^^^
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^Global symbol "\$bt_web" requires explicit package name.* at bugtracker\.web line 1\b} ),
            '    Bad code fragment begins at bugtracker.web line 1.',
            #                                ^^^^^^^^^^^^^^
            'bugtracker.web:',
            #^^^^^^^^^^^^^^
            '    1: {{$bt_web}}',
            re( qr{${E}Global symbol "\$bt_web" requires explicit package name.* at bugtracker\.web line 1\b} ),
        ],
    },
};

run_me 'Error in array' => {
    resources => {
        'prepend'   => 'use strict;',
        'license'   => [ '{{$lic}}' ],  # REQUIRE: Dist::Zilla::Plugin::MetaResources 4.300039
        #^^^^^^^^     ^^^          ^^^ Array.
    },
    expected => {
        exception => $aborting,
        messages => [
            re( qr{^Global symbol "\$lic" requires explicit package name.* at license#1 line 1\b} ),
            '    Bad code fragment begins at license#1 line 1.',
            #                                ^^^^^^^^^
            'license#1:',
            #^^^^^^^^^
            '    1: {{$lic}}',
            re( qr{${E}Global symbol "\$lic" requires explicit package name.* at license#1 line 1\b} ),
        ],
    },
};

run_me 'warning about undefined variable' => {
    resources => {
        'prepend'           => 'use warnings;',
        'homepage'          => 'http://example.org/{{$OUT .= $MY::home}}',
            #   1.  `{{$MY::home}} does not cause a warning. Perl issues a warning when undefined
            #       value is used in an expression.
            #   2.  Older `Dist::Zilla` (5.020) dies if `homepage` resource exists but is empty.
            #       So `homepage` should be a valid URL even if Perl code fragment is expanded to
            #       empty string.
    },
    expected => {
        messages => [
            re( qr{^Use of uninitialized value.* at homepage line 1\b} ),
            #   Error message depends on Perl version. Older Perl versions (v5.8) does not include
            #   name of undefined variable, newer version includes, so do not be too specific.
        ],
    },
};

done_testing;

exit( 0 );

# end of file #
