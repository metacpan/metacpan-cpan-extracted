package Langertha::Raider::ToolArgs;
# ABSTRACT: Internal check of a tool call's arguments against the tool's inputSchema
our $VERSION = '0.503';

use strict;
use warnings;
use JSON::MaybeXS qw( is_bool );
use Scalar::Util qw( blessed looks_like_number );

use Exporter 'import';
our @EXPORT_OK = qw( tool_args_problems );


sub tool_args_problems {
  my ( $schema, $args ) = @_;
  return unless ref $schema eq 'HASH';
  my $explicit_object = _type_includes($schema->{type}, 'object');
  return if defined $schema->{type} && !$explicit_object;

  $args //= {};
  unless (ref $args eq 'HASH' && !blessed $args) {
    return $explicit_object ? ( 'arguments must be an object, got '._type_of($args) ) : ();
  }

  my ( @problems, %required );
  if (ref $schema->{required} eq 'ARRAY') {
    for my $key (@{$schema->{required}}) {
      next if !defined $key || ref $key;
      $required{$key} = 1;
      push @problems, "missing required property '".$key."'" unless exists $args->{$key};
    }
  }

  my $properties = $schema->{properties};
  return @problems unless ref $properties eq 'HASH';
  for my $key (sort keys %$args) {
    my $prop = $properties->{$key};
    next unless ref $prop eq 'HASH' && defined $prop->{type};
    my $value = $args->{$key};
    next if !defined $value && !$required{$key};
    my @types = ref $prop->{type} eq 'ARRAY' ? @{$prop->{type}} : ( $prop->{type} );
    my $known = 0;
    my $match = 0;
    for my $type (@types) {
      next if ref $type;
      my $check = _type_check($type) or next;
      $known = 1;
      if ($check->($value)) { $match = 1; last }
    }
    next if $match || !$known;
    push @problems, "property '".$key."' must be ".join(' or ', grep { !ref } @types)
      .', got '._type_of($value);
  }
  return @problems;
}

# True when the schema's type (a name or a list of names) includes $want.
sub _type_includes {
  my ( $type, $want ) = @_;
  return 0 unless defined $type;
  return ( grep { defined && !ref && $_ eq $want } @$type ) ? 1 : 0 if ref $type eq 'ARRAY';
  return !ref $type && $type eq $want ? 1 : 0;
}

# A plain scalar: defined, no reference, no JSON boolean.
sub _plain_scalar {
  my ( $v ) = @_;
  return defined $v && !ref $v && !is_bool($v);
}

sub _number {
  my ( $v ) = @_;
  return _plain_scalar($v) && looks_like_number($v) && $v == $v && $v !~ /\A\s*[-+]?inf/i;
}

my %TYPE_CHECK = (
  string  => sub { _plain_scalar($_[0]) },
  number  => sub { _number($_[0]) },
  integer => sub { _number($_[0]) && $_[0] == int $_[0] },
  boolean => sub { is_bool($_[0]) || ( _plain_scalar($_[0]) && $_[0] =~ /\A[01]\z/ ) },
  object  => sub { ref $_[0] eq 'HASH' },
  array   => sub { ref $_[0] eq 'ARRAY' },
  null    => sub { !defined $_[0] },
);

sub _type_check { $TYPE_CHECK{$_[0]} }

# The JSON type name of a decoded value, for the message.
sub _type_of {
  my ( $v ) = @_;
  return !defined $v ? 'null'
    : is_bool($v) ? 'boolean'
    : ref $v eq 'HASH' ? 'object'
    : ref $v eq 'ARRAY' ? 'array'
    : ref $v ? lc ref $v
    : looks_like_number($v) ? 'number'
    : 'string';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::ToolArgs - Internal check of a tool call's arguments against the tool's inputSchema

=head1 VERSION

version 0.503

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The C<validate> step of the one execution path every tool call of a raid
takes (ADR 0005): before a tool runs, its arguments are held against the
C<inputSchema> the model was shown. Only what is clearly wrong is reported --
a C<required> key that is missing, or a top-level property whose value does
not have the C<type> the schema names. Everything JSON Schema says beyond that
(C<enum>, C<additionalProperties>, nested schemas, C<anyOf>, formats, ...) is
not checked here: the tool itself still answers for it.

It stays lenient where Perl cannot tell or the model's slip does no harm:

=over

=item * A numeric string passes as C<number> / C<integer> (C<"5"> for an
integer), and a number passes as C<string>. Perl tools coerce either way, and
after any numeric use a Perl scalar no longer says which one it was.

=item * C<0> / C<1> pass as C<boolean>, as Perl code writes booleans. The
strings C<"true"> / C<"false"> do not: C<"false"> is true in Perl.

=item * C<null> for a property that is not C<required> counts as absent.

=item * No schema, a schema whose C<type> is not C<object>, a property
without C<type>, and a type name not listed below: nothing is checked.

=back

=head2 tool_args_problems

    my @problems = tool_args_problems($input_schema, $arguments);

Returns one message per violation, C<required> keys first (in schema order),
then property types (by name); the empty list when the arguments pass.
C<undef> arguments count as C<{}>. Known types: C<string>, C<number>,
C<integer>, C<boolean>, C<object>, C<array>, C<null>, also as a list
(C<< type => [ 'string', 'null' ] >>).

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
