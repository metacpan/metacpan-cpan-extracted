package Enbld::Definition::Pkgconfig;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'pkg-config';
    $self->{defined}{WebSite}           =
        'http://www.freedesktop.org/wiki/Software/pkg-config/';
    $self->{defined}{VersionForm}       =   '\d\.\d{1,2}(?:\.\d)?';
    $self->{defined}{DownloadSite}      =
        'http://pkgconfig.freedesktop.org/releases/';

    $self->{defined}{AdditionalArgument} = '--with-internal-glib';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Pkgconfig - definition module for pkg-config

=head1 SEE ALSO

L<pkg-config|http://www.freedesktop.org/wiki/Software/pkg-config/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
