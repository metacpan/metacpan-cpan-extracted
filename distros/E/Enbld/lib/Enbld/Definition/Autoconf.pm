package Enbld::Definition::Autoconf;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{WebSite}      = 'http://www.gnu.org/software/autoconf/';

    $self->{defined}{DownloadSite} = 'http://ftp.gnu.org/gnu/autoconf/';

    $self->{defined}{ArchiveName}  = 'autoconf';
    $self->{defined}{VersionForm}  = '2\.\d{1,2}';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Autoconf - definition module for GNU Autoconf

=head1 SEE ALSO

L<GNU Autoconf|http://www.gnu.org/software/autoconf/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
