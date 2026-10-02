package Langertha::Role::KeepAlive;
# ABSTRACT: Role for engines that support keep-alive duration
our $VERSION = '0.503';
use Moose::Role;

has keep_alive => (
  isa => 'Str',
  is => 'ro',
  predicate => 'has_keep_alive',
);


has no_keep_alive => (
  isa => 'Bool',
  is => 'ro',
  default => 0,
);


sub get_keep_alive {
  my ( $self ) = @_;
  return 0 if $self->no_keep_alive;
  return undef unless $self->has_keep_alive;
  my $keep_alive = $self->keep_alive;
  # Ollama reads a JSON number as seconds (negative = forever) but parses a
  # JSON string as a Go duration, which needs a unit: "-1" is a 400 (k333).
  return $keep_alive =~ /\A-?\d+(?:\.\d+)?\z/ ? 0 + $keep_alive : $keep_alive;
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Role::KeepAlive - Role for engines that support keep-alive duration

=head1 VERSION

version 0.503

=head2 keep_alive

    keep_alive => '5m'
    keep_alive => -1     # keep forever
    keep_alive => 300    # seconds

Controls how long the engine keeps the model loaded in memory after a request.
Accepts a duration string with a unit such as C<5m> or C<1h>, or a plain
number of seconds (C<300> or C<'300'>; a negative number such as C<-1> keeps
the model loaded forever). A plain number, also when given as a string, is
sent as a JSON number; a duration string stays a string. When not set, the
engine uses its own default.

See also C<no_keep_alive> for explicitly unloading the model after each request.

=head2 no_keep_alive

    no_keep_alive => 1

When true, the model is unloaded from memory immediately after each request.
Equivalent to setting C<keep_alive =E<gt> 0> but more explicit.

=head2 get_keep_alive

Returns the effective keep-alive value: the number C<0> if C<no_keep_alive> is
set, the C<keep_alive> value if provided (a plain number as a number, see
L</keep_alive>), or C<undef> if neither is set (letting the engine use its
default).

Composing this role advertises the C<keep_alive> capability, so callers can
dispatch on C<< $engine->supports('keep_alive') >> — see
L<Langertha::Role::Capabilities>.

=head1 SEE ALSO

=over

=item * L<Langertha::Engine::Ollama> - Engine that composes this role

=item * L<Langertha::Role::Capabilities> - Registry that turns this role into the C<keep_alive> flag

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
