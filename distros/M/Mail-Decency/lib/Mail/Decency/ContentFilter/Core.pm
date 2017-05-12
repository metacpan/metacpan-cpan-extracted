package Mail::Decency::ContentFilter::Core;

use Moose;
extends 'Mail::Decency::Core::Child';

use version 0.74; our $VERSION = qv( "v0.1.4" );

=head1 NAME

Mail::Decency::ContentFilter::Core

=head1 DESCRIPTION

Base class for all content filter


=head1 CLASS ATTRIBUTES

=head2 max_size : Int

Max size in bytes for an email to be checked.

=cut

has max_size => ( is => 'ro', isa => 'Int', default => 0 );

=head2 timeout : Int

Timeout for each policy module.

Default: 30

=cut

has timeout  => ( is => 'rw', isa => 'Int', default => 30 );

=head2 ArrayRef[Str] : Int

For easy module initialization, developers can set array of the config params. They will be set if they are defined.

    # do this
    has config_params => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [ qw/ something / ] } );
    
    # an it will be initialized
    $self->something( $self->config->{ something } )
        if defined $self->config->{ something };

=cut

has config_params => ( is => 'ro', isa => 'ArrayRef[Str]', predicate => 'has_config_params' );


=head1 METHODS

=head2 init

=cut

sub init {
    my ( $self ) = @_;
    
    # run pre-init phase
    $self->pre_init() if $self->can( 'pre_init' );
    
    # each filter might have a max size for files to be filtered
    if ( defined $self->config->{ max_size } ) {
        $self->max_size( $self->config->{ max_size } );
    }
    
    # set timeout
    $self->timeout( $self->config->{ timeout } )
        if defined $self->config->{ timeout };
    
    # having list of optional config params ?
    if ( $self->has_config_params ) {
        foreach my $attr( @{ $self->config_params } ) {
            $self->$attr( $self->config->{ $attr } )
                if $self->config->{ $attr };
        }
    }
    
}


=head2  session_data, file, file_size, from, to, mime

Convinient accessor to the server's session data 

=cut

sub session_data {
    return shift->server->session_data;
}

sub file {
    return shift->session_data->file;
}
sub file_size {
    return shift->session_data->file_size;
}
sub from {
    return shift->session_data->from;
}
sub to {
    return shift->session_data->to;
}
sub mime {
    return shift->session_data->mime;
}

=head2 write_mime

Write latest MIME data back to file

=cut

sub write_mime {
    return shift->session_data->write_mime;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
