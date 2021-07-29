package Local::PluginBundle::RetVal;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::PluginBundle';

our $RESULT;

use namespace::autoclean;

sub bundle_config {
    my ( $class, $section ) = @_;

    my $plugin_class = $section->{payload}{plugin};
    my $plugin_name  = $section->{payload}{name};
    my $code         = $section->{payload}{code};
    my $retval       = $section->{payload}{retval};
    $RESULT = undef;

    return [
        $plugin_name,
        $plugin_class,
        {
            $code => sub {
                my ($self) = @_;
                $self->log("Name = $retval");
                return $retval;
            },
        },
      ],
      [
        'SayMyName',
        'Dist::Zilla::Plugin::Code::BeforeBuild',
        {
            before_build => sub {
                my ($self) = @_;
                $RESULT = $self->zilla->name;
                return;
            },
        },
      ];
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
