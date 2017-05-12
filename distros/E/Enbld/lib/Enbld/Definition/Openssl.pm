package Enbld::Definition::Openssl;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'openssl';
    $self->{defined}{WebSite}           =   'http://www.openssl.org/';
    $self->{defined}{VersionForm}       =   '\d\.\d\.\d\w?';
    $self->{defined}{DownloadSite}      =   'http://www.openssl.org/source/';

    $self->{defined}{DarwinArgument}    =   'darwin64-x86_64-cc';

    $self->{defined}{SortedVersionList} =   \&set_sorted_version_list;

    $self->{defined}{TestAction}        =   'test';

    $self->{defined}{CommandConfigure}  =   \&set_commandconfigure;

    return $self;
}

sub set_commandconfigure {
    return $^O eq 'darwin' ? './configure' : './config';
}

sub set_sorted_version_list {
    my $attributes = shift;

    my $list = $attributes->VersionList;

    my @sorted = sort { $a cmp $b } @{ $list };

    return \@sorted;
}

1;

=pod

=head1 NAME

Enbld::Definition::Openssl - definition module for OpenSSL

=head1 SEE ALSO

L<OpenSSL|http://www.openssl.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
