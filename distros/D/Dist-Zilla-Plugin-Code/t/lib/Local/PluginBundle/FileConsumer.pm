package Local::PluginBundle::FileConsumer;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::PluginBundle';

use Dist::Zilla::File::InMemory;

our $RESULT;

use namespace::autoclean;

sub bundle_config {
    my ( $class, $section ) = @_;

    my $plugin_class = $section->{payload}{plugin};
    my $plugin_name  = $section->{payload}{name};
    my $input        = $section->{payload}{input};
    my $code         = $section->{payload}{code};
    $RESULT = undef;

    return [
        $plugin_name,
        $plugin_class,
        {
            $code => [
                sub {
                    my ($self) = @_;
                    $self->log($input);
                    $RESULT = $input * $input;
                    my @modules = grep { $_->name =~ m{ ^ lib/file- [23] .* [.] pm }xsm } @{ $self->zilla->files };
                    return \@modules;
                },
            ],
        },
      ],
      [
        '=Local::FileConsumer',
        'Local::FileConsumer',
        { finder => "$plugin_name" },
      ];
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
