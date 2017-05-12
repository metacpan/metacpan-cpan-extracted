package inc::MungeImageLinks;

use strict;
use warnings;
use namespace::autoclean;

use Moose;

with 'Dist::Zilla::Role::FileMunger';

sub munge_file {
    my $self = shift;
    my $file = shift;

    return unless $file->name =~ m{lib/Meta/Grapher/Moose\.pm};

    my $release
        = ( $self->zilla->plugin_named('@DROLSKY/Authority')->authority
            =~ s/^cpan://r )
        . q{/}
        . $self->zilla->name . q{-}
        . $self->zilla->version;
    $file->content( $file->content =~ s/\{dist-release}/$release/gr );

    return;
}

__PACKAGE__->meta->make_immutable;

1;
