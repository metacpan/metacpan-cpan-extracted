package Local::PluginBundleEasy::RetVal;

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
    my $code         = $self->payload->{code};
    my $retval       = $self->payload->{retval};
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
                        $self->log("Name = $retval");
                        return $retval;
                    },
                ],
            },
        ],
        [
            'Code::BeforeBuild',
            'SayMyNameEasy',
            {
                before_build => [
                    sub {
                        my ($self) = @_;
                        $RESULT = $self->zilla->name;
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
