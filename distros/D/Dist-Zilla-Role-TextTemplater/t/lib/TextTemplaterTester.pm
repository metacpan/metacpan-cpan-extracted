#   ---------------------------------------------------------------------- copyright and license ---
#
#   file: t/lib/TextTempalerTester.pm
#
#   Copyright © 2015, 2016 Van de Bugger.
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
#   ---------------------------------------------------------------------- copyright and license ---

package TextTemplaterTester;

#   The test is written using `Moose`-based `Test::Routine`. It is not big deal, because we are
#   testing plugin for `Dist::Zilla`, and `Dist-Zilla` is also `Moose`-based.

use autodie ':all';
use namespace::autoclean;

use Test::Routine;

with 'Test::Dist::Zilla::Build';

use Test::More;
use Test::Deep qw{ cmp_deeply };

has text => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    default     => sub { [] },
);

has delimiters => (
    is          => 'ro',
    isa         => 'Str',
);

has package => (
    is          => 'ro',
    isa         => 'Str',
);

has prepend => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    default     => sub { [] },
);

sub _build_plugins {
    my ( $self ) = @_;
    return [
        'GatherDir',
        [ '=TextTemplaterTestPlugin', {
            'text' => $self->text,
            $self->delimiters   ? ( delimiters => $self->delimiters ) : (),
            $self->package      ? ( package    => $self->package    ) : (),
            @{ $self->prepend } ? ( prepend    => $self->prepend    ) : (),
        } ]
    ];
};

sub _build_message_filter {
    return sub {
        map(
            { ( my $r = $_ ) =~ s{^\[[^\[\]]*\] }{}; $r; }
            grep( { $_ =~ m{^\[=TextTemplaterTestPlugin\] } } @_ )
        );
    };
};

has hook => (
    is          => 'ro',
    isa         => 'CodeRef',
);

around build => sub {
    my ( $orig, $self, @args ) = @_;
    local $TextTemplaterTestPlugin::Hook = $self->hook if $self->hook;
    return $self->$orig( @args );
};

test 'Text' => sub {

    my ( $self ) = @_;
    my $expected = $self->expected;

    if ( $self->exception ) {
        plan skip_all => 'exception occurred';
    };
    if ( not exists( $expected->{ text } ) ) {
        plan skip_all => 'no expected text';
    };

    plan tests => 1;

    my $plugin = $self->tzil->plugin_named( '=TextTemplaterTestPlugin' );
    $self->_anno_text( 'Template', @{ $self->text } );
    $self->_anno_text( 'Output', @{ $plugin->text } );
    cmp_deeply( $plugin->text, $expected->{ text }, 'text' );

    done_testing;

};

1;

# end of file #
