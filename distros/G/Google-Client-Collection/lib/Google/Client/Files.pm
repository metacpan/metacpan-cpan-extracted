package Google::Client::Files;
$Google::Client::Files::VERSION = '0.005';
use Moo;
with qw/
Google::Client::Role::Token
Google::Client::Role::FurlAgent
/;

use Carp;
use Cpanel::JSON::XS;

has base_url => (
    is => 'ro',
    default => 'https://www.googleapis.com/drive/v3/files'
);

sub copy {
    my ($self, $id, $params, $content) = @_;
    confess("No fileId provided") unless ($id);

    $content = $content ? encode_json($content) : undef;

    my $url = $self->_url("/$id/copy", $params);
    my $json = $self->_request(
        method => 'POST',
        url => $url,
        content => $content
    );
    return $json;
}

sub create {
    my ($self, $params, $content) = @_;
    unless ( $content && %$content ) {
        confess("No content provided to create a media upload");
    }
    my $url = $self->_url('/drive/v3/files', $params);
    my $json = $self->_request(
        method => 'POST',
        url => $url,
        content => encode_json($content)
    );
    return $json;
}

sub create_media {
    my ($self, $params, $content) = @_;
    unless ( $content && %$content ) {
        confess("No content provided to create a media upload");
    }
    my $url = $self->_url('/upload/drive/v3/files', $params);
    my $json = $self->_request(
        method => 'POST',
        url => $url,
        content => encode_json($content)
    );
    return $json;
}

sub delete {
    my ($self, $id) = @_;
    confess("No ID provided") unless ($id);
    my $url = $self->_url("/$id");
    $self->_request(
        method => 'DELETE',
        url => $url
    );
    return 1;
}

sub empty_trash {
    my ($self) = @_;
    $self->_request(
        method => 'DELETE',
        url => $self->_url('/trash')
    );
    return 1;
}

sub export {
    my ($self, $id, $params) = @_;
    confess("No ID provided") unless ($id);
    confess("mimeType is a required param to export files") unless ($params->{mimeType});
    my $url = $self->_url("/$id/export", $params);
    my $decoded_content = $self->_request(
        method => 'GET',
        url => $url
    );
    return $decoded_content;
}

sub generate_ids {
    my ($self, $params) = @_;
    my $url = $self->_url('/generateIds', $params);
    my $json = $self->_request(
        method => 'GET',
        url => $url
    );
    return $json;
}

sub get {
    my ($self, $id, $params) = @_;
    confess("No ID provided") unless ($id);
    my $url = $self->_url("/$id", $params);
    my $json = $self->_request(
        method => 'GET',
        url => $url
    );
}

sub list {
    my ($self, $params) = @_;
    my $url = $self->_url(undef, $params);
    my $json = $self->_request(
        method => 'GET',
        url => $url
    );
    return $json;
}

sub update_media {
    my ($self, $id, $params, $content) = @_;
    confess("No ID provided") unless ($id);
    unless ( $content && %$content ) {
        confess("No content provided to update");
    }
    my $url = $self->_url("/upload/drive/v3/files/$id", $params);
    my $json = $self->_request(
        method => 'PATCH',
        url => $url,
        content => encode_json($content)
    );
    return $json;
}

sub update {
    my ($self, $id, $params, $content) = @_;
    confess("No ID provided") unless ($id);
    unless ( $content && %$content ) {
        confess("No content provided to update");
    }
    my $url = $self->_url("/$id", $params);
    my $json = $self->_request(
        method => 'PATCH',
        url => $url,
        content => encode_json($content)
    );
    return $json;
}

sub watch {
    my ($self, $id, $params, $content) = @_;
    confess("No ID provided") unless ($id);
    my $url = $self->_url("/$id/watch", $params);
    $content = $content ? encode_json($content) : undef;
    my $json = $self->_request(
        method => 'POST',
        url => $url,
        content => $content
    );
    return $json;
}

=head1 NAME

Google::Client::Files

=head1 DESCRIPTION

A file resource client used in L<Google::Client::Collection|https://metacpan.org/pod/Google::Client::Collection> to integrate with
Googles Files REST API.

See L<https://developers.google.com/drive/v3/reference/files> for documentation.

=head2 copy(Str $id, HashRef $query_params, HashRef $post_content)

=head2 create(HashRef $query_params, HashRef $post_content)

=head2 create_media(HashRef $query_params, HashRef $post_content)

=head2 delete(Str $id)

=head2 empty_trash()

=head2 export(Str $id, HashRef $query_params)

=head2 generate_ids(HashRef $query_params)

=head2 get(Str $id, HashRef $query_params)

=head2 list(HashRef $query_params)

=head2 update(Str $id, HashRef $query_params, HashRef $post_content)

=head2 update_media(Str $id, HashRef $query_params, HashRef $post_content)

=head2 watch(Str $id, HashRef $query_params, HashRef $post_content)

=head1 AUTHOR

Ali Zia, C<< <ziali088@gmail.com> >>

=head1 REPOSITORY

L<https://github.com/ziali088/googleapi-client>

=head1 COPYRIGHT AND LICENSE

This is free software. You may use it and distribute it under the same terms as Perl itself.
Copyright (C) 2016 - Ali Zia

=cut

1;
