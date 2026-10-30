package Langertha::Raider::Context::Frontmatter;
# ABSTRACT: Internal lenient reader of the YAML frontmatter of skill and agent files
our $VERSION = '0.504';
use strict;
use warnings;
use YAML::PP ();


sub parse {
  my ( $self, $text, %arg ) = @_;
  my %bool = map { $_ => 1 } @{ $arg{booleans} // [] };
  my ( $fm, $problem ) = ( {}, undef );
  if ($text =~ s/\A---[ \t]*\r?\n(.*?)^---[ \t]*(?:\r?\n|\z)//ms) {
    my $yaml = $1;
    my $data = eval { YAML::PP->new->load_string($yaml) };
    if (my $err = $@) {
      if (my $lenient = $self->lenient($yaml, \%bool)) {
        $fm = $lenient;
      }
      else {
        my ( $line ) = grep { /\S/ } split /\n/, "$err";
        $line //= 'syntax error';
        $line =~ s/ at (?:(?! at ).)+ line \d+\.?\z//;
        $problem = 'invalid frontmatter: '.$line;
      }
    }
    elsif (ref $data eq 'HASH') {
      $fm = $data;
    }
    elsif (defined $data) {
      $problem = 'frontmatter is not a mapping';
    }
  }
  $text =~ s/\A(?:[ \t]*\r?\n)+//;
  return ( $fm, $text, $problem );
}


my $KEY = qr/[A-Za-z0-9_][\w.-]*/;

sub lenient {
  my ( $self, $yaml, $bool ) = @_;
  $bool //= {};
  my ( %fm, %block, $key, $sub );
  for my $line (split /\r?\n/, $yaml) {
    next unless $line =~ /\S/;
    if ($line =~ /\A($KEY):(?:[ \t]+(.*?))?[ \t]*\z/) {
      ( $key, $sub ) = ( $1, undef );
      my $value = $2 // '';
      $block{$key} = $value =~ /\A[|>][+-]?\z/ ? 1 : 0;
      $value = '' if $block{$key};
      $fm{$key} = length $value ? $self->_value($key, $value, $bool) : undef;
      next;
    }
    next if $line =~ /\A#/ || !defined $key || $line !~ /\A[ \t]+(.*?)[ \t]*\z/;
    my $more = $1;
    if (!$block{$key} && ( !defined $fm{$key} || ref $fm{$key} eq 'HASH' )
      && $more =~ /\A($KEY):(?:[ \t]+(.*))?\z/) {
      $sub = $1;
      $fm{$key}{$sub} = defined $2 && length $2 ? $self->_unquote($2) : undef;
      next;
    }
    if (ref $fm{$key} eq 'HASH') {
      next unless defined $sub;
      $self->_continue($fm{$key}, $sub, $more);
      next;
    }
    $self->_continue(\%fm, $key, $more);
  }
  return %fm ? \%fm : undef;
}

# One indented line under $key of $hash: '- item' extends a list, anything
# else continues a scalar.
sub _continue {
  my ( $self, $hash, $key, $more ) = @_;
  if ($more =~ /\A-[ \t]+(.*)\z/ && ( !defined $hash->{$key} || ref $hash->{$key} eq 'ARRAY' )) {
    push @{ $hash->{$key} }, $self->_unquote($1);
  }
  elsif (!ref $hash->{$key}) {
    $hash->{$key} = defined $hash->{$key} && length $hash->{$key} ? $hash->{$key}.' '.$more : $more;
  }
  return;
}

sub _value {
  my ( $self, $key, $value, $bool ) = @_;
  return $value eq 'true' ? !!1 : !!0 if $bool->{$key} && $value =~ /\A(?:true|false)\z/;
  return $self->_unquote($value);
}

sub _unquote {
  my ( $self, $value ) = @_;
  $value =~ s/\A(["'])(.*)\1\z/$2/s;
  return $value;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Frontmatter - Internal lenient reader of the YAML frontmatter of skill and agent files

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my ( $fm, $body, $problem ) = Langertha::Raider::Context::Frontmatter->parse(
      $text, booleans => [qw( disable-model-invocation )],
    );

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one frontmatter reader of the skill catalogue
(L<Langertha::Raider::Context::Skills>) and the agent catalogue
(L<Langertha::Raider::Context::Agents>): Claude Code's Markdown files with
a leading C<---> ... C<---> block.

The block is parsed as YAML. What YAML rejects but Claude Code reads --
typically an unquoted C<: > inside a description -- is read line by line
instead:

=over

=item * C<key: value> at column 0: the value is everything after the first
C<: >, trimmed, outer quotes stripped. The keys named in C<booleans> read
C<true> / C<false> as booleans.

=item * Indented lines continue the previous key, joined with a space;
C<- item> lines make it a list; a C<|> / C<E<gt>> block becomes its lines
joined with spaces.

=item * An indented C<key:> or C<key: value> directly under a key without a
value (not a block) makes a nested mapping, one level deep -- enough for
C<briefing:> / C<skills:> / C<- item>. Its own continuation and C<- item>
lines go to the nested key.

=back

Only when that finds no key either, or the YAML is not a mapping, the
frontmatter is empty and a problem is returned.

=head2 parse

    my ( $fm, $body, $problem ) = $class->parse($text, booleans => \@keys);

The frontmatter as a hash ref (empty without a block), the body without the
frontmatter and its leading blank lines, and a problem -- a short reason
such as C<invalid frontmatter: ...> or C<frontmatter is not a mapping> --
or C<undef>.

=head2 lenient

    my $fm = $class->lenient($yaml, { 'user-invocable' => 1 });

The line reader described above on its own: a hash ref, or C<undef> when it
finds no key. The second argument names the boolean keys.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Skills>

=item * L<Langertha::Raider::Context::Agents>

=back

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
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

L<https://raudssus.de/>

=cut
