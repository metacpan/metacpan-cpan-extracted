package Enbld::Definition::Python;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'Python';
    $self->{defined}{WebSite}           =   'http://www.python.org';
    $self->{defined}{VersionForm}       =   '\d\.\d(\.\d)?';
    $self->{defined}{Extension}         =   'tgz';
    $self->{defined}{DownloadSite}      =   'http://www.python.org/ftp/python/';

    $self->{defined}{VersionList}       =   \&set_versionlist;
    $self->{defined}{URL}               =   \&set_url;

    $self->{defined}{TestAction}        =   'test';

    return $self;
}

sub set_versionlist {
    my $attributes = shift;

    require Enbld::HTTP;
    my $first_html = Enbld::HTTP->get_html( $attributes->IndexSite );

    my $first_list = $first_html->parse_version(
            quotemeta( '<a href="') . '\d\.\d(\.\d)?' . quotemeta( '/">' ),
            '\d\.\d(\.\d)?'
            );

    my $versionlist;
    for my $ver_num ( @{ $first_list } ) {
        my $url = $attributes->IndexSite . $ver_num;
        my $html = Enbld::HTTP->get_html( $url );

        my $list = $html->parse_version(
            quotemeta( '<a href="Python-' ) .
            '\d\.\d(\.\d)?' . quotemeta( '.tgz' ) . quotemeta( '">' ) .
            quotemeta( 'Python-' ) .
            '\d\.\d(\.\d)?' . quotemeta( '.tgz</a>' ),
            '\d\.\d(\.\d)?'
            );

        if ( $list ) {
            push @{ $versionlist }, $ver_num;
        }

    }

    return $versionlist;
}

sub set_url {
    my $attributes = shift;

    my $ver = $attributes->Version;

    my $filename = $attributes->Filename;
    my $url = $attributes->DownloadSite . $ver . '/' . $filename;

    return $url;
}

1;

=pod

=head1 NAME

Enbld::Definition::Python - definition module for Python Programming Language

=head1 SEE ALSO

L<Python Programming Language|http://www.python.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
