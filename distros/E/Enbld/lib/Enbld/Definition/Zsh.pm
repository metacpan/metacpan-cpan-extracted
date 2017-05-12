package Enbld::Definition::Zsh;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{ArchiveName}     = 'zsh';
    $self->{defined}{WebSite}         = 'http://www.zsh.org';
    $self->{defined}{VersionForm}     = '\d\.\d\.\d';
    $self->{defined}{DownloadSite}    = 'http://sourceforge.net/projects/zsh/files/zsh/';

    $self->{defined}{IndexParserForm} = \&set_index_parser_form;
    $self->{defined}{URL}             = \&set_URL;

    return $self;
}

sub set_index_parser_form {
    my $attributes = shift;

    my $index_parser_form = '<a href="/projects/zsh/files/zsh/' .
        $attributes->VersionForm .'/"';

    return $index_parser_form;
}

sub set_URL {
    my $attributes = shift;

    my $site = 'http://sourceforge.net/projects/zsh/files/zsh/';

    my $dir  = $attributes->Version;
    my $file = $attributes->ArchiveName . '-' . $attributes->Version .
        '.' . $attributes->Extension;

    my $url = $site . $dir . '/' . $file . '/download';

    return $url;
}

1;

=pod

=head1 NAME

Enbld::Definition::Zsh - definition module for Zsh

=head1 SEE ALSO

L<Zsh|http://www.zsh.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
