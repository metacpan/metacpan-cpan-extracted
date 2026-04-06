package Langertha::Raid;
# ABSTRACT: Base class for orchestrating Runnable steps
our $VERSION = '0.309';
use Moose;
use Future::AsyncAwait;
use Carp qw( croak );
use Scalar::Util qw( blessed );

use Langertha::Result;
use Langertha::RunContext;

with 'Langertha::Role::Runnable';


has steps => (
  is      => 'ro',
  isa     => 'ArrayRef',
  default => sub { [] },
);


has name => (
  is        => 'ro',
  isa       => 'Str',
  predicate => 'has_name',
);


sub BUILD {
  my ( $self ) = @_;
  $self->_validate_steps($self->steps);
}

sub _validate_steps {
  my ( $self, $steps ) = @_;
  for my $idx (0..$#{$steps}) {
    my $step = $steps->[$idx];
    croak "Invalid step at index $idx: expected Runnable object"
      unless blessed($step) && $step->can('run_f');
  }
  return;
}


sub _coerce_context {
  my ( $self, $ctx ) = @_;
  return $ctx if blessed($ctx) && $ctx->isa('Langertha::RunContext');
  return Langertha::RunContext->new(input => $ctx);
}


sub _step_label {
  my ( $self, $step, $idx ) = @_;
  return $step->name if $step->can('name') && defined $step->name;
  return ref($step) . "[$idx]";
}

sub _normalize_result {
  my ( $self, $raw ) = @_;

  if (blessed($raw) && $raw->isa('Langertha::Result')) {
    return $raw;
  }

  if (!ref($raw)) {
    return Langertha::Result->final($raw);
  }

  if (ref($raw) eq 'HASH') {
    my %args = (
      type => ($raw->{type} // 'final'),
      (exists $raw->{text}    ? (text    => $raw->{text})    : ()),
      (exists $raw->{content} ? (content => $raw->{content}) : ()),
      (exists $raw->{options} ? (options => $raw->{options}) : ()),
      (exists $raw->{data}    ? (data    => $raw->{data})    : ()),
    );
    return Langertha::Result->new(%args);
  }

  croak "Unsupported step result type from ".(blessed($raw) || ref($raw) || 'scalar');
}


sub _with_context_result {
  my ( $self, $result, $ctx ) = @_;
  return $result->with_context($ctx)
    if $result->can('with_context');

  return Langertha::Result->new(
    %{$result->as_hash},
    context => $ctx,
  );
}

sub _apply_final_result_to_context {
  my ( $self, $ctx, $result, %extra ) = @_;
  if ($result->has_text) {
    $ctx->input($result->text);
    $ctx->state->{last_output} = $result->text;
  }
  $ctx->state->{last_result_type} = $result->type;
  $ctx->state->{last_result} = $result->as_hash;
  if ($extra{step_name}) {
    $ctx->metadata->{last_step_name} = $extra{step_name};
  }
  return $ctx;
}

async sub _run_steps_sequentially_f {
  my ( $self, $ctx, %opts ) = @_;
  my @steps = @{$self->steps};

  my $last = Langertha::Result->final($ctx->input // '');

  for my $idx (0..$#steps) {
    my $step = $steps[$idx];
    my $step_name = $self->_step_label($step, $idx);
    my $raw;

    my $ok = eval {
      $raw = await $step->run_f($ctx);
      1;
    };

    if (!$ok) {
      my $err = $@ || 'Unknown step error';
      chomp $err;
      my $abort = Langertha::Result->abort("Step '$step_name' failed: $err");
      $ctx->add_trace({
        node        => ref($self),
        event       => 'step_error',
        step_index  => $idx,
        step_name   => $step_name,
        result_type => 'abort',
      });
      $ctx->state->{last_result_type} = 'abort';
      return $self->_with_context_result($abort, $ctx);
    }

    my $result = $self->_normalize_result($raw);
    $ctx->add_trace({
      node        => ref($self),
      event       => 'step_result',
      step_index  => $idx,
      step_name   => $step_name,
      result_type => $result->type,
      ($opts{loop_iteration} ? (loop_iteration => $opts{loop_iteration}) : ()),
    });

    if ($result->is_final) {
      $self->_apply_final_result_to_context($ctx, $result, step_name => $step_name);
      $last = $result;
      next;
    }

    $ctx->state->{last_result_type} = $result->type;
    $ctx->state->{last_result} = $result->as_hash;
    return $self->_with_context_result($result, $ctx);
  }

  return $self->_with_context_result($last, $ctx);
}


async sub run_f {
  croak ref($_[0])." is abstract; use a Raid subclass";
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raid - Base class for orchestrating Runnable steps

=head1 VERSION

version 0.309

=head1 SYNOPSIS

    my $raid = Langertha::Raid::Sequential->new(
      steps => [ $raider_a, $raider_b ],
    );

    my $ctx = Langertha::RunContext->new(input => 'start');
    my $result = await $raid->run_f($ctx);

=head1 DESCRIPTION

Abstract orchestration base class for runnable workflows. Holds child steps
that implement C<run_f($ctx)> and provides shared helpers for context
coercion, step validation, result normalization, and sequential step driving.

=head2 steps

Ordered child nodes. Each step must implement C<run_f>.

=head2 name

Optional human-friendly node name used in traces and diagnostics.

=head2 _validate_steps

Internal step validation used at construction.

=head2 _coerce_context

Internal helper that normalizes scalar/array input into L<Langertha::RunContext>.

=head2 _normalize_result

Internal helper to normalize scalar/hash/object returns into L<Langertha::Result>.

=head2 _run_steps_sequentially_f

Internal sequential executor used by sequential/loop orchestrators.
Stops early and propagates C<question>, C<pause>, and C<abort>.

=head2 run_f

Abstract execution method required by C<Langertha::Role::Runnable>.
Concrete subclasses must implement it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
