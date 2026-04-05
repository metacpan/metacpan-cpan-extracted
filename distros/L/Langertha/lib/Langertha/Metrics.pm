package Langertha::Metrics;
our $VERSION = '0.308';
# ABSTRACT: Metrics and pricing helpers across Langertha ecosystem
use strict;
use warnings;

sub normalize_usage {
  my ($class, $usage) = @_;
  return {
    input_tokens  => 0,
    output_tokens => 0,
    total_tokens  => 0,
  } unless $usage && ref($usage) eq 'HASH';

  my $input  = $usage->{input_tokens};
  my $output = $usage->{output_tokens};
  my $total  = $usage->{total_tokens};

  $input  = $usage->{prompt_tokens}     if !defined $input  && defined $usage->{prompt_tokens};
  $input  = $usage->{prompt_eval_count} if !defined $input  && defined $usage->{prompt_eval_count};

  $output = $usage->{completion_tokens} if !defined $output && defined $usage->{completion_tokens};
  $output = $usage->{eval_count}        if !defined $output && defined $usage->{eval_count};

  $input  = 0 + ($input  // 0);
  $output = 0 + ($output // 0);
  $total  = defined($total) ? (0 + $total) : ($input + $output);

  return {
    input_tokens  => $input,
    output_tokens => $output,
    total_tokens  => $total,
  };
}

sub usage_from_response {
  my ($class, $response) = @_;
  return $class->normalize_usage({}) unless $response;

  if (ref($response) && eval { $response->isa('Langertha::Response') }) {
    return $class->normalize_usage($response->has_usage ? $response->usage : {});
  }

  if (ref($response) eq 'HASH') {
    return $class->normalize_usage($response->{usage} || {});
  }

  return $class->normalize_usage({});
}

sub normalize_tool_metrics {
  my ($class, $tool_calls) = @_;
  my @names;
  for my $tc (@{$tool_calls || []}) {
    next unless ref($tc) eq 'HASH';
    my $name = $tc->{name};
    if (!defined $name && ref($tc->{function}) eq 'HASH') {
      $name = $tc->{function}{name};
    }
    next unless defined $name && length $name;
    push @names, $name;
  }

  return {
    tool_calls => scalar(@names),
    tool_names => \@names,
  };
}

sub estimate_cost_usd {
  my ($class, %args) = @_;
  my $usage = $class->normalize_usage($args{usage} || {});
  my $pricing = $args{pricing} || {};

  my $input_per_million  = 0 + ($pricing->{input_per_million}  // 0);
  my $output_per_million = 0 + ($pricing->{output_per_million} // 0);

  my $input_cost  = ($usage->{input_tokens}  / 1_000_000) * $input_per_million;
  my $output_cost = ($usage->{output_tokens} / 1_000_000) * $output_per_million;
  my $total_cost  = $input_cost + $output_cost;

  return {
    input_cost_usd  => $input_cost + 0,
    output_cost_usd => $output_cost + 0,
    total_cost_usd  => $total_cost + 0,
    currency        => 'USD',
  };
}

sub build_record {
  my ($class, %args) = @_;
  my $usage = $class->normalize_usage(
    $args{usage}
      || (($args{response} && ref($args{response}) eq 'HASH') ? $args{response}{usage} : {})
      || {}
  );
  my $tool = $class->normalize_tool_metrics($args{tool_calls} || []);
  my $cost = $class->estimate_cost_usd(
    usage   => $usage,
    pricing => ($args{pricing} || {}),
  );

  return {
    provider      => $args{provider},
    engine        => $args{engine},
    model         => $args{model},
    route         => $args{route},
    duration_ms   => (defined $args{duration_ms} ? 0 + $args{duration_ms} : undef),
    started_at    => $args{started_at},
    finished_at   => $args{finished_at},
    input_tokens  => $usage->{input_tokens},
    output_tokens => $usage->{output_tokens},
    total_tokens  => $usage->{total_tokens},
    tool_calls    => $tool->{tool_calls},
    tool_names    => $tool->{tool_names},
    input_cost_usd  => $cost->{input_cost_usd},
    output_cost_usd => $cost->{output_cost_usd},
    total_cost_usd  => $cost->{total_cost_usd},
    currency        => $cost->{currency},
    pricing_version => $args{pricing_version},
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Metrics - Metrics and pricing helpers across Langertha ecosystem

=head1 VERSION

version 0.308

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
