package Marketplace::Rakuten::Response;

use strict;
use warnings;

use Moo;
use MooX::Types::MooseLike::Base qw(Str Bool HashRef);
use XML::LibXML::Simple qw/XMLin/;
use Marketplace::Rakuten::Utils;
use Data::Dumper;
use namespace::clean;

=head1 NAME

Marketplace::Rakuten::Response - Class to handle the responses from
webservice.rakuten.de

The constructors keys map the L<HTTP::Tiny> keys, so you can feed the
constructor straight with the response.

=head1 ACCESSORS

=head2 success

Boolean indicating whether the operation returned a 2XX status code

=head2 url

URL that provided the response. This is the URL of the request
unless there were redirections, in which case it is the last URL
queried in a redirection chain

=head2 status

The HTTP status code of the response

=head2 reason

The response phrase returned by the server

=head2 content

The body of the response. If the response does not have any content or
if a data callback is provided to consume the response body, this will
be the empty string

=head2 headers

A hashref of header fields. All header field names will be normalized
to be lower case. If a header is repeated, the value will be an
arrayref; it will otherwise be a scalar string containing the value

=head2 data

The parsed data from xml, if any.

=cut

has success => (is => 'ro', isa => Bool);
has url     => (is => 'ro', isa => Str);
has status  => (is => 'ro', isa => Str);
has reason  => (is => 'ro', isa => Str);
has content => (is => 'ro', isa => Str);
has headers => (is => 'ro', isa => HashRef);

has data => (is => 'lazy');
sub _build_data {
    my $self = shift;
    my $data;
    if (my $xml = $self->content) {
        eval { $data = XMLin($xml,
                             ForceArray => [ qw/error order/ ],
                             # prevent <name> to be used as key in the structure
                             KeyAttr => [],
                            ) };
        warn "Faulty xml! $@" . $xml if $@;
    }
    Marketplace::Rakuten::Utils::turn_empty_hashrefs_into_empty_strings($data);
    return $data;
}

=head1 METHODS

=head2 is_success

Check that the http status is ok and that there are no errors.

=cut

sub is_success {
    my $self = shift;
    if ($self->success && !$self->errors &&
        defined($self->data->{success}) &&
        $self->data->{success} >= 0) {
        return 1;
    }
    return 0;
}

=head2 errors

Return, if any, a list of hashrefs with errors. The I<expected> keys
of each element are: C<code> C<message> C<help>

http://webservice.rakuten.de/documentation/howto/error

Return an arrayref of error, if any. If there is no error, return
undef.

=cut

sub errors {
    my $self = shift;
    if (my $errors = $self->data->{errors}) {
        if (my $error = $errors->{error}) {
            return $error;
        }
        else {
            die "Unexpected error content!" . Dumper($errors);
        }
    }
    return undef;
}

=head2 error_string

The errors returned as a single string.

=cut

sub error_string {
    my $self = shift;
    if (my $errors = $self->errors) {
        my @out;
        foreach my $err (@$errors) {
            my @pieces;
            foreach my $k (qw/code message help/) {
                push @pieces, $err->{$k} if $err->{$k};
            }
            if (@pieces) {
                push @out, join(' ', @pieces);
            }
        }
        if (@out) {
            return join("\n", @out) . "\n";
        }
    }
    return '';
}

1;
