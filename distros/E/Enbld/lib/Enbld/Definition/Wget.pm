package Enbld::Definition::Wget;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{WebSite}           =   'http://www.gnu.org/software/wget/';

    $self->{defined}{Dependencies}      =   [ 'libidn' ];

    $self->{defined}{DownloadSite}      =   'http://ftp.gnu.org/gnu/wget/';

    $self->{defined}{ArchiveName}       =   'wget';
    $self->{defined}{VersionForm}       =   '\d{1,2}\.\d{1,2}(\.\d{1,2})?';
    
    $self->{defined}{DarwinArgument}    =   \&set_argument;
    $self->{defined}{DefaultArgument}   =   '--with-ssl=openssl --enable-iri';

    return $self;
}

sub set_argument {
    my $attributes = shift;
    
    require Enbld::Home;
    my $to_install = Enbld::Home->library;

    my $argument = "--with-ssl=openssl --enable-iri --with-libidn=$to_install";

    $argument .= ' ' . 'PERL=/usr/bin/perl POD2MAN=/usr/bin/pod2man';

    return $argument;
}

1;

=pod

=head1 NAME

Enbld::Definition::Wget - definition module for GNU Wget

=head1 SEE ALSO

L<GNU Wget|http://www.gnu.org/software/wget/>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
