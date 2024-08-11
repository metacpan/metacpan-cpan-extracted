package Langertha::Role::HTTP;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for HTTP APIs
$Langertha::Role::HTTP::VERSION = '0.003';
use Moose::Role;

use Carp qw( croak );
use URI;
use LWP::UserAgent;

use Langertha::Request::HTTP;
use HTTP::Request::Common;

requires qw(
  json
);

has url => (
  is => 'ro',
  isa => 'Str',
  predicate => 'has_url',
);

sub generate_json_body {
  my ( $self, %args ) = @_;
  return $self->json->encode({ %args });
}

our $boundary = 'XyXLaXyXngXyXerXyXthXyXaXyX';

sub generate_multipart_body {
  my ( $self, $req, %args ) = @_;
  my @formdata = map { $_, $args{$_} } sort { $a cmp $b } keys %args;
  return HTTP::Request::Common::form_data(\@formdata, $boundary, $req);
}

sub generate_http_request {
  my ( $self, $method, $url, $response_call, %args ) = @_;
  my $uri = URI->new($url);
  my $content_type = (delete $args{content_type}||"");
  my $userinfo = $uri->userinfo;
  $uri->userinfo(undef) if $userinfo;
  my $headers = [
    ( 'Content-Type',
      $content_type eq 'multipart/form-data'
        ? 'multipart/form-data; boundary="'.$boundary.'"'
      : 'application/json; charset=utf-8' )
  ];
  my $request = Langertha::Request::HTTP->new(
    http => [ uc($method), $uri, $headers, ( scalar %args > 0 ?
      ( !$content_type or $content_type eq 'application/json' )
        ? $self->generate_json_body(%args)
          : ()
      : ()
    ) ],
    request_source => $self,
    response_call => $response_call,
  );
  if ($content_type and $content_type eq 'multipart/form-data') {
    $request->content($self->generate_multipart_body($request, %args));
  }
  if ($userinfo) {
    my ( $user, $pass ) = split(/:/, $userinfo);
    if ($user and $pass) {
      $request->authorization_basic($user, $pass);
    }
  }
  $self->update_request($request) if $self->can('update_request');
  return $request;
}

sub parse_response {
  my ( $self, $response ) = @_;
  croak "".(ref $self)." request failed: ".($response->status_line) unless $response->is_success;
  return $self->json->decode($response->decoded_content);
}

has user_agent_timeout => (
  isa => 'Int',
  is => 'ro',
  predicate => 'has_user_agent_timeout',
);

has user_agent_agent => (
  isa => 'Str',
  is => 'ro',
  lazy_build => 1,
);
sub _build_user_agent_agent {
  my ( $self ) = @_;
  return "".(ref $self)."";
}

has user_agent => (
  isa => 'LWP::UserAgent',
  is => 'ro',
  lazy_build => 1,
);
sub _build_user_agent {
  my ( $self ) = @_;
  return LWP::UserAgent->new(
    agent => $self->user_agent_agent,
    $self->has_user_agent_timeout ? ( timeout => $self->user_agent_timeout ) : (),
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::HTTP - Role for HTTP APIs

=head1 VERSION

version 0.003

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/Getty/langertha>

  git clone https://github.com/Getty/langertha.git

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
