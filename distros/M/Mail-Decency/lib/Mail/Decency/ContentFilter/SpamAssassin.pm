package Mail::Decency::ContentFilter::SpamAssassin;

use Moose;
extends qw/
    Mail::Decency::ContentFilter::Core
/;
with qw/
    Mail::Decency::ContentFilter::Core::User
    Mail::Decency::ContentFilter::Core::Spam
    Mail::Decency::ContentFilter::Core::WeightTranslate
/;

use version 0.74; our $VERSION = qv( "v0.1.6" );

use mro 'c3';
use Data::Dumper;
use Mail::SpamAssassin::Client;
use File::Temp qw/ tempfile /;

=head1 NAME

Mail::Decency::ContentFilter::SpamAssassin

=head1 DESCRIPTION

Filter messages through spamc and translate results

=head2 CONFIG

    ---
    
    disable: 0
    #max_size: 0
    #timeout: 30
    
    cmd_check: '/usr/bin/spamc -u %user% --headers'
    

=head1 CLASS ATTRIBUTES


=head2 host

Spamassassin host .. use this or socket

=cut

has host => (
    is      => 'rw',
    isa     => 'Str',
    default => 'localhost'
);


=head2 port

Spamassassin port .. if host is used

=cut

has port => (
    is      => 'rw',
    isa     => 'Int',
    default => 783
);


=head2 socket

Spamassassin socket .. instead of host and port

=cut

has socket => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_socket'
);


=head1 METHODS


=head2 pre_init

=cut

sub pre_init {
    my ( $self ) = @_;
    push @{ $self->{ config_params } ||=[] }, qw/ host port socket /;
    return ;
}


=head2 handle

Use L<Mail::SpamAssassin::Client> to retreive filter result from SpamAssassin

=cut

sub handle {
    my ( $self ) = @_;
    
    my $client = $self->get_client();
    return unless $client;
    
    # process mail
    my $ref = $client->process( $self->mime->stringify );
    
    # no result ?
    unless ( $ref ) {
        $self->logger->error( "Failed to receive result from spamd" );
        return ;
    }
    
    # calc weight
    my $weight = 0;
    
    # use scoring ?
    if ( $self->has_weight_translate ) {
        $weight = $self->translate_weight( $ref->{ score } );
    }
    
    # is HAM ?
    elsif ( $ref->{ isspam } eq 'False' ) {
        $weight = $self->weight_innocent;
    }
    
    # is SPAM..
    else {
        $weight = $self->weight_spam;
    }
    $self->logger->debug0( "Score mail to '$weight'" );
    
    # get header
    my ( $last_header, %header ) = ();
    foreach my $l( split( /\n/, $ref->{ message } ) ) {
        if ( $l =~ /^X-Spam-(\S+):\s*(.*?)$/ ) {
            ( $last_header, my $value ) = ( $1, $2 );
            $header{ $last_header } = $value;
        }
        elsif ( $last_header && $l =~ /^\s+(.+?)$/ ) {
            $header{ $last_header } .= $1;
        }
        else {
            last;
        }
    }
    
    # add weight to content filte score
    return $self->add_spam_score( $weight, [
        "SpamAssassin Status: ". ( $header{ Status } || "UNKNOWN" )
    ] );
}


=head2 train

Train mails into SpamAssassin

=cut

sub train {
    my ( $self, $mode ) = @_;
    
    die "Train mode has to be 'spam' or 'ham'\n"
        unless $mode eq 'spam' || $mode eq 'ham';
    
    my $client = $self->get_client();
    return ( 0, undef, 1 ) unless $client;
    
    my $learned = $client->learn( $self->mime->stringify, $mode eq 'spam' ? 0 : 1 );
    return ( $learned, "OK", 0 );
}


=head2 get_client

Creates instance of L<Mail::SpamAssassin::Client> and returns it

=cut

sub get_client {
    my ( $self ) = @_;
    
    my $user = $self->get_user();
    my $client;
    eval {
        $client = $self->has_socket
            ? Mail::SpamAssassin::Client->new( {
                socketpath => $self->socket,
                user => $user
            } )
            : Mail::SpamAssassin::Client->new( {
                host => $self->host,
                port => $self->port,
                user => $user
            } )
        ;
    };
    
    # errro setup client
    if ( $@ ) {
        warn "> ERR $@\n";
        $self->logger->error( "Error connecting to spamd: $@" );
        return;
    }
    elsif ( ! $client ) {
        warn "> OOPS \n";
        $self->logger->error( "Could not create SpamAssassin client" );
        return;
    }
    
    # cannotping spamd
    unless ( $client->ping ) {
        $self->logger->error( "Cannot ping spamd. Down ?" );
        return ;
    }
    
    return $client;
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut


1;
