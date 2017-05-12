package Enbld::Definition::Libyaml;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{WebSite}      = 'http://pyyaml.org/wiki/LibYAML';
    $self->{defined}{DownloadSite} = 'http://pyyaml.org/download/libyaml/';

    $self->{defined}{ArchiveName}  = 'yaml';
    $self->{defined}{VersionForm}  = '\d\.\d\.\d';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Libyaml - definition module for LibYAML

=head1 SEE ALSO

L<LibYAML - PyYAML|http://pyyaml.org/wiki/LibYAML>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
