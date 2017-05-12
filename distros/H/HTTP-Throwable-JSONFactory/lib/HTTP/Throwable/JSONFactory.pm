package HTTP::Throwable::JSONFactory;
# ABSTRACT: Throw exceptions with JSON bodies
$HTTP::Throwable::JSONFactory::VERSION = '0.002';
use strict;
use warnings;

use parent qw(HTTP::Throwable::Factory);

sub extra_roles {
  return qw(
    HTTP::Throwable::Role::JSONBody
  );
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::JSONFactory - Throw exceptions with JSON bodies

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use HTTP::Throwable::JSONFactory qw(http_throw);

  http_throw(Gone => {
    payload => {
      error => "You won't find what you're looking for here",
    },
  });

=head1 OVERVIEW

This subclass of L<HTTP::Throwable::Factory> arranges for each built/thrown
exception to consume the L<HTTP::Throwable::Role::JSONBody> role, which
will generate HTTP responses with an C<application/json> content type and
encode the (optional) provided payload using L<JSON::MaybeXS>.

The C<payload> attribute passed to C<http_throw> or C<http_exception> should
be anything allowed by L<JSON/encode_json> (hashref, arrayref, etc).

=head1 AUTHOR

Matthew Horsfall <wolfsage@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Matthew Horsfall.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SYNOPSIS
#pod
#pod   use HTTP::Throwable::JSONFactory qw(http_throw);
#pod
#pod   http_throw(Gone => {
#pod     payload => {
#pod       error => "You won't find what you're looking for here",
#pod     },
#pod   });
#pod
#pod =head1 OVERVIEW
#pod
#pod This subclass of L<HTTP::Throwable::Factory> arranges for each built/thrown
#pod exception to consume the L<HTTP::Throwable::Role::JSONBody> role, which
#pod will generate HTTP responses with an C<application/json> content type and
#pod encode the (optional) provided payload using L<JSON::MaybeXS>.
#pod
#pod The C<payload> attribute passed to C<http_throw> or C<http_exception> should
#pod be anything allowed by L<JSON/encode_json> (hashref, arrayref, etc).
#pod
#pod =cut
