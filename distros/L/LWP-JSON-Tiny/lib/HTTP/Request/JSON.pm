package HTTP::Request::JSON;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'HTTP::Message::JSON', 'HTTP::Request';

our $VERSION = $LWP::JSON::Tiny::VERSION;

use Encode ();
use LWP::JSON::Tiny;
use JSON::MaybeXS ();

=head1 NAME

HTTP::Request::JSON - a subclass of HTTP::Request that understands JSON

=head1 SYNOPSIS

 my $request = HTTP::Request::JSON->new(PATCH => "$base_url/death_ray");
 # $request has an Accept header saying it's OK to send JSON back
 $request->json_content(
     {
         self_destruct_mechanism   => 'disabled',
         users_allowed_to_override => [],
     }
 );
 # Request content is JSON-encoded, and the content-type is set.

=head1 DESCRIPTION

This is a simple subclass of HTTP::Request::JSON that does two things.
First of all, it sets the Accept header to C<application/json> as soon
as it's created. Secondly, it implements a L</json_content>
method that adds the supplied data structure to the request, as JSON,
or returns the current JSON contents as a Perl structure.

=head2 new

 In: ...
 Out: $request

As HTTP::Request->new, but also sets the Accept header.

=cut

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->header('Accept' => 'application/json');
    return $self;
}

=head2 json_content

 In: $perl_data (optional)
 Out: $converted_content

A mutator for the request's JSON contents.

As a setter, supplied with a valid JSON data structure, sets the request
contents to be the JSON-encoded version of that data structure, and sets the
Content-Type header to C<application/json>. Will throw an exception if the
data structure cannot be converted to JSON. Returns the resulting string
contents.

All strings in $perl_data must be Unicode strings, or you will get
encoding errors.

As a getter, decodes the request contents from JSON
into a Perl structure, and returns the resulting data structure.

=cut

sub json_content {
    my $self = shift;

    my $json = $self->json_object;

    # Setter
    if (@_) {
        $self->content(Encode::encode('UTF8', $json->encode(shift)));
        $self->content_type('application/json');
        return $self->decoded_content;
    }

    # Getter
    my $perl_data = $json->decode($self->decoded_content);
    return $perl_data;
}

=head2 json_object

 Out: $json_object

Returns an object that knows how to handle the C<encode> and C<decode>
methods. By default whatever LWP::JSON::Tiny->json_object returns.
This is what you'd subclass if you wanted to use some other kind of JSON
object instead.

=cut

sub json_object {
    my ($self) = @_;

    return LWP::JSON::Tiny->json_object;
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