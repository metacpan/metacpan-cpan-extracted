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

package Local::PluginBundleEasy::RetVal;

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $RESULT;

use namespace::autoclean;

sub configure {
    my ($self) = @_;

    my $plugin_class = $self->payload->{plugin};
    my $plugin_name  = $self->payload->{name};
    my $code         = $self->payload->{code};
    my $retval       = $self->payload->{retval};
    $RESULT = undef;

    my ($moniker) = $plugin_class =~ m{ ^ \QDist::Zilla::Plugin::\E ( .+ ) }xsm;

    $self->add_plugins(
        [
            $moniker,
            $plugin_name,
            {
                $code => sub {
                    my ($self) = @_;
                    $self->log("Name = $retval");
                    return $retval;
                },
            },
        ],
        [
            'Code::BeforeBuild',
            'SayMyNameEasy',
            {
                before_build => sub {
                    my ($self) = @_;
                    $RESULT = $self->zilla->name;
                    return;
                },
            },
        ],
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
