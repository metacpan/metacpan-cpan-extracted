package Enbld::Definition::Git;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{DownloadSite}      =
        'https://www.kernel.org/pub/software/scm/git/';
    $self->{defined}{ArchiveName}       =   'git';
    $self->{defined}{WebSite}           =   'http://git-scm.com';
    $self->{defined}{VersionForm}       =   '\d\.\d\.\d{1,2}(\.\d{1,2})?';

    $self->{defined}{AdditionalArgument} = '--without-tcltk';

    $self->{defined}{TestAction}        =   'test';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Git - definition module for git

=head1 SEE ALSO

L<git|http://git-scm.com>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
