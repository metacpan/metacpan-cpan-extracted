package Dictionary::Cambridge;
our $AUTHORITY = 'cpan:JINNKS';
# ABSTRACT: A simple module for the Cambridge Dictionary API, only implemented
# one method to get an entry (meaning of a word from the dictionary)
$Dictionary::Cambridge::VERSION = '0.02';
use Moose;
use HTTP::Request;
use LWP::UserAgent;
use URI::Encode;
use JSON;
use namespace::autoclean;

with 'Dictionary::Cambridge::Response';

has "base_url" => (
    is      => 'ro',
    isa     => 'Str',
    default => 'https://dictionary.cambridge.org/api/v1/'
);

has "dictionary" => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has "format" => (
    is => 'rw',
    isa => 'Str',
    default => 'xml'
);

has "access_key" => (
    is  => 'rw',
    isa => 'Str',
    required => 1
);

has "user_agent" => (
    is         => 'ro',
    isa        => 'LWP::UserAgent',
    lazy_build => 1
);

has "encode_uri" => (
    is         => 'ro',
    isa        => 'URI::Encode',
    lazy_build => 1
);

has "json" => (
    is         => 'ro',
    isa        => 'JSON',
    lazy_build => 1
);

sub _build_user_agent {

    return LWP::UserAgent->new();
}

sub _build_http_request {

    return HTTP::Request->new();
}

sub _build_encode_uri {

    return URI::Encode->new();
}

sub _build_json {

    return JSON->new()->utf8;

}


sub get_entry {

    my ( $self, $word ) = @_;

    my $response;
    my $hashed_content;
    #return an error message unless there is entry_id and dict_id
    return "Dictionary id or word not found" unless $self->dictionary and $word;
    return "format of the reponse content is required" unless $self->format;
    return "Format allowed is html or xml"
      unless $self->format eq 'xml'
      or $self->format eq 'html';
    $self->user_agent->default_header( accessKey => $self->access_key );

    my $uri = $self->base_url;
    $uri .= 'dictionaries/' . $self->dictionary . '/entries/';
    $uri .= $word . '/?format=' . $self->format;
    $uri = $self->encode_uri->encode($uri);

    eval { $response = $self->user_agent->get($uri); };
    if ( my $e = $@ ) {
        die "Could not get response from API $e";
    }

    if ( $response->is_success and $response->content ) {
        my $data = $self->json->decode( $response->content );
        $hashed_content = $self->parse_xml_def_eg($data->{entryContent});
    }
    else {
        my $data = $self->json->decode($response->content);
         return $data->{errorMessage};
    }
    $hashed_content;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dictionary::Cambridge - A simple module for the Cambridge Dictionary API, only implemented

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Dictionary::Cambridge

   my $dictionary = Dictionary::Cambridge->new(
    access_key => $ENV{ACCESS_KEY},
    dictionary => 'british',
    format     => 'xml'
);

 my $meaning = $dictionary->get_entry("test");

=head1 DESCRIPTION

    A simple module to interact with Cambridge Dictionary API, this module will only be able to get the meaning of the words
    and their relevant examples if they exist. Also this is my first release so please be patient on mistake and errors.

=head2 METHODS
    get_entry
    params: word to get the meaning of

=head1 SEE ALSO

L<http://dictionary-api.cambridge.org/api/resources>

=head1 AUTHOR

Farhan Siddiqui <forsadia@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Farhan Siddiqui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
