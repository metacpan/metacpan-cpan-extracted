package HTTP::Headers::ActionPack::Authorization::Basic;
BEGIN {
  $HTTP::Headers::ActionPack::Authorization::Basic::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::Authorization::Basic::VERSION = '0.09';
}
# ABSTRACT: The Basic Authorization Header

use strict;
use warnings;

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
        my ($username, $password) = split ':' => decode_base64( $credentials );
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

=head1 NAME

HTTP::Headers::ActionPack::Authorization::Basic - The Basic Authorization Header

=head1 VERSION

version 0.09

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

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
