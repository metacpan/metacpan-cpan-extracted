package Dist::Zilla::Chrome::Test 6.032;
# ABSTRACT: the chrome used by Dist::Zilla::Tester

use Moose;

use Dist::Zilla::Pragmas;

use MooseX::Types::Moose qw(ArrayRef HashRef Str);
use Dist::Zilla::Types qw(OneZero);
use Log::Dispatchouli 1.102220;

use namespace::autoclean;

has logger => (
  is => 'ro',
  default => sub {
    Log::Dispatchouli->new({
      ident   => 'Dist::Zilla::Tester',
      log_pid => 0,
      to_self => 1,
    });
  }
);

#pod =attr response_for
#pod
#pod The response_for attribute (which exists only in the Test chrome) is a
#pod hashref that lets you specify the answer to questions asked by
#pod C<prompt_str> or C<prompt_yn>.  The key is the prompt string.  If the
#pod value is a string, it is returned every time that question is asked.
#pod If the value is an arrayref, the first element is shifted off and
#pod returned every time the question is asked.  If the arrayref is empty
#pod (or the prompt is not listed in the hash), the default answer (if any)
#pod is returned.
#pod
#pod Since you can't pass arguments to the Chrome constructor, response_for
#pod is initialized to an empty hash, and you can add entries after
#pod construction with the C<set_response_for> method:
#pod
#pod   $chrome->set_response_for($prompt => $response);
#pod
#pod =cut

has response_for => (
  isa     => HashRef[ ArrayRef | Str ],
  traits  => [ 'Hash' ],
  default => sub { {} },
  handles => {
    response_for     => 'get',
    set_response_for => 'set',
  },
);

sub prompt_str {
  my ($self, $prompt, $arg) = @_;
  $arg ||= {};

  my $response = $self->response_for($prompt);

  $response = shift @$response if ref $response;

  $response = $arg->{default} unless defined $response;

  $self->logger->log_fatal("no response for test prompt '$prompt'")
    unless defined $response;

  return $response;
}

sub prompt_yn {
  my $self = shift;

  return OneZero->coerce( $self->prompt_str(@_) );
}

sub prompt_any_key { return }

with 'Dist::Zilla::Role::Chrome';
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Chrome::Test - the chrome used by Dist::Zilla::Tester

=head1 VERSION

version 6.032

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 ATTRIBUTES

=head2 response_for

The response_for attribute (which exists only in the Test chrome) is a
hashref that lets you specify the answer to questions asked by
C<prompt_str> or C<prompt_yn>.  The key is the prompt string.  If the
value is a string, it is returned every time that question is asked.
If the value is an arrayref, the first element is shifted off and
returned every time the question is asked.  If the arrayref is empty
(or the prompt is not listed in the hash), the default answer (if any)
is returned.

Since you can't pass arguments to the Chrome constructor, response_for
is initialized to an empty hash, and you can add entries after
construction with the C<set_response_for> method:

  $chrome->set_response_for($prompt => $response);

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
