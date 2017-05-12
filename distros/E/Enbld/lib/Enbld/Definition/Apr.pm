package Enbld::Definition::Apr;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{WebSite}      = 'http://apr.apache.org';

    $self->{defined}{DownloadSite} = 'http://archive.apache.org/dist/apr/';

    $self->{defined}{ArchiveName}  = 'apr';
    $self->{defined}{VersionForm}  = '\d\.\d\.\d{1,2}';

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Apr - definition module for The Apache Portable Runtime Project

=head1 SEE ALSO

L<The Apache Portable Runtime Project|http://apr.apache.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
