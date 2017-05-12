package Enbld::Definition::Libidn;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{WebSite}      = 'http://www.gnu.org/software/libidn/';
    $self->{defined}{DownloadSite} = 'http://ftp.gnu.org/gnu/libidn/';

    $self->{defined}{ArchiveName}  = 'libidn';
    $self->{defined}{VersionForm}  = '1\.\d{1,2}';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Libidn - definition module for GNU IDN Library

=head1 SEE ALSO

L<GNU IDN Library|http://www.gnu.org/software/libidn/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
