package Mail::Decency::ContentFilter::ClamAV;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Core
/;
with qw/
    Mail::Decency::ContentFilter::Core::Virus
/;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use mro 'c3';
use Data::Dumper;
use ClamAV::Client;
use Scalar::Util qw/ blessed /;

=head1 NAME

Mail::Decency::ContentFilter::ClamAV

=head1 DESCRIPTION

Checks mails against clamav

=head1 CONFIG

    ---
    
    disable: 0
    #max_size: 0
    #timeout: 30
    
    # hostname / ip of clamav server
    #host: '127.0.0.1'
    #port: 12345
    
    # or use unix socket (path)
    path: /var/run/clamav/clamd.ctl
    

=head1 CLASS ATTRIBUTES

=head2 clamav : ClamAV::Client

Instance of L<ClamAV::Client>

=cut

has clamav => ( is => 'rw', isa => 'ClamAV::Client' );

=head1 METHODS

=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    $self->next::method();
    
    if ( $self->config->{ host } ) {
        die ref( $self ).": Require port in config if using host\n"
            unless $self->config->{ port };
        $self->clamav( ClamAV::Client->new(
            socket_host => $self->config->{ host },
            socket_port => $self->config->{ port },
        ) );
    }
    elsif ( $self->config->{ path } ) {
        $self->clamav( ClamAV::Client->new(
            socket_name => $self->config->{ path },
        ) );
    }
    else {
        die ref( $self ). ": Require either host and port OR path\n";
    }
}


=head2 handle

=cut

sub handle {
    my ( $self ) = @_;
    
    my $result;
    eval {
        open my $fh, '<', $self->file;
        $result = $self->clamav->scan_stream( $fh );
        close $fh;
    };
    
    if ( $@ ) {
        if ( blessed( $@ ) && $@->isa( 'ClamAV::Client::Error' ) ) {
            $self->logger->error( "Error connecting to clamav: $@" );
        }
        else {
            $self->logger->error( "Error occured: $@" );
        }
    }
    
    if ( $result ) {
        $self->logger->info( sprintf(
            'Found Virus in mail from %s to %s: %s',
            $self->from, $self->to, $result
        ) );
        return $self->found_virus( $result );
    }
    
    # return ok
    return ;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
