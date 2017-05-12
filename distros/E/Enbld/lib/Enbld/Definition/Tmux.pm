package Enbld::Definition::Tmux;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

sub initialize {
    my $self = shift;

    $self->SUPER::initialize;

    $self->{defined}{DarwinArgument}    =  \&set_argument;
    $self->{defined}{ArchiveName}       =   'tmux';
    $self->{defined}{WebSite}           =   'http://tmux.sourceforge.net';
    $self->{defined}{VersionForm}       =   '\d\.\d';
    $self->{defined}{Dependencies}      =   [ 'pkgconfig', 'libevent' ];
    $self->{defined}{DownloadSite}      =
        'http://sourceforge.net/projects/tmux/files/tmux/';

    $self->{defined}{IndexParserForm}   =   \&set_index_parser_form;
    $self->{defined}{URL}               =   \&set_URL;

    $self->{defined}{TestAction}        =   'test';

    $self->{defined}{CommandConfigure}  =   'sh configure';

    return $self;
}

sub set_argument {

    require Enbld::Home;
    my $path = File::Spec->catdir(
            Enbld::Home->install_path,
            'lib',
            'pkgconfig'
            );

    my $env = 'PKG_CONFIG_PATH=' . $path;

    return $env;
}

sub set_index_parser_form {
    my $attributes = shift;

    my $index_form = quotemeta( $attributes->ArchiveName ) . '-' .
                $attributes->VersionForm;

    my $index_parser_form = '<a href="/projects/tmux/files/tmux/' .
        $index_form . '/stats/timeline"';

    return $index_parser_form;
}

sub set_URL {
    my $attributes = shift;

    my $dir  = $attributes->ArchiveName . '-' . $attributes->Version;
    my $file = $attributes->ArchiveName . '-' . $attributes->Version .
        '.' . $attributes->Extension;

    my $url = $attributes->DownloadSite . $dir . '/' . $file . '/download';

    return $url;
}

1;

=pod

=head1 NAME

Enbld::Definition::Tmux - definition module for Tmux

=head1 SEE ALSO

L<tmux|http://tmux.sourceforge.net>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
