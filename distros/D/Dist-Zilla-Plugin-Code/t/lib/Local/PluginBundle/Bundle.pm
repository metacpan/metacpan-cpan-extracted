package Local::PluginBundle::Bundle;

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

    my $bundle_name = $section->{payload}{name};
    my $input       = $section->{payload}{input};
    $RESULT = undef;

    return [
        $bundle_name,
        'Dist::Zilla::PluginBundle::Code',
        {
            bundle_config => sub {
                my ($self) = @_;

                print ">>$input<<\n";
                print '}}' . $self->payload->{test_data} . "{{\n";
                $RESULT = $input * $input;

                return;
            },
            test_data => "A${input}Z",
        },
    ];
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
