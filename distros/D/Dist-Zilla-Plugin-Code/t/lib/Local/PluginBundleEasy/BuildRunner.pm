package Local::PluginBundleEasy::BuildRunner;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::PluginBundle::Easy';

our $RESULT;

use namespace::autoclean;

sub configure {
    my ($self) = @_;

    my $plugin_class = $self->payload->{plugin};
    my $plugin_name  = $self->payload->{name};
    my $input        = $self->payload->{input};
    my $code         = $self->payload->{code};
    $RESULT = undef;

    my ($moniker) = $plugin_class =~ m{ ^ \QDist::Zilla::Plugin::\E ( .+ ) }xsm;

    $self->add_plugins(
        [
            $moniker,
            $plugin_name,
            {
                $code => [
                    sub {
                        my ($self) = @_;
                        $self->log($input);
                        $RESULT = $input * $input;
                        mkdir 'blib';    ## no critic (InputOutput::RequireCheckedSyscalls)
                        return;
                    },
                ],
            },
        ],
    );

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
