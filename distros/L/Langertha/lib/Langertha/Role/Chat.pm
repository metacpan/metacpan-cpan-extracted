package Langertha::Role::Chat;
our $AUTHORITY = 'cpan:GETTY';
# ABSTRACT: Role for APIs with normal chat functionality
$Langertha::Role::Chat::VERSION = '0.008';
use Moose::Role;
use Carp qw( croak );

requires qw(
  chat_request
  chat_response
);

has chat_model => (
  is => 'ro',
  isa => 'Str',
  lazy_build => 1,
);
sub _build_chat_model {
  my ( $self ) = @_;
  croak "".(ref $self)." can't handle models!" unless $self->does('Langertha::Role::Models');
  return $self->default_chat_model if $self->can('default_chat_model');
  return $self->model;
}

sub chat {
  my ( $self, @messages ) = @_;
  return $self->chat_request($self->chat_messages(@messages));
}

sub chat_messages {
  my ( $self, @messages ) = @_;
  return [$self->has_system_prompt
    ? ({
      role => 'system', content => $self->system_prompt,
    }) : (),
    map {
      ref $_ ? $_ : {
        role => 'user', content => $_,
      }
    } @messages];
}

sub simple_chat {
  my ( $self, @messages ) = @_;
  my $request = $self->chat(@messages);
  my $response = $self->user_agent->request($request);
  return $request->response_call->($response);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::Chat - Role for APIs with normal chat functionality

=head1 VERSION

version 0.008

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
