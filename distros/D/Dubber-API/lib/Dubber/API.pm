package Dubber::API;

# ABSTRACT: Interact with the Dubber Call Recording platform API

use strict;
use warnings;

our $VERSION = '0.011'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Mouse;
use Method::Signatures;
use Cpanel::JSON::XS;
use Crypt::Digest::MD5 qw[md5_b64];
use Crypt::Digest::SHA256 qw[sha256_hex];
use DateTime;
use HTTP::Request;
use LWP::ConnCache;
use LWP::UserAgent;
use Try::Tiny;
use URI;

with 'Web::API';

# ------------------------------------------------------------------------


# ------------------------------------------------------------------------

has api_version => (
    is      => 'ro',
    isa     => 'Num',
    default => sub {'1'},
);

has region => (
    is      => 'ro',
    isa     => 'Str',
    default => sub {'sandbox'},
);

# ------------------------------------------------------------------------

has client_id       => (is => 'ro', isa=> 'Str', required => 1);
has client_secret   => (is => 'ro', isa=> 'Str', required => 1);
has auth_id         => (is => 'ro', isa=> 'Str', required => 1);
has auth_secret     => (is => 'ro', isa=> 'Str', required => 1);
has max_part_size   => (is => 'ro', isa=> 'Int', default => sub { 5 * 1024 * 1024});
# ------------------------------------------------------------------------
has _auth_token         => (is => 'rw', isa => 'Str', predicate => '_has_auth_token', clearer => 'clear_auth_token',);
has _auth_refresh_token => (is => 'rw', isa => 'Str',);
has _auth_token_expiry  => (is => 'rw', isa => 'DateTime',);

method _new_auth_token ($refresh_token?) {
    my $uri = URI->new( $self->base_url . '/token' );
    my $request = HTTP::Request->new( 'POST', $uri );
    $request->header(
        'Accept'       => 'application/json',
        'Content-type' => 'application/x-www-form-urlencoded'
    );

    # token request content
    my $content = { client_id => $self->client_id, client_secret => $self->client_secret };
    if ($refresh_token) {

        # refresh request content...
        $content->{refresh_token} = $refresh_token;
        $content->{grant_type}    = 'refresh_token';
    }
    else {
        $content->{username}   = $self->auth_id;
        $content->{password}   = $self->auth_secret;
        $content->{grant_type} = 'password';
    }
    $request->content( $self->encode( $content, 'application/x-www-form-urlencoded' ) );

    # send and decode query
    $self->_clear_state;
    my $response = $self->request($request);
    my $answer   = $self->format_response($response);
    $self->_clear_state;

    # unpack components
    $self->_auth_token( $answer->{content}{access_token} );
    $self->_auth_refresh_token( $answer->{content}{refresh_token} );
    $self->_auth_token_expiry( DateTime->now->add( seconds => $answer->{content}{expires_in} - 20 ) );

    # return the token
    return $answer->{content}{access_token};
}

# ------------------------------------------------------------------------
method is_authenticated () {
    return 1 if ( ( $self->_has_auth_token ) and ( DateTime->now < $self->_auth_token_expiry ) );
    return;
}

# ------------------------------------------------------------------------
method auth_token () {
    if ( $self->_has_auth_token ) {
        if ( DateTime->now > $self->_auth_token_expiry ) {
            $self->_new_auth_token( $self->_auth_refresh_token );
        }
    }
    else {
        $self->_new_auth_token();
    }
    return $self->_auth_token;
}

# ------------------------------------------------------------------------
method auth_lifetime_seconds () {
    return 0 unless ( $self->is_authenticated );
    my $diff = $self->_auth_token_expiry->delta_ms( DateTime->now );
    return ( abs( $diff->minutes * 60 ) + abs( $diff->seconds ) );
}

# ------------------------------------------------------------------------
has header => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

method _build_header () {
    return { Authorization => 'Bearer ' . $self->auth_token };
}

# ------------------------------------------------------------------------
has connection_cache => (
    is         => 'ro',
    isa        => 'LWP::ConnCache',
    lazy_build => 1,
);

method _build_connection_cache () { return LWP::ConnCache->new( total_capacity => 5 ); }

# ------------------------------------------------------------------------
has json_coder => (
    is         => 'ro',
    isa        => 'Cpanel::JSON::XS',
    lazy_build => 1,
);

method _build_json_coder () { return Cpanel::JSON::XS->new->utf8; }

# ------------------------------------------------------------------------
has endpoints => (
    is      => 'ro',
    default => sub {
        {   root => { path => '/' },

            # Group Methods (Group Authentication Required)
            get_group_details                 => { path => 'groups/:group_id' },
            get_group_accounts                => { path => 'groups/:group_id/accounts' },
            create_child_group                => { path => 'groups/:group_id/groups', method => 'POST' },
            create_account                    => { path => 'accounts', method => 'POST' },
            get_group_unidentified_recordings => { path => 'groups/:group_id/unidentified_recordings' },
            create_group_unidentified_recording =>
                { path => 'groups/:group_id/unidentified_recordings', method => 'POST' },

            # Account Methods
            get_account_details    => { path => 'accounts/:account_id' },
            update_account_details => { path => 'accounts/:account_id', method => 'PUT' },

            # Recording Methods
            get_account_recordings    => { path => 'accounts/:account_id/recordings',   method => 'GET' },
            create_recording          => { path => 'accounts/:account_id/recordings',   method => 'POST' },
            get_recording_details     => { path => 'recordings/:recording_id',          method => 'GET' },
            get_recording_waveform    => { path => 'recordings/:recording_id/waveform', method => 'GET' },
            delete_recording          => { path => 'recordings/:recording_id',          method => 'DELETE' },
            update_recording_metadata => { path => 'recordings/:recording_id/metadata', method => 'PUT' },
            add_recording_tags        => { path => 'recordings/:recording_id/tags',     method => 'POST' },
            delete_recording_tags     => { path => 'recordings/:recording_id/tags',     method => 'DELETE' },

            # Multipart Recording Methods
            create_multipart_recording => { path => 'accounts/:account_id/recordings', method => 'POST' },
            get_recording_upload_part  => {
                path   => 'recordings/:recording_id/upload',
                method => 'GET',

                #mandatory => [qw(part_number content_md5 content_sha256)]
            },
            put_complete_multipart_recording_upload =>

                #{ path => 'recordings/:recording_id/complete_upload', method => 'PUT', mandatory => [qw(parts)] },
                { path => 'recordings/:recording_id/complete_upload', method => 'PUT', },
            abort_multipart_recording_upload => { path => 'recordings/:recording_id', method => 'DELETE' },

            # User Methods
            get_account_users   => { path => 'accounts/:account_id/users', method => 'GET' },
            create_account_user => { path => 'accounts/:account_id/users', method => 'POST' },
            get_user_details    => { path => 'users/:user_id',             method => 'GET' },
            delete_user         => { path => 'users/:user_id',             method => 'DELETE' },
            update_user         => { path => 'users/:user_id',             method => 'PUT' },

            # Profile Methods
            get_profile => { path => 'profile', method => 'GET' },

            # Notification (Rest Hook) Methods
            create_group_notification => { path => 'groups/:group_id/notifications', method => 'POST' }
            ,    # (Group Authentication Only)
            get_group_notifications => { path => 'groups/:group_id/notifications', method => 'GET' }
            ,    # (Group Authentication Only)
            create_account_notification    => { path => 'accounts/:account_id/notifications',       method => 'POST' },
            get_account_notifications      => { path => 'accounts/:account_id/notifications',       method => 'GET' },
            get_notification_details       => { path => 'notifications/:notification_id',           method => 'GET' },
            update_notification            => { path => 'notifications/:notification_id',           method => 'PUT' },
            activate_notification          => { path => 'notifications/:notification_id/activate',  method => 'POST' },
            release_unclaimed_notification => { path => 'notifications/:notification_id/unclaimed', method => 'GET' },
            delete_notification => { path => 'notifications/:notification_id', method => 'DELETE' },

            # Dub.Point (Group Authentication Required)
            get_group_unidentified_dub_points =>
                { path => 'groups/:group_id/unidentified_dub_points', method => 'GET' },
            get_account_dub_points   => { path => 'accounts/:account_id/dub_points', method => 'GET' },
            create_account_dub_point => { path => 'accounts/:account_id/dub_points', method => 'POST' },
            get_dub_point_details    => { path => 'dub_points/:dub_point_id',        method => 'GET' },
            find_dub_point           => {
                path      => 'dub_points/find',
                method    => 'GET',
                mandatory => [qw(external_type service_provider external_group external_identifier)]
            },

            # OAuth 2 Methods
            revoke_access_token => { path => 'revoke', method => 'POST' },

        };
    },
);

method commands () { return $self->endpoints; }

# ------------------------------------------------------------------------
method upload_recording_mp3_file ($account_id, $call_metadata, $mp3_file_or_data) {
    my @data_parts = $self->_split_recording_data($mp3_file_or_data);

    # create the recording object
    my $res = $self->create_recording( account_id => $account_id, %{$call_metadata} );
    if ( $res->{code} eq '201' ) {
        my $recording_id = $res->{content}{id};
        my $return_status;
        try {
            my @etag_parts;
            my $part_number = 0;
            foreach my $part_data (@data_parts) {
                my $md5_b64    = md5_b64($part_data);
                my $sha256_hex = sha256_hex($part_data);
                ++$part_number;

                # request to upload a recording part
                my $upload_req_res = $self->get_recording_upload_part(
                    recording_id   => $recording_id,
                    part_number    => $part_number,
                    content_md5    => $md5_b64,
                    content_sha256 => $sha256_hex
                );
                if ( $upload_req_res->{code} eq '200' ) {

                    # upload the recording part
                    my $put_uri = URI->new( $upload_req_res->{content}{url} );
                    my $put_request = HTTP::Request->new( 'PUT', $put_uri );
                    $put_request->header(
                        'Accept'               => 'application/json',
                        'Content-type'         => 'audio/mpeg',                                # apparently right!
                        'Authorization'        => $upload_req_res->{content}{authorization},
                        'X-Amz-Date'           => $upload_req_res->{content}{'X-Amz-Date'},
                        'Host'                 => $upload_req_res->{content}{Host},
                        'Content-Md5'          => $md5_b64,
                        'X-Amz-Content-Sha256' => $sha256_hex
                    );
                    $put_request->content($part_data);
                    my $put_response = $self->request($put_request);
                    if ( $put_response->is_success ) {
                        push( @etag_parts, { part_number => $part_number, e_tag => $put_response->header('ETag') } );
                    }
                    else {
                        die "Unable to PUT recording upload - $!";
                    }
                }
                else {
                    die "Unable to request recording upload - $!";
                }
            }
            $return_status = $self->put_complete_multipart_recording_upload(
                recording_id => $recording_id,
                parts        => \@etag_parts
            );
        }
        catch {
            # it failed - delete the part uploaded chunk
            $self->abort_multipart_recording_upload( recording_id => $recording_id );
        };
        return $return_status;
    }
    return $res;
}

# ------------------------------------------------------------------------
method _split_recording_data ($file_or_data) {
    my $data;
    if ( ref($file_or_data) and $file_or_data->isa('Path::Tiny') ) {
        my $stat = $file_or_data->stat or die "File $file_or_data does not exist - $!\n";
        $data = $file_or_data->slurp_raw;
    }
    else {
        $data = $file_or_data;
    }

    # split into chunks of $max_part_size
    my $template =
        sprintf( 'A%d', $self->max_part_size ) x int( length($data) / $self->max_part_size )
        . ( length($data) % $self->max_part_size )
        ? 'A*'
        : '';
    my @chunks = unpack( $template, $data );
    return @chunks;
}

# ------------------------------------------------------------------------
method BUILD ($args) {
    $self->user_agent( __PACKAGE__ . ' ' . ( $Dubber::API::VERSION || '' ) );
    $self->base_url( 'https://api.dubber.net/' . $self->region . '/v' . $self->api_version );
    $self->content_type('application/json');
    $self->decoder( sub { $self->json_coder->decode( shift || '{}' ) } );
}

# ------------------------------------------------------------------------
method _build_agent () {
    return LWP::UserAgent->new(
        agent      => $self->user_agent,
        cookie_jar => $self->cookies,
        timeout    => $self->timeout,
        con_cache  => $self->connection_cache,
        keep_alive => 1,
        ssl_opts   => { verify_hostname => $self->strict_ssl },
    );
}

# ------------------------------------------------------------------------
method _clear_state () { $self->clear_decoded_response; $self->clear_response; }

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dubber::API - Interact with the Dubber Call Recording platform API

=head1 VERSION

version 0.011

This is undocumented to an amazing degree at present!

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
