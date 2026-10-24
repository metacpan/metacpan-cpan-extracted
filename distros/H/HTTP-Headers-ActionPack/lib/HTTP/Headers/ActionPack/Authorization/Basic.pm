package HTTP::Headers::ActionPack::Authorization::Basic;
# ABSTRACT: The Basic Authorization Header

use strict;
use warnings;

our $VERSION = '0.10';

use Carp         qw[ confess ];
use MIME::Base64 qw[ encode_base64 decode_base64 ];

use parent 'HTTP::Headers::ActionPack::Core::Base';

sub BUILDARGS {
    my $class       = shift;
    my $type        = shift || confess "Must specify type";
    my $credentials = shift || confess "Must provide credentials";

    if ( ref $credentials && ref $credentials eq 'HASH' ) {
        return +{ auth_type => $type, %$credentials };
    }
    elsif ( ref $credentials && ref $credentials eq 'ARRAY' ) {
        my ($username, $password) = @$credentials;
        return +{ auth_type => $type, username => $username, password => $password };
    }
    else {
        my ($username, $password) = decode_base64( $credentials ) =~ /^([^:]+):(.*)$/;
        return +{ auth_type => $type, username => $username, password => $password };
    }
}

sub new_from_string {
    my ($class, $header_string) = @_;
    my ($type, $credentials) = split /\s/ => $header_string;
    ($type eq 'Basic')
        || confess "The type must be 'Basic', not '$type'";
    $class->new( $type, $credentials );
}

sub auth_type { (shift)->{'auth_type'} }
sub username  { (shift)->{'username'}  }
sub password  { (shift)->{'password'}  }

sub as_string {
    my $self = shift;
    join ' ' => $self->auth_type, encode_base64( (join ':' => $self->username, $self->password), '' )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::Authorization::Basic - The Basic Authorization Header

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Authorization::Basic;

  # create from string
  my $auth = HTTP::Headers::ActionPack::Authorization::Basic->new_from_string(
      'Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
  );

  # create from parameters
  my $auth = HTTP::Headers::ActionPack::Authorization::Basic->new(
      'Basic' => {
          username => 'Aladdin',
          password => 'open sesame'
      }
  );

  my $auth = HTTP::Headers::ActionPack::Authorization::Basic->new(
      'Basic' => [ 'Aladdin', 'open sesame' ]
  );

  my $auth = HTTP::Headers::ActionPack::Authorization::Basic->new(
      'Basic' => 'QWxhZGRpbjpvcGVuIHNlc2FtZQ=='
  );

=head1 DESCRIPTION

This class represents the Authorization header with the specific
focus on the 'Basic' type.

=head1 METHODS

=over 4

=item C<new ( $type, $credentials )>

The C<$credentials> argument can either be a Base64 encoded string (as
would be passed in via the header), a HASH ref with username and password
keys, or a two element ARRAY ref where the first element is the username
and the second the password.

=item C<new_from_string ( $header_string )>

=item C<auth_type>

=item C<username>

=item C<password>

=item C<as_string>

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
