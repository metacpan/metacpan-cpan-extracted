package Langertha::Raid::Parallel;
# ABSTRACT: Parallel Raid orchestrator with branched context isolation
our $VERSION = '0.305';
use Moose;
use Future::AsyncAwait;
use Future;

use Langertha::Result;

extends 'Langertha::Raid';


has merge_slot => (
  is      => 'ro',
  isa     => 'Str',
  default => 'parallel_branches',
);


async sub run_f {
  my ( $self, $ctx ) = @_;
  $ctx = $self->_coerce_context($ctx);

  my @steps = @{$self->steps};
  return Langertha::Result->final($ctx->input // '')->with_context($ctx)
    unless @steps;

  $ctx->add_trace({
    node  => ref($self),
    event => 'parallel_start',
    steps => scalar @steps,
  });

  my @futures;
  for my $idx (0..$#steps) {
    my $step = $steps[$idx];
    my $step_name = $self->_step_label($step, $idx);
    my $branch_ctx = $ctx->branch(metadata => {
      parallel_index => $idx,
      parallel_step  => $step_name,
    });

    my $future = $step->run_f($branch_ctx)->then(sub {
      my ( $raw_result ) = @_;
      my $result = $self->_normalize_result($raw_result);
      Future->done({
        index     => $idx,
        step_name => $step_name,
        result    => $result,
        context   => $branch_ctx,
      });
    })->else(sub {
      my ( $err ) = @_;
      chomp($err) if defined $err;
      Future->done({
        index     => $idx,
        step_name => $step_name,
        result    => Langertha::Result->abort("Parallel step '$step_name' failed: $err"),
        context   => $branch_ctx,
      });
    });

    push @futures, $future;
  }

  my @outcomes = await Future->needs_all(@futures);
  @outcomes = sort { $a->{index} <=> $b->{index} } @outcomes;

  for my $outcome (@outcomes) {
    my $slot_name = sprintf('%02d_%s', $outcome->{index}, $outcome->{step_name});
    $ctx->merge_branch($outcome->{context}, slot => $self->merge_slot, name => $slot_name);
    $ctx->add_trace({
      node        => ref($self),
      event       => 'parallel_branch_result',
      step_index  => $outcome->{index},
      step_name   => $outcome->{step_name},
      result_type => $outcome->{result}->type,
    });
  }

  my $winner =
       (grep { $_->{result}->is_abort } @outcomes)[0]
    || (grep { $_->{result}->is_question } @outcomes)[0]
    || (grep { $_->{result}->is_pause } @outcomes)[0];

  if ($winner) {
    $ctx->state->{last_result_type} = $winner->{result}->type;
    $ctx->state->{last_result} = $winner->{result}->as_hash;
    return $self->_with_context_result($winner->{result}, $ctx);
  }

  my @texts = map {
    $_->{result}->has_text ? $_->{result}->text : ()
  } @outcomes;

  my $joined = join("\n", @texts);
  my $final = Langertha::Result->final($joined, data => {
    branch_count => scalar @outcomes,
  });

  $ctx->state->{parallel_results} = [
    map { $_->{result}->as_hash } @outcomes
  ];
  $self->_apply_final_result_to_context($ctx, $final, step_name => ref($self));

  return $self->_with_context_result($final, $ctx);
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raid::Parallel - Parallel Raid orchestrator with branched context isolation

=head1 VERSION

version 0.305

=head1 SYNOPSIS

    my $raid = Langertha::Raid::Parallel->new(
      steps => [ $a, $b, $c ],
    );

    my $result = await $raid->run_f($ctx);

=head1 DESCRIPTION

Runs child steps concurrently using Futures. Each branch receives a cloned
context (via C<< $ctx->branch >>), so branch mutations are isolated.
Branch snapshots are merged back into parent artifacts under C<merge_slot>.

Aggregation strategy:

=over 4

=item * If any branch aborts, first abort is propagated.

=item * Otherwise first question is propagated.

=item * Otherwise first pause is propagated.

=item * Otherwise final branch texts are concatenated with newlines.

=back

=head2 merge_slot

Artifact slot name where merged branch snapshots are stored.

=head2 run_f

    my $result = await $raid->run_f($ctx);

Executes all child steps concurrently with branched context isolation and
deterministic result aggregation.

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
