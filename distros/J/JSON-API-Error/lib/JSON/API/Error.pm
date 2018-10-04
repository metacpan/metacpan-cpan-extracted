package JSON::API::Error;

# ABSTRACT: JSON API-style error objects

use Moo;
use overload bool => sub {1}, '""' => \&to_string;

use Types::Standard qw/Str HashRef/;

our $VERSION = '0.01';

has code   => (is => 'ro', isa => Str);
has detail => (is => 'ro', isa => Str);
has id     => (is => 'ro', isa => Str);
has links  => (is => 'ro', isa => HashRef);
has meta   => (is => 'ro', isa => HashRef);
has source => (is => 'ro', isa => HashRef);
has status => (is => 'ro', isa => Str);
has title  => (is => 'ro', isa => Str);

sub to_string {
    my $self = shift;
    return sprintf "%s: %s", $self->{source}->{pointer}, $self->{title};
}

sub TO_JSON {
    my $self = shift;
    my $json = {};
    for (qw/code detail id links meta source status title/) {
        $json->{$_} = $self->$_ if $self->$_;
    }
    return $json;
}

1;

__END__

=encoding utf-8

=head1 NAME

JSON::API::Error - JSON API-style error objects

=head1 SYNOPSIS

  use JSON::API::Error;
  use Mojo::JSON qw/encode_json/;

  # A JSON API error representing bad submission data
  my $err = JSON::API::Error->new({
      source => {pointer => '/forename'},
      status => '400',
      title  => 'Field required',
  });

  # Field required
  say $err->title;
  # /forename: Field required
  say "$err";

  # {
  #   "source": {
  #     "pointer": "/forename"
  #   },
  #   "status": "400",
  #   "title": "Field required"
  # }
  say encode_json $err;
  say encode_json $err->TO_JSON;

  # A JSON API error representing a missing resource
  my $err = JSON::API::Error->new({
      status => '404',
      title  => 'Not Found',
  });

  # {
  #   "status": "404",
  #   "title": "Not Found"
  # }
  say encode_json $err;
  say encode_json $err->TO_JSON;

=head1 DESCRIPTION

L<JSON::API::Error> provides a L<JSON API error object|http://jsonapi.org/format/#error-objects>.
It is intended to provide a consistent error interface that can be digested by
front and backend software.

The front end will receive an C<ARRAY> of these objects when there is an error.
It should contain enough information to be able to add custom errors to specific
form elements.

=head1 ATTRIBUTES

L<JSON::API::Error> implements the following attributes.

=head2 code

An application-specific error code, expressed as a string value.

=head2 detail

A human-readable explanation specific to this occurrence of the problem. Like
C<title>, this field's value can be localized.

=head2 id

A unique identifier for this particular occurrence of the problem.

=head2 links

A L<links object|http://jsonapi.org/format/#document-links> containing the
following members:

B<about>: a link that leads to further details about this particular occurrence
of the problem.

=head2 meta

    my $err = JSON::API::Error->new(
        {
            meta => {
                length => 5,
                detail => "Field length is 5, should be at least 30"
            },
            source => {pointer => "/forename"},
            status => '400',
            title  => "Field length",
        }
    );

A meta object containing non-standard meta-information about the error. Can be
used to include more detail about the error.

=head2 source

An object containing references to the source of the error, optionally including
any of the following members:

B<pointer>: a JSON Pointer [RFC6901] to the associated entity in the request
document [e.g. "/data" for a primary data object, or "/data/attributes/title"
for a specific attribute].

B<parameter>: a string indicating which URI query parameter caused the error.

=head2 status

The HTTP status code applicable to this problem, expressed as a string value.

=head2 title

A short, human-readable summary of the problem that SHOULD NOT change from
occurrence to occurrence of the problem, except for purposes of localization.

=head1 METHODS

L<JSON::API::Error> implements the following methods.

=head2 TO_JSON

Returns the object instance as a C<HASH> reference, suitable for encoding to
C<JSON>.

=head1 OPERATORS

L<JSON::API::Error> overloads the following operators.

=head2 bool

  my $bool = !!$err;

Always true.

=head2 stringify

  my $str = "$err";

Alias for C<to_string>.

=head1 AUTHOR

Paul Williams E<lt>kwakwa@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018- Paul Williams

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<https://metacpan.org/pod/Mojolicious::Plugin::OpenAPI>,
L<http://jsonapi.org/>,
L<http://jsonapi.org/format/#errors>.

=cut
