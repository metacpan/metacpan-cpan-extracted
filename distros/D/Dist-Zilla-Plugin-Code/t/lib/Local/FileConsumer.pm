package Local::FileConsumer;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose;
with(
    'Dist::Zilla::Role::AfterBuild',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => ['ThisPluginDoesNotExist'],
    },
);

our $RESULT;

use namespace::autoclean;

sub after_build {
    my ($self) = @_;

    for my $file ( @{ $self->found_files } ) {
        push @{$RESULT}, $file->name;
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
