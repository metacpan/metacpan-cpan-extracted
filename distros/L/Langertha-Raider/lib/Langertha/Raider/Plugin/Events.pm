package Langertha::Raider::Plugin::Events;
our $VERSION = '0.503';
# ABSTRACT: Report a raid's tool calls and results as machine-output events

use Moose;
use namespace::autoclean;
use Future::AsyncAwait;
use JSON::MaybeXS ();

extends 'Langertha::Plugin';


has on_event => (
  is       => 'ro',
  isa      => 'CodeRef',
  required => 1,
);

has _calls => ( is => 'rw', init_arg => undef, default => 0 );

async sub plugin_before_raid {
  my ( $self, $messages ) = @_;
  $self->_calls(0);
  return $messages;
}

async sub plugin_before_tool_call {
  my ( $self, $name, $input ) = @_;
  $self->_calls($self->_calls + 1);
  $self->on_event->('tool.call', call => $self->_call_id, name => $name, arguments => $input // {},
    status => 'dispatched');
  return ( $name, $input );
}

# Tool calls run one after another, so a result belongs to the last call.
sub _call_id { 'c'.$_[0]->_calls }

async sub plugin_after_tool_call {
  my ( $self, $name, $input, $result ) = @_;
  my ( $text, $ok ) = ref $result eq 'HASH'
    ? ( join('', map { $_->{text} // '' } grep { ref $_ eq 'HASH' }
        ref $result->{content} eq 'ARRAY' ? @{ $result->{content} } : ()),
        !$result->{isError} )
    : ( $result // '', 1 );
  $self->on_event->('tool.result',
    call    => $self->_call_id,
    name    => $name,
    status  => ref $result eq 'HASH' && $result->{cancelled} ? 'cancelled' : $ok ? 'succeeded' : 'failed',
    ok      => $ok ? JSON::MaybeXS->true : JSON::MaybeXS->false,
    size    => length $text,
    content => $text,
  );
  return $result;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Plugin::Events - Report a raid's tool calls and results as machine-output events

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    my $raider = Langertha::Raider->new(
        engine  => $engine,
        plugins => [ '+Langertha::Raider::Plugin::Events' => {
          on_event => sub { my ( $type, %payload ) = @_; ... },
        } ],
    );

=head1 DESCRIPTION

The source of the C<tool.call> and C<tool.result> events of a raid: the
output of C<raider --stream-json> and its siblings (ADR 0013) and the
session journal (ADR 0015) are both fed from here. Every tool call the raid
makes is handed to L</on_event> twice: before it runs, with its name and
arguments, and after, with the outcome and the whole text of its result --
a consumer that shows less (the stream) cuts it itself.

Load it after any plugin that may skip or rewrite a tool call, so the
events describe the call that actually runs.

=head2 on_event

Code reference called as C<< $on_event->($type, %payload) >>. Required.

=over

=item C<tool.call> -- C<call> (the id of the call within the raid: C<c1>,
C<c2>, ...), C<name>, C<arguments> and C<status> (C<dispatched>).

=item C<tool.result> -- C<call> (the id of its C<tool.call>), C<name>,
C<status> (C<cancelled> for a call cut off by L<Langertha::Raider/cancel>,
C<failed> when the tool reported an error, else C<succeeded>),
C<ok> (the same as a boolean), C<size> (characters of the text) and
C<content> (the whole text).

=back

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI::Machine>

=item * L<Langertha::Plugin>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
