package HTTP::Throwable::Role::JSONBody;
# ABSTRACT - JSON Body
$HTTP::Throwable::Role::JSONBody::VERSION = '0.002';
use Moo::Role;
use JSON::MaybeXS;

has payload => (
  is => 'ro',
);

sub body {
  my $self = shift;

  # Preempt bad clients that can't handle application/json with empty
  # body
  return "{}" unless $self->payload;

  return encode_json($self->payload);
}

sub body_headers {
  my ($self, $body) = @_;

  return [
    'Content-Type' => 'application/json',
    'Content-Length' => length $body,
  ];
}

sub as_string {
  my $self = shift;

  return $self->body;
}

no Moo::Role; 1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Role::JSONBody

=head1 VERSION

version 0.002

=head1 OVERVIEW

This role does two things - accepts an optional C<payload> argument that
should be anything you can pass to L<JSON/"encode_json">, and then encodes
it as the body, specifying a C<Content-Type> of C<application/json>. If no
C<payload> is provided, the body will be C<{}>.

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Matthew Horsfall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 OVERVIEW
#pod
#pod This role does two things - accepts an optional C<payload> argument that
#pod should be anything you can pass to L<JSON/"encode_json">, and then encodes
#pod it as the body, specifying a C<Content-Type> of C<application/json>. If no
#pod C<payload> is provided, the body will be C<{}>.
#pod
#pod =cut
