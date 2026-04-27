package Langertha::Input::Tools;
our $VERSION = '0.500';
# ABSTRACT: Backwards-compat facade over Langertha::Tool / Langertha::ToolChoice
use strict;
use warnings;
use Carp ();
use Langertha::Tool;
use Langertha::ToolChoice;

Carp::carp(
  "Langertha::Input::Tools is a backwards-compatibility facade. New code should use "
  . "Langertha::Tool / Langertha::ToolChoice directly."
);

# All methods here are kept for backwards compatibility with Skeid/Knarr
# and other existing consumers. New code should use Langertha::Tool and
# Langertha::ToolChoice directly.

sub normalize_tools {
  my ($class, $tools) = @_;
  return [ map { $_->to_hash } @{ Langertha::Tool->from_list($tools) } ];
}

sub to_openai_tools {
  my ($class, $canonical_tools) = @_;
  my @out;
  for my $hash ( @{ $canonical_tools || [] } ) {
    next unless ref($hash) eq 'HASH';
    my $name = $hash->{name} // 'tool';
    push @out, Langertha::Tool->new(
      name         => $name,
      description  => ( $hash->{description} // '' ),
      input_schema => ( $hash->{input_schema} || { type => 'object', properties => {} } ),
    )->to_openai;
  }
  return \@out;
}

sub to_anthropic_tools {
  my ($class, $canonical_tools) = @_;
  my @out;
  for my $hash ( @{ $canonical_tools || [] } ) {
    next unless ref($hash) eq 'HASH';
    my $name = $hash->{name} // 'tool';
    push @out, Langertha::Tool->new(
      name         => $name,
      description  => ( $hash->{description} // '' ),
      input_schema => ( $hash->{input_schema} || { type => 'object', properties => {} } ),
    )->to_anthropic;
  }
  return \@out;
}

sub normalize_tool_choice {
  my ($class, $tool_choice) = @_;
  my $tc = Langertha::ToolChoice->from_hash($tool_choice);
  return $tc ? $tc->to_hash : undef;
}

sub to_openai_tool_choice {
  my ($class, $canonical_tool_choice) = @_;
  return undef unless ref($canonical_tool_choice) eq 'HASH';
  my $tc = Langertha::ToolChoice->from_hash($canonical_tool_choice);
  return $tc ? $tc->to_openai : undef;
}

sub to_anthropic_tool_choice {
  my ($class, $canonical_tool_choice) = @_;
  return undef unless ref($canonical_tool_choice) eq 'HASH';
  my $tc = Langertha::ToolChoice->from_hash($canonical_tool_choice);
  return $tc ? $tc->to_anthropic : undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Input::Tools - Backwards-compat facade over Langertha::Tool / Langertha::ToolChoice

=head1 VERSION

version 0.500

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
