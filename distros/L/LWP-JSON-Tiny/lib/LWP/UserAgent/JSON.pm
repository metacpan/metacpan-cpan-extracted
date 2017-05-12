package LWP::UserAgent::JSON;

use strict;
use warnings;
no warnings 'uninitialized';

use HTTP::Request::JSON;
use LWP::JSON::Tiny;
use Scalar::Util ();
use parent 'LWP::UserAgent';

our $VERSION = $LWP::JSON::Tiny::VERSION;

=head1 NAME

LWP::UserAgent::JSON - a subclass of LWP::UserAgent that understands JSON

=head1 SYNOPSIS

 my $user_agent = LWP::UserAgent::JSON->new;
 my $request    = HTTP::Request::JSON->new(...);
 my $response   = $user_agent->request($request);
 # $response->isa('HTTP::Response::JSON') if we got back JSON

=head1 DESCRIPTION

This is a subclass of LWP::UserAgent which recognises if it gets
JSON output back, and if so returns an L<HTTP::Response::JSON> object instead
of a L<HTTP::Response> object. It exposes the logic of reblessing the
HTTP::Response object in case you get handed a HTTP::Response object by
some other method.

It also offers a handful of convenience methods to directly convert
parameters into JSON for POST, PUT and PATCH requests.

=head2 post_json

Like LWP::UserAgent::post, except for when it's called as
C<post_json($url, $form_ref, ...)>, in which case $form_ref is turned into
JSON. Obviously if you specify Content-Type or Content in subsequent header
arguments they'll take precedence.

=cut

sub post_json {
    my $self = shift;
    my $url = shift;

    $self->SUPER::post($url, $self->_mangle_request_arguments(@_));
}

=head3 put_json

A variant on LWP::UserAgent::put with the same transformations as post_json.

=cut

sub put_json {
    my $self = shift;
    my $url = shift;

    $self->SUPER::put($url, $self->_mangle_request_arguments(@_));
}

=head3 patch_json

As post_json and put_json, but generates a PATCH request instead.

=cut

sub patch_json {
    my $self = shift;
    my $url = shift;

    $self->patch($url, $self->_mangle_request_arguments(@_));
}

=head3 patch

LWP::UserAgent doesn't actually implement a patch method, so it's defined
here.

=cut

sub patch {
    require HTTP::Request::Common;
    my ($self, @parameters) = @_;
    my @suff = $self->_process_colonic_headers(\@parameters,
        (ref($parameters[1]) ? 2 : 1));
    return $self->request(
        HTTP::Request::Common::request_type_with_data('PATCH', @parameters),
        @suff);
}

sub _mangle_request_arguments {
    my $self = shift;

    # If we have a reference as the first argument, remove it and replace
    # it with a series of standard headers, so HTTP::Request::Common doesn't
    # do its magic.
    if (ref($_[0])) {
        my $throwaway_request = HTTP::Request::JSON->new;
        $throwaway_request->json_content($_[0]);
        splice(
            @_, 0, 1,
            Content        => $throwaway_request->content,
            'Content-Type' => $throwaway_request->content_type,
            Accept         => 'application/json'
        );
    }
    return @_;
}

=head2 simple_request

As LWP::UserAgent::simple_request, but returns a L<HTTP::Response:JSON>
object instead of a L<HTTP::Response> object if the response is JSON.

=cut

sub simple_request {
    my $self = shift;

    $self->rebless_maybe($_[0]);
    my $response = $self->SUPER::simple_request(@_);
    $self->rebless_maybe($response);
    return $response;
}

=head2 rebless_maybe

 In: $object
 Out: $reblessed

Supplied with a HTTP::Request or HTTP::Response object, looks to see if it's a
JSON object, and if so reblesses it to be a HTTP::Request::JSON or
HTTP::Response::JSON object respectively. Returns whether it reblessed the
object or not.

=cut

sub rebless_maybe {
    my ($object) = pop;

    if (   Scalar::Util::blessed($object)
        && $object->can('content_type')
        && $object->content_type eq 'application/json')
    {
        if ($object->isa('HTTP::Response')) {
            bless $object => 'HTTP::Response::JSON';
            return 1;
        } elsif ($object->isa('HTTP::Request')) {
            bless $object => 'HTTP::Request::JSON';
            return 1;
        }
    }
    return 0;
}

=head1 AUTHOR

Sam Kington <skington@cpan.org>

The source code for this module is hosted on GitHub
L<https://github.com/skington/lwp-json-tiny> - this is probably the
best place to look for suggestions and feedback.

=head1 COPYRIGHT

Copyright (c) 2015 Sam Kington.

=head1 LICENSE

This library is free software and may be distributed under the same terms as
perl itself.

=cut

1;
