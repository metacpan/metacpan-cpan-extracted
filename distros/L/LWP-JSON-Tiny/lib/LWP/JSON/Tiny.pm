package LWP::JSON::Tiny;

use strict;
use warnings;
no warnings 'uninitialized';

use HTTP::Request::JSON;
use HTTP::Response::JSON;
use JSON::MaybeXS;
use LWP;
use LWP::UserAgent::JSON;

our $VERSION = '0.010';
$VERSION = eval $VERSION;

=head1 NAME

LWP::JSON::Tiny - use JSON natively with LWP objects

=head1 VERSION

This is version 0.009.

=head1 SYNOPSIS

 my $user_agent = LWP::UserAgent::JSON->new;
 my $request = HTTP::Request::JSON->new(POST => "$url_prefix/upload_dance");
 $request->json_content({ contents => [qw(badger mushroom snake)] });
 my $response = $user_agent->request($request);
 if (my $upload_id = $response->json_content->{upload}{id}) {
     print "Uploaded Weebl rip-off: $upload_id\n";
 }

 my $other_response = $some_other_object->do_stuff(...);
 if (LWP::UserAgent::JSON->rebless_maybe($other_response)) {
     do_something($other_response->json_content);
 }

=head1 DESCRIPTION

A lot of RESTful API integration involves pointless busy work with setting
accept and content-type headers, remembering how Unicode is supposed to work
and so on. This is a very simple wrapper around HTTP::Request and
HTTP::Response that handles all of that for you.

There are four classes in this distribution:

=over

=item LWP::JSON::Tiny

Pulls in the other classes, and implements a L</"json_object"> method which
returns a JSON object, suitable for parsing and emitting JSON.

=item HTTP::Request::JSON

A subclass of HTTP::Request. It automatically sets the Accept header to
C<application/json>, and implements a
L<json_content|HTTP::Request::JSON/json_content> method
which takes a JSONable data structure and sets the content-type.

=item HTTP::Response::JSON

A subclass of HTTP::Response. It implements a
L<json_content|HTTP::Response::JSON/json_content> method which
decodes the JSON contents into a Perl data structure.

=item LWP::UserAgent::JSON

A subclass of LWP::UserAgent. It does only one thing: is a response has
content-type JSON, it reblesses it into a HTTP::Response::JSON object.
It exposes this method L<rebless_maybe|LWP::UserAgent::JSON/rebless_maybe>
for convenience, if you ever get an HTTP::Response object back from some
other class.

=back

As befits a ::Tiny distribution, sensible defaults are applied. If you really
need to tweak this stuff (e.g. you really care about the very slight
performance impact of sorting all hash keys), look at the individual
modules' documentation for how you can subclass behaviour.

=head2 Class methods

=head3 json_object

 Out: $json

Returns a JSON object, as per JSON::MaybeXS->new. Cached across multiple
calls for speed.

Note that the JSON object has the utf8 option disabled. I<This is deliberate>.
The documentation for JSON::XS is very clear that the utf8 option means both
that it should spit out JSON in UTF8, and that it should expect strings
passed to it to be in UTF8 encoding. This latter part is daft, and violates
the best practice that character encoding should be dealt with at the
outermost layer.

=cut

{
    my %json_by_class;

    sub json_object {
        my ($invocant) = @_;

        my $class = ref($invocant) || $invocant;
        my $json ||= $json_by_class{$class};
        return $json if defined $json;
        $json = JSON::MaybeXS->new($class->default_json_arguments);
        return $json_by_class{$class} = $json;
    }
}

=head3 default_json_arguments

 Out: %default_json_arguments

The default arguments to pass to JSON::MaybeXS->new. This is what you'd
subclass if you wanted to change how LWP::JSON::Tiny encoded JSON.

=cut

sub default_json_arguments {
    return (
        utf8            => 0,
        allow_nonref    => 1,
        allow_unknown   => 0,
        allow_blessed   => 0,
        convert_blessed => 0,
        canonical       => 1,
    );
}

=head1 SEE ALSO

L<JSON::API> handles authentication and common URL prefixes, but (a)
doesn't support PATCH routes, and (b) makes you use a wrapper object
rather than LWP directly.

L<WWW::JSON> handles authentication (including favours of OAuth), common URL
prefixes, response data structure transformations, but has the same
limitations as JSON::API, as well as being potentially unwieldy.

L<LWP::Simple::REST> decodes JSON but makes you use a wrapper object, and
looks like a half-hearted attempt that never went anywhere.

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