package Langertha::Output::Tools;
our $VERSION = '0.307';
# ABSTRACT: Tool output conversion across proxy formats
use strict;
use warnings;
use JSON::MaybeXS qw( encode_json decode_json );

sub extract_from_raw {
  my ($class, $raw) = @_;
  my %meta = (
    text          => '',
    tool_calls    => [],
    finish_reason => undef,
  );
  return \%meta unless ref($raw) eq 'HASH';

  my $msg = $raw->{message};
  if (ref($msg) eq 'HASH') {
    $meta{text} = $msg->{content} // '';
    if (ref($msg->{tool_calls}) eq 'ARRAY') {
      $meta{tool_calls} = $class->_canonicalize_tool_calls($msg->{tool_calls});
    }
    $meta{finish_reason} = $raw->{done_reason} if defined $raw->{done_reason};
    return \%meta;
  }

  my $oai_msg = $raw->{choices}[0]{message};
  if (ref($oai_msg) eq 'HASH') {
    $meta{text} = $oai_msg->{content} // '';
    if (ref($oai_msg->{tool_calls}) eq 'ARRAY') {
      $meta{tool_calls} = $class->_canonicalize_tool_calls($oai_msg->{tool_calls});
    }
    $meta{finish_reason} = $raw->{choices}[0]{finish_reason} if defined $raw->{choices}[0]{finish_reason};
    return \%meta;
  }

  if (ref($raw->{content}) eq 'ARRAY') {
    my @text;
    my @calls;
    for my $block (@{$raw->{content}}) {
      next unless ref($block) eq 'HASH';
      if (($block->{type} // '') eq 'text') {
        push @text, $block->{text} // '';
        next;
      }
      if (($block->{type} // '') eq 'tool_use') {
        push @calls, {
          id        => ($block->{id} // ''),
          name      => ($block->{name} // 'tool'),
          arguments => (ref($block->{input}) eq 'HASH' ? $block->{input} : {}),
        };
      }
    }
    $meta{text} = join('', @text);
    $meta{tool_calls} = \@calls;
    $meta{finish_reason} = $raw->{stop_reason} if defined $raw->{stop_reason};
  }

  return \%meta;
}

sub parse_hermes_calls_from_text {
  my ($class, $text) = @_;
  my @calls;
  my $clean = defined($text) ? $text : '';

  while ($clean =~ m{<tool_call>\s*(.*?)\s*</tool_call>}sg) {
    my $json = $1;
    my $obj = eval { decode_json($json) };
    next unless ref($obj) eq 'HASH';
    next unless defined $obj->{name} && length $obj->{name};
    my $args = $obj->{arguments};
    $args = {} unless ref($args) eq 'HASH';
    push @calls, {
      id        => '',
      name      => $obj->{name},
      arguments => $args,
    };
  }

  $clean =~ s{<tool_call>.*?</tool_call>}{}sg;
  $clean =~ s/^\s+|\s+$//g;
  return ($clean, \@calls);
}

sub to_openai_tool_calls {
  my ($class, $canonical_calls) = @_;
  my @out;
  my $i = 0;
  for my $call (@{$canonical_calls || []}) {
    $i++;
    next unless ref($call) eq 'HASH';
    my $name = $call->{name} // '';
    next unless length $name;
    my $args = ref($call->{arguments}) eq 'HASH' ? $call->{arguments} : {};
    push @out, {
      id       => (length($call->{id} // '') ? $call->{id} : "call_langertha_$i"),
      type     => 'function',
      function => {
        name      => $name,
        arguments => encode_json($args),
      },
    };
  }
  return \@out;
}

sub to_anthropic_tool_use_blocks {
  my ($class, $canonical_calls) = @_;
  my @out;
  my $i = 0;
  for my $call (@{$canonical_calls || []}) {
    $i++;
    next unless ref($call) eq 'HASH';
    my $name = $call->{name} // '';
    next unless length $name;
    my $args = ref($call->{arguments}) eq 'HASH' ? $call->{arguments} : {};
    push @out, {
      type  => 'tool_use',
      id    => (length($call->{id} // '') ? $call->{id} : "toolu_langertha_$i"),
      name  => $name,
      input => $args,
    };
  }
  return \@out;
}

sub to_ollama_tool_calls {
  my ($class, $canonical_calls) = @_;
  my @out;
  for my $call (@{$canonical_calls || []}) {
    next unless ref($call) eq 'HASH';
    my $name = $call->{name} // '';
    next unless length $name;
    my $args = ref($call->{arguments}) eq 'HASH' ? $call->{arguments} : {};
    push @out, {
      function => {
        name      => $name,
        arguments => $args,
      },
      (length($call->{id} // '') ? (id => $call->{id}) : ()),
    };
  }
  return \@out;
}

sub _canonicalize_tool_calls {
  my ($class, $tool_calls) = @_;
  my @out;
  for my $tc (@{$tool_calls || []}) {
    next unless ref($tc) eq 'HASH';
    my $fn = $tc->{function} || {};
    next unless ref($fn) eq 'HASH';
    my $name = $fn->{name} // '';
    next unless length $name;
    my $args = $fn->{arguments};
    my $arguments = {};
    if (ref($args) eq 'HASH') {
      $arguments = $args;
    } elsif (defined $args && length $args) {
      my $decoded = eval { decode_json($args) };
      $arguments = $decoded if ref($decoded) eq 'HASH';
    }
    push @out, {
      id        => ($tc->{id} // ''),
      name      => $name,
      arguments => $arguments,
    };
  }
  return \@out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Output::Tools - Tool output conversion across proxy formats

=head1 VERSION

version 0.307

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
