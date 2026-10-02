package Langertha::Raider::Approval;
# ABSTRACT: Internal approval of one exact tool call, bound to session, run, tool, arguments and policy revision
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS qw( JSON is_bool );


has session_id => ( is => 'ro', isa => 'Str', required => 1 );


has run_id => ( is => 'ro', isa => 'Str', required => 1 );


has tool => ( is => 'ro', isa => 'Str', required => 1 );


has source => ( is => 'ro', isa => 'Str', required => 1 );


has arguments_sha256 => ( is => 'ro', isa => 'Str', required => 1 );


has policy_revision => ( is => 'ro', isa => 'Str', required => 1 );


sub _bound_fields { qw( session_id run_id tool source arguments_sha256 policy_revision ) }

# The binding of a call in its context, as constructor arguments. A missing
# field stays undef; the callers decide what that means.
sub _binding {
  my ( $self, %arg ) = @_;
  my $call = $arg{call};
  croak __PACKAGE__.' call must be a hash of name, source and arguments'
    unless ref $call eq 'HASH';
  return (
    session_id       => $arg{session_id},
    run_id           => $arg{run_id},
    policy_revision  => $arg{policy_revision},
    tool             => $call->{name},
    source           => $call->{source},
    arguments_sha256 => $self->digest_arguments($call->{arguments}),
  );
}

sub for_call {
  my ( $class, %arg ) = @_;
  my %binding = $class->_binding(%arg);
  for my $field ($class->_bound_fields) {
    croak __PACKAGE__.'->for_call needs '.$field unless defined $binding{$field};
  }
  return $class->new(%binding);
}


sub covers {
  my ( $self, %arg ) = @_;
  my %binding = $self->_binding(%arg);
  for my $field ($self->_bound_fields) {
    return unless defined $binding{$field} && $binding{$field} eq $self->$field;
  }
  return 1;
}


sub digest_arguments {
  my ( $self, $arguments ) = @_;
  my $json = JSON::MaybeXS->new( utf8 => 1, canonical => 1, allow_nonref => 1 );
  return sha256_hex( $json->encode( $self->_canonical_value($arguments) ) );
}


# A copy of $value that encodes the same whatever Perl last did with its
# scalars (see digest_arguments). Returns undef as a value, not an empty list:
# it lands in a hash or array slot.
sub _canonical_value {
  my ( $self, $value ) = @_;
  return undef unless defined $value;
  return $value ? JSON->true : JSON->false if is_bool($value);
  my $ref = ref $value;
  return "$value" unless $ref;
  return { map { $_ => $self->_canonical_value($value->{$_}) } keys %$value } if $ref eq 'HASH';
  return [ map { $self->_canonical_value($_) } @$value ] if $ref eq 'ARRAY';
  croak __PACKAGE__.' arguments can hold no '.$ref;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Approval - Internal approval of one exact tool call, bound to session, run, tool, arguments and policy revision

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $approval = Langertha::Raider::Approval->for_call(
      session_id      => $session->id,
      run_id          => $run,
      policy_revision => $revision,
      call            => { name => 'write_file', source => 'engine:1', arguments => \%args },
    );

    # later, for the call about to run -- same named arguments:
    run_it() if $approval->covers(
      session_id => $session->id, run_id => $run, policy_revision => $revision, call => $call,
    );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

An approval as ADR 0005 binds it: to one session, one run, one tool (by name
and source) and one set of arguments, under one policy revision. Any change of
any of these invalidates it -- fixture F20: arguments changed after the
approval are not covered by it. The arguments are held as the SHA-256 of their
canonical JSON (L</digest_arguments>), never by reference, so a hash changed in
place after the approval is seen as changed.

The call is the canonical call the tool gate sees
(C<< { name => ..., source => ..., arguments => ... } >>, see C<_tool_gate> in
L<Langertha::Raider>). This class is pure logic: nothing asks for an approval
or consults one yet, and an approval lives only as long as the run that holds
it -- nothing persists it.

=head2 session_id

The session the approval was given in. Required.

=head2 run_id

The run the approval was given in. Required.

=head2 tool

The name of the approved tool. Required.

=head2 source

Where the approved tool runs, as the tool gate names it (C<raider>,
C<inline>, C<engine:N>, C<catalog:NAME>). Required: the same tool name from
another source is another tool.

=head2 arguments_sha256

The L</digest_arguments> of the approved arguments. Required.

=head2 policy_revision

The revision of the policy the approval was given under. Required; compared
as a string.

=head2 for_call

    my $approval = Langertha::Raider::Approval->for_call(
      session_id => $sid, run_id => $rid, policy_revision => $rev,
      call       => { name => $tool, source => $source, arguments => $args },
    );

Builds the approval of C<call> in its context. Croaks when C<call> is not a
hash, or when the session id, run id, policy revision, tool name or source is
missing. C<arguments> may be absent; it is then bound as C<null>, which is not
the same as C<{}>.

=head2 covers

    if ( $approval->covers( session_id => $sid, run_id => $rid,
                            policy_revision => $rev, call => $call ) ) { ... }

True when the call in its context is exactly the approved one: same session,
run, tool, source, policy revision and canonical arguments. False on any
difference, and false when any of them is missing -- a missing field never
matches. Croaks only when C<call> is not a hash.

=head2 digest_arguments

    my $hex = Langertha::Raider::Approval->digest_arguments(\%args);

The SHA-256 (hex) of the canonical JSON of C<$arguments>: hash keys sorted at
every depth, arrays in order, UTF-8. Before encoding, every plain scalar is
taken by its string form, so C<5> and C<"5"> are the same argument -- the
digest does not depend on whether Perl last used a value as a number or a
string, nor on how the JSON backend writes numbers. C<"1.0"> and C<"1"> stay
different. Booleans (L<JSON::MaybeXS/is_bool>) stay booleans and C<undef>
stays C<null>, so C<true>, C<1>, C<"true">, C<false>, C<0>, C<"">, and
C<null> are all different. Croaks on anything JSON arguments cannot hold:
code refs, objects other than booleans, scalar refs.

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
