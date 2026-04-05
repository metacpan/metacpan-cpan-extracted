package Langertha::Input::Tools;
our $VERSION = '0.308';
# ABSTRACT: Tool input conversion across proxy formats
use strict;
use warnings;

sub normalize_tools {
  my ($class, $tools) = @_;
  my @out;
  for my $t (@{$tools || []}) {
    next unless ref($t) eq 'HASH';

    # OpenAI/Ollama style
    if (($t->{type} // '') eq 'function' && ref($t->{function}) eq 'HASH') {
      my $fn = $t->{function};
      my $name = $fn->{name} // '';
      next unless length $name;
      push @out, {
        name         => $name,
        description  => ($fn->{description} // ''),
        input_schema => ($fn->{parameters} || { type => 'object', properties => {} }),
      };
      next;
    }

    # Anthropic style
    if (defined $t->{name}) {
      my $name = $t->{name} // '';
      next unless length $name;
      push @out, {
        name         => $name,
        description  => ($t->{description} // ''),
        input_schema => ($t->{input_schema} || $t->{parameters} || { type => 'object', properties => {} }),
      };
    }
  }
  return \@out;
}

sub to_openai_tools {
  my ($class, $canonical_tools) = @_;
  return [map {
    {
      type     => 'function',
      function => {
        name        => ($_->{name} // 'tool'),
        description => ($_->{description} // ''),
        parameters  => ($_->{input_schema} || { type => 'object', properties => {} }),
      },
    }
  } @{$canonical_tools || []}];
}

sub to_anthropic_tools {
  my ($class, $canonical_tools) = @_;
  return [map {
    {
      name         => ($_->{name} // 'tool'),
      description  => ($_->{description} // ''),
      input_schema => ($_->{input_schema} || { type => 'object', properties => {} }),
    }
  } @{$canonical_tools || []}];
}

sub normalize_tool_choice {
  my ($class, $tool_choice) = @_;
  return undef unless defined $tool_choice;

  if (!ref($tool_choice)) {
    return { type => 'any' }  if $tool_choice eq 'required';
    return { type => 'auto' } if $tool_choice eq 'auto';
    return { type => 'none' } if $tool_choice eq 'none';
    return undef;
  }

  return undef unless ref($tool_choice) eq 'HASH';
  my $type = $tool_choice->{type} // '';

  if ($type eq 'function') {
    my $name = '';
    if (ref($tool_choice->{function}) eq 'HASH') {
      $name = $tool_choice->{function}{name} // '';
    } elsif (defined $tool_choice->{name}) {
      $name = $tool_choice->{name} // '';
    }
    return length($name) ? { type => 'tool', name => $name } : { type => 'auto' };
  }

  if ($type eq 'tool') {
    my $name = $tool_choice->{name} // '';
    return length($name) ? { type => 'tool', name => $name } : { type => 'auto' };
  }

  return { type => 'any' }  if $type eq 'any';
  return { type => 'auto' } if $type eq 'auto';
  return { type => 'none' } if $type eq 'none';
  return undef;
}

sub to_openai_tool_choice {
  my ($class, $canonical_tool_choice) = @_;
  return undef unless ref($canonical_tool_choice) eq 'HASH';
  my $type = $canonical_tool_choice->{type} // '';

  return 'required' if $type eq 'any';
  return 'auto'     if $type eq 'auto';
  return 'none'     if $type eq 'none';
  if ($type eq 'tool') {
    my $name = $canonical_tool_choice->{name} // '';
    return length($name) ? { type => 'function', function => { name => $name } } : 'auto';
  }
  return undef;
}

sub to_anthropic_tool_choice {
  my ($class, $canonical_tool_choice) = @_;
  return undef unless ref($canonical_tool_choice) eq 'HASH';
  my $type = $canonical_tool_choice->{type} // '';

  return { type => 'any' }  if $type eq 'any';
  return { type => 'auto' } if $type eq 'auto';
  return { type => 'none' } if $type eq 'none';
  if ($type eq 'tool') {
    my $name = $canonical_tool_choice->{name} // '';
    return length($name) ? { type => 'tool', name => $name } : { type => 'auto' };
  }
  return undef;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Input::Tools - Tool input conversion across proxy formats

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
