package Enbld::Definition::Automake;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{WebSite}      = 'http://www.gnu.org/software/automake/';
    $self->{defined}{DownloadSite} = 'http://ftp.gnu.org/gnu/automake/';

    $self->{defined}{ArchiveName}  = 'automake';
    $self->{defined}{VersionForm}  = '1\.\d{1,2}(\.\d{1,2})?';

    $self->{defined}{Dependencies} = sub { return [ 'autoconf' ] };

    return $self;
}

1;

=pod

=head1 NAME

Enbld::Definition::Automake - definition module for GNU Automake

=head1 SEE ALSO

L<GNU Automake|http://www.gnu.org/software/automake/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
