package Langertha::Raider::Hall::Raider;
our $VERSION = '0.503';
# ABSTRACT: Internal record of a raider process spawned by the hall


use Moose;
use namespace::autoclean;
use JSON::MaybeXS;

has id => (is => 'ro', isa => 'Str', required => 1);
has pid => (is => 'ro', isa => 'Int', predicate => 'has_pid');
has slot_name => (is => 'ro', isa => 'Str', required => 1);
has base_name => (is => 'ro', isa => 'Str', required => 1);
has log_path => (is => 'ro', isa => 'Path::Tiny', required => 1);
has mission => (is => 'ro', isa => 'Str', required => 1);


has events_path => (is => 'ro', isa => 'Path::Tiny', predicate => 'has_events_path');


has session_id => (is => 'ro', isa => 'Str', predicate => 'has_session_id');
has binding => (is => 'ro', isa => 'Str', predicate => 'has_binding');


sub run_finished {
  my ( $self ) = @_;
  return unless $self->has_events_path && -f $self->events_path;
  my $json = JSON::MaybeXS->new( utf8 => 1 );
  for my $line ( reverse $self->events_path->lines_raw({ chomp => 1 }) ) {
    my $event = eval { $json->decode($line) };
    next unless ref $event eq 'HASH' && ( $event->{type} // '' ) eq 'run.finished';
    delete @{$event}{qw( type seq time )};
    return $event;
  }
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Hall::Raider - Internal record of a raider process spawned by the hall

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Data object the L<Langertha::Raider::Hall> keeps per running raider, keyed by run ID:
id, pid, slot and base name, log path, events path, mission and, for a
bound run, its session and binding.

=head2 events_path

The file the raider's C<--stream-json> stdout goes to, one file per run.
Optional; without it L</run_finished> has nothing to read.

=head2 session_id

The session the hall started a bound run with (C<--session ID>).
Unset for an unbound run, which picks its own session.

=head2 binding

The binding key of a bound run (C<telegram:ops:42>, C<cron:nightly>,
C<slot:1bjorn>, ...); see L<Langertha::Raider::Hall/session_bindings>.

=head2 run_finished

    my $doc = $raider->run_finished;   # HashRef or undef

The payload of the last C<run.finished> event in L</events_path>: the run's
C<--json> document (C<version>, C<status>, C<response> or C<error>, ...),
without the event fields C<type>, C<seq> and C<time>. Undef when the file is
missing or holds no C<run.finished> -- the process was killed before it
could write one, for example. Lines that are not JSON objects are skipped.

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
