package Enbld::Definition::Hello;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{WebSite}      = 'http://www.gnu.org/software/hello/';

    $self->{defined}{DownloadSite} = 'http://ftp.gnu.org/gnu/hello/';
    $self->{defined}{ArchiveName}  = 'hello';
    $self->{defined}{VersionForm}  = '\d\.\d';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Hello - definition module for GNU Hello

=head1 SEE ALSO

L<GNU Hello|http://www.gnu.org/software/hello/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
