package Flickr::API::Request;

use strict;
use warnings;
use HTTP::Request;
use Net::OAuth;
use URI;
use Encode qw(encode_utf8);

use parent qw(HTTP::Request);

our $VERSION = '1.28';

sub new {
    my $class = shift;
    my $options = shift;
    my $self;

    if (($options->{api_type} || '') eq 'oauth') {

        $options->{args}->{request_method}='POST';
        $options->{args}->{request_url}=$options->{rest_uri};

        $Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

        my $orequest;

        if (defined($options->{args}->{token})) {

            $orequest = Net::OAuth->request('protected resource')->new(%{$options->{args}});

        }
        else {

            $orequest = Net::OAuth->request('consumer')->new(%{$options->{args}});

        }

        $orequest->sign();

        my $h = HTTP::Headers->new;
        $h->header('Content-Type' => 'application/x-www-form-urlencoded');
        $h->header('Content-Length' => length($orequest->to_post_body));

        $self = HTTP::Request->new(
            $options->{args}->{request_method},
            $options->{rest_uri},
            $h,
            $orequest->to_post_body());

        $self->{api_method} = $options->{method};
        $self->{api_type}   = $options->{api_type};
        $self->{unicode}    = $options->{unicode} || 0;

    }
    else {

        $self = HTTP::Request->new;

        $self->{api_method} = $options->{method};

        $self->{api_type}   = $options->{api_type} || 'flickr';
        $self->{unicode}    = $options->{unicode} || 0;
        $self->{api_args}   = $options->{args};
        $self->{rest_uri}   = $options->{rest_uri} || 'https://api.flickr.com/services/rest/';
        $self->method('POST');
        $self->uri($self->{rest_uri});

    }

    bless $self, $class;

    return $self;
}

sub encode_args {
    my ($self) = @_;

    my $content;
    my $url = URI->new('https:');

    if ($self->{unicode}){
        for my $k(keys %{$self->{api_args}}){
            $self->{api_args}->{$k} = encode_utf8($self->{api_args}->{$k});
        }
    }
    $url->query_form(%{$self->{api_args}});
    $content = $url->query;


    $self->header('Content-Type' => 'application/x-www-form-urlencoded');
    if (defined($content)) {
        $self->header('Content-Length' => length($content));
        $self->content($content);
    }
    return;
}

1;

__END__

=head1 NAME

Flickr::API::Request - A request to the Flickr API

=head1 SYNOPSIS

=head2 Using the OAuth form:

  use Flickr::API;
  use Flickr::API::Request;

  my $api = Flickr::API->new({'consumer_key' => 'your_api_key'});

  my $request = Flickr::API::Request->new({
      'method' => $method,
      'args' => {},
  });

  my $response = $api->execute_request($request);

=head2 Using the original Flickr form:

  use Flickr::API;
  use Flickr::API::Request;

  my $api = Flickr::API->new({'key' => 'your_api_key'});

  my $request = Flickr::API::Request->new({
      'method' => $method,
      'args' => {},
  });

  my $response = $api->execute_request($request);


=head1 DESCRIPTION

This object encapsulates a request to the Flickr API.

C<Flickr::API::Request> is a subclass of L<HTTP::Request>, so you can access
any of the request parameters and tweak them yourself. The content, content-type
header and content-length header are all built from the 'args' list by the
C<Flickr::API::execute_request()> method.


=head1 AUTHOR

Copyright (C) 2004, Cal Henderson, E<lt>cal@iamcal.comE<gt>

OAuth patches and additions 
Copyright (C) 2014-2016, Louis B. Moore <lbmoore@cpan.org>


=head1 SEE ALSO

L<Flickr::API>.
L<Net::OAuth>,

=cut
