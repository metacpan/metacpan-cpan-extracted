# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# Copyright (c) 2020-2023 Sven Kirmess
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use 5.006;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Code;

our $VERSION = '0.008';

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle';

use MooseX::Types::Moose qw(CodeRef HashRef Str);

has bundle_config => (
    is       => 'ro',
    isa      => CodeRef,
    reader   => '_bundle_config',
    required => 1,
);

has name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has payload => (
    is       => 'ro',
    isa      => HashRef,
    required => 1,
);

sub bundle_config {
    my ( $class, $section ) = @_;

    $section->{bundle_config} = delete $section->{payload}->{bundle_config};

    my $self = $class->new($section);

    my $code_ref = $self->_bundle_config;
    return $self->$code_ref;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Code - a dynamic bundle

=head1 VERSION

Version 0.008

=head1 SYNOPSIS

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle';

    sub bundle_config {
        my ( $class, $section ) = @_;

        my @plugins;
        push @plugins, [
            'SomeUniqueName',
            'Dist::Zilla::PluginBundle::Code',
            {
                bundle_config => sub {
                    my ($self) = @_;
                    print $self->payload->{some_arg}, "\n";

                    # Dist::Zilla expects you to return plugins and bundles
                    # or nothing.
                    return;
                },
                some_arg    => 'some value',
                another_arg => 'another value',
            },
        ];

        return @plugins;
    }

=head1 DESCRIPTION

This bundle implements the L<Dist::Zilla::Role::PluginBundle> role. It
can be returned from another bundle by the C<bundle_config> method.

L<Dist::Zilla> will then run the C<bundle_config> method of this code bundle.
This is mainly useful if your bundle wants to return a plugin that runs
in the initialization phase (e.g. L<Dist::Zilla::Plugin::lib>) and run a
function after that plugin run.

This, being a bundle, has no access to the C<zilla> object nor the various
C<log> methods. But you can access the C<name> and C<payload> attributes.
The C<payload> attribute is a hash ref that contains the arguments given to
the code bundle.

B<Note:> Bundles that consume the L<Dist::Zilla::Role::PluginBundle::Easy>
role immediately resolve other bundles themselves, there is no way to push
a bundle back onto the stack. Therefore it doesn't make sense to use this
code bundle inside L<Dist::Zilla::Role::PluginBundle::Easy> bundles.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Code/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Code>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Code.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Role::PluginBundle>

=cut
