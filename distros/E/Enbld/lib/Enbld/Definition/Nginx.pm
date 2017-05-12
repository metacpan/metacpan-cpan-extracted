package Enbld::Definition::Nginx;

use strict;
use warnings;

use parent qw/Enbld::Definition/;

use File::Spec;

sub initialize {
    my $self = shift;
    
    $self->SUPER::initialize;
    
    $self->{defined}{ArchiveName}       =   'nginx';
    $self->{defined}{WebSite}           =   'http://nginx.org';
    $self->{defined}{VersionForm}       =   '1\.\d\.\d{1,2}';
    $self->{defined}{DownloadSite}      =   'http://nginx.org/download/';
    
    $self->{defined}{AdditionalArgument}=   \&set_argument;
    
    $self->{defined}{CommandConfigure}  =   './configure';
    $self->{defined}{CommandTest}       =   '';

    return $self;
}

sub set_argument {
    my $attributes = shift;

    require Enbld::Definition;
    my $pcre = Enbld::Definition->new( 'pcre' )->parse;
    $pcre->add( 'VersionCondition', 'latest' );

    require Enbld::HTTP;
    require Enbld::Home;
    my $path = File::Spec->catfile( Enbld::Home->dists, $pcre->Filename );
    my $archivefile = Enbld::HTTP->download_archivefile( $pcre->URL, $path );
    my $build = $archivefile->extract( Enbld::Home->build );

    my $argument = "--with-http_ssl_module --with-pcre=" . $build;

    require Enbld::Feature;
    if ( ! Enbld::Feature->is_deploy_mode ) {
        $argument .= ' --user=nginx';
        $argument .= ' --group=nginx';
        $argument .= ' --pid-path='       .
            File::Spec->catfile( Enbld::Home->log, 'nginx.pid' );
        $argument .= ' --error-log-path=' .
            File::Spec->catfile( Enbld::Home->log, 'error.log' );
        $argument .= ' --http-log-path='  .
            File::Spec->catfile( Enbld::Home->log, 'access.log' );
        $argument .= ' --conf-path='      .
            File::Spec->catfile( Enbld::Home->conf, 'nginx.conf' );
    }

    return $argument;
}

1;

=pod

=head1 NAME

Enbld::Definition::Nginx - definition module for nginx

=head1 SEE ALSO

L<nginx|http://nginx.org>

L<Enbld::Definition>

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
