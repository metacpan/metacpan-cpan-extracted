package Enbld::Definition::Libevent;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{ArchiveName}       =   'libevent';
    $self->{defined}{WebSite}           =   'http://libevent.org';
    $self->{defined}{VersionForm}       =   '\d\.\d\.\d{1,2}';
    $self->{defined}{IndexSite}         =
        'http://libevent.org/old-releases.html';
    $self->{defined}{DownloadSite}      =
        'https://github.com/downloads/libevent/libevent/';
    $self->{defined}{IndexParserForm}   =   \&set_index_parser_form;
    $self->{defined}{Filename}          =   \&set_filename;

    $self->{defined}{TestAction}        =   'verify';

    return $self;
}

sub set_filename {
    my $attributes = shift;

    my $filename = $attributes->ArchiveName . '-' . $attributes->Version .
        '-stable.' . $attributes->Extension;

    return $filename;
}

sub set_index_parser_form {
    my $attributes = shift;

    my $parser = 'href="' .quotemeta( $attributes->DownloadSite ). 
        quotemeta( $attributes->ArchiveName ). '-' . $attributes->VersionForm .
        '-stable.' . quotemeta( $attributes->Extension ) . '">';

    return $parser;
}

1;

=pod

=head1 NAME

Enbld::Definition::Libevent - definition module for libevent

=head1 SEE ALSO

L<libevent|http://libevent.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
