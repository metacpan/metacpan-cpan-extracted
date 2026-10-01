package Kubernetes::REST::APIError;
our $VERSION = '1.109';
# ABSTRACT: An HTTP error status answered by the Kubernetes API
use Moo;
use Carp ();
use JSON::MaybeXS ();
use Types::Standard qw(Int Maybe Str);
use namespace::clean;

use overload
    '""'     => '_as_string',
    bool     => sub { 1 },
    fallback => 1;


has code => (is => 'ro', isa => Int, required => 1);


has body => (is => 'ro', isa => Str, default => sub { '' });


# Maybe: check_response may be called without a context, and the message
# then reads "Kubernetes API error (): ...", as it always did.
has context => (is => 'ro', isa => Maybe[Str]);


has response => (is => 'ro');


# The Kubernetes Status object the body holds, or undef when it holds none:
# a proxy's HTML page, plain text, JSON of another shape, no body at all.
has _status => (is => 'lazy');

sub _build__status {
    my ($self) = @_;
    # body is characters already, so the decoder must not expect bytes.
    my $status = eval { JSON::MaybeXS->new->decode($self->body) };
    return unless ref $status eq 'HASH' && ($status->{kind} // '') eq 'Status';
    return $status;
}

has reason => (is => 'lazy');

sub _build_reason { ($_[0]->_status // {})->{reason} }


has message => (is => 'lazy');

sub _build_message { ($_[0]->_status // {})->{message} }


has details => (is => 'lazy');

sub _build_details { ($_[0]->_status // {})->{details} }


# ' at FILE line N.' plus newline, as croak appends it; set by throw.
has _location => (is => 'ro', default => sub { '' });

sub is_not_found { $_[0]->code == 404 }


sub is_conflict { $_[0]->code == 409 }


our @CARP_NOT;

sub throw {
    my ($class, %args) = @_;
    # Trust the package that throws, so Carp skips its frames exactly as a
    # croak from there would: the location names the caller line the string
    # croak named before this was an object.
    local @CARP_NOT = (scalar caller);
    die $class->new(%args, _location => Carp::shortmess(''));
}


sub _as_string {
    my ($self) = @_;
    return 'Kubernetes API error (' . ($self->context // '') . '): '
        . $self->code . ' ' . $self->body . $self->_location;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Kubernetes::REST::APIError - An HTTP error status answered by the Kubernetes API

=head1 VERSION

version 1.109

=head1 SYNOPSIS

    my $pod = eval { $api->get('Pod', 'web', namespace => 'default') };
    if (my $err = $@) {
        die $err unless ref $err && $err->isa('Kubernetes::REST::APIError');
        if ($err->is_not_found) {
            # already gone
        } elsif ($err->is_conflict) {
            # changed in the meantime: re-read and retry
        } else {
            warn $err->code . ' ' . ($err->reason // '') . ': '
                . ($err->message // $err->body) . "\n";
            die $err;
        }
    }

=head1 DESCRIPTION

What L<Kubernetes::REST> dies with when the API server answers a request with
an HTTP error status (400 and up) - from every method that checks a
response, and from the public L<Kubernetes::REST/check_response> an async
wrapper calls.

The object stringifies to exactly the message these errors carried as plain
strings, location included:

    Kubernetes API error (get Pod): 404 {"kind":"Status",...} at app.pl line 12.

so code that prints C<$@>, matches it against a regex or compares it with
C<eq> keeps working. It is always true in boolean context.

Everything else - invalid arguments, a resource name that resolves to no
class - still croaks with a plain string. Where such a message reports an
API error behind it, such as a failed discovery read, it embeds this
object's text.

Not to be confused with L<Kubernetes::REST::Error>, the exception class of
the deprecated v0 API.

=head2 code

Required. The HTTP status code, as a number (C<404>, C<409>, C<500>, ...).

=head2 body

The response body, decoded from UTF-8 to characters - leniently, so a
truncated or non-UTF-8 body still yields a string. Empty when there was none.

=head2 context

What was being done, as named in the message: C<get Pod>,
C<delete IO::K8s::Api::Core::V1::Pod>, ... C<undef> when
L<Kubernetes::REST/check_response> was given none.

=head2 response

The response object itself (a L<Kubernetes::REST::HTTPResponse>, or whatever
the IO backend returned), for anything the other attributes do not carry.

=head2 reason

The C<reason> of the Kubernetes C<Status> object in the body - C<NotFound>,
C<AlreadyExists>, C<Conflict>, C<Invalid>, C<Forbidden>, ... C<undef> when
the body is not such an object.

=head2 message

The C<message> of the Kubernetes C<Status> object in the body, e.g.
C<pods "web" not found>. C<undef> when the body is not such an object.

=head2 details

The C<details> of the Kubernetes C<Status> object in the body, as a hashref
(C<name>, C<kind>, C<causes>, ...). C<undef> when the body is not such an
object or carries none.

=head2 is_not_found

True for a C<404>: the resource does not exist (or no longer does).

=head2 is_conflict

True for a C<409>: the resource already exists, or changed since the
C<resourceVersion> that was sent.

=head2 throw

    Kubernetes::REST::APIError->throw(
        code     => $response->status,
        body     => $decoded_body,
        context  => 'get Pod',
        response => $response,
    );

Construct the error and die with it. The location it stringifies with is
the one C<croak> would add at that point: the first caller outside the
throwing package.

=head1 SEE ALSO

=over

=item * L<Kubernetes::REST> - Main API client

=item * L<Kubernetes::REST/check_response> - Where it is thrown

=item * L<https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/status/> - The Kubernetes Status object

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/pplu/kubernetes-rest/issues>.

=head2 IRC

Join C<#kubernetes> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHORS

=over 4

=item *

Torsten Raudssus <getty@cpan.org>

=item *

Jose Luis Martinez Torres <jlmartin@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019-2026 by Jose Luis Martinez Torres <jlmartin@cpan.org>.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
