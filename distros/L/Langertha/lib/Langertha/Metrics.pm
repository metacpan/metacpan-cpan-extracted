package Langertha::Metrics;
our $VERSION = '0.401';
# ABSTRACT: Backwards-compat facade over Langertha::Usage / Pricing / Cost / UsageRecord
use strict;
use warnings;
use Carp ();
use Langertha::Usage;
use Langertha::Pricing;
use Langertha::Cost;
use Langertha::UsageRecord;

Carp::carp(
  "Langertha::Metrics is a backwards-compatibility facade. New code should use "
  . "Langertha::Usage / Langertha::Pricing / Langertha::Cost / Langertha::UsageRecord directly."
);

# All methods here are kept for backwards compatibility with existing
# Skeid/Knarr code. New code should construct Langertha::Usage,
# Langertha::Pricing, and Langertha::UsageRecord directly.

sub normalize_usage {
  my ($class, $usage) = @_;
  return Langertha::Usage->from_hash($usage)->to_hash;
}

sub usage_from_response {
  my ($class, $response) = @_;
  return Langertha::Usage->from_response($response)->to_hash;
}

sub normalize_tool_metrics {
  my ($class, $tool_calls) = @_;
  my @names;
  for my $tc ( @{ $tool_calls || [] } ) {
    next unless ref($tc) eq 'HASH';
    my $name = $tc->{name};
    if ( !defined $name && ref( $tc->{function} ) eq 'HASH' ) {
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
  my $usage = Langertha::Usage->from_hash( $args{usage} || {} );
  my $rule  = $args{pricing} || {};
  my $pricing = Langertha::Pricing->new( default_rule => $rule );
  my $cost = $pricing->cost_for( $usage, undef );
  return $cost->to_hash;
}

sub build_record {
  my ($class, %args) = @_;
  my $usage = Langertha::Usage->from_hash(
    $args{usage}
      || ( ( $args{response} && ref( $args{response} ) eq 'HASH' ) ? $args{response}{usage} : {} )
      || {}
  );
  my $tool = $class->normalize_tool_metrics( $args{tool_calls} || [] );

  my $pricing_rule = $args{pricing} || {};
  my $pricing = Langertha::Pricing->new( default_rule => $pricing_rule );
  my $cost = $pricing->cost_for( $usage, $args{model} );

  my $record = Langertha::UsageRecord->new(
    usage           => $usage,
    cost            => $cost,
    provider        => $args{provider},
    engine          => $args{engine},
    model           => $args{model},
    route           => $args{route},
    api_key_id      => $args{api_key_id},
    duration_ms     => $args{duration_ms},
    started_at      => $args{started_at},
    finished_at     => $args{finished_at},
    tool_calls      => $tool->{tool_calls},
    tool_names      => $tool->{tool_names},
    pricing_version => $args{pricing_version},
  );
  return $record->to_hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Metrics - Backwards-compat facade over Langertha::Usage / Pricing / Cost / UsageRecord

=head1 VERSION

version 0.401

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha/issues>.

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
