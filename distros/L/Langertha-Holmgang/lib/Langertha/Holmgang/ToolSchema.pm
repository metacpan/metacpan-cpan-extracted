package Langertha::Holmgang::ToolSchema;
# ABSTRACT: The JSON Schema subset of tool parameters, checked at load and per call

use strict;
use warnings;
use utf8;

use Exporter qw( import );
use JSON::MaybeXS ();
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Expectation qw( same_scalar );

our $VERSION = '0.002';

our @EXPORT_OK = qw( check_schema schema_errors );

# the subset of JSON Schema a tool's parameters may use; a true constant
our @SCHEMA_KEYS = qw( type required properties items enum const pattern
  minLength maxLength minimum maximum minItems maxItems description title );

my %TYPE = map { $_ => 1 } qw( object array string number integer boolean null );


sub _refuse { Langertha::Holmgang::Error->throw(@_) }


sub check_schema {
  my ( $s, $field ) = @_;
  _refuse( $field, 'not a hash' ) unless ref $s eq 'HASH';
  for my $k ( sort keys %$s ) {
    _refuse( $field.'.'.$k, 'unknown key' ) unless grep { $_ eq $k } @SCHEMA_KEYS;
  }
  if ( exists $s->{type} ) {
    my $t = $s->{type};
    if ( ref $t eq 'ARRAY' ) {
      _refuse( $field.'.type', 'empty list' ) unless @$t;
      my %seen;
      for my $i ( 0 .. $#$t ) {
        my $x = $t->[$i];
        _refuse( $field.'.type['.$i.']', 'unknown type' ) unless defined $x && !ref $x && $TYPE{$x};
        _refuse( $field.'.type['.$i.']', 'named twice' ) if $seen{$x}++;
      }
    }
    else {
      _refuse( $field.'.type', 'unknown type' ) unless defined $t && !ref $t && $TYPE{$t};
    }
  }
  if ( exists $s->{pattern} ) {
    my $p = $s->{pattern};
    _refuse( $field.'.pattern', 'text missing' ) if !defined $p || ref $p || !length $p;
    _refuse( $field.'.pattern', 'invalid regular expression' ) unless eval { qr/$p/; 1 };
  }
  if ( exists $s->{properties} ) {
    _refuse( $field.'.properties', 'not a hash' ) unless ref $s->{properties} eq 'HASH';
    check_schema( $s->{properties}{$_}, $field.'.properties.'.$_ ) for sort keys %{ $s->{properties} };
  }
  check_schema( $s->{items}, $field.'.items' ) if exists $s->{items};
  _refuse( $field.'.required', 'not a list' ) if exists $s->{required} && ref $s->{required} ne 'ARRAY';
  _refuse( $field.'.enum', 'not a list' )     if exists $s->{enum}     && ref $s->{enum} ne 'ARRAY';
  _refuse( $field.'.const', 'not a scalar' )
    if exists $s->{const} && ( !defined $s->{const} || ref $s->{const} && !JSON::MaybeXS::is_bool( $s->{const} ) );
  return $s;
}

sub _is_type {
  my ( $d, $t ) = @_;
  return $t eq 'object'  ? ref $d eq 'HASH'
    :    $t eq 'array'   ? ref $d eq 'ARRAY'
    :    $t eq 'null'    ? !defined $d
    :    $t eq 'boolean' ? JSON::MaybeXS::is_bool($d)
    :    $t eq 'integer' ? ( defined $d && !ref $d && "$d" =~ /\A-?\d+\z/ )
    :    $t eq 'number'  ? ( defined $d && !ref $d && "$d" =~ /\A-?\d+(?:\.\d+)?\z/ )
    :    $t eq 'string'  ? ( defined $d && !ref $d )
    :                      0;
}


sub schema_errors {
  my ( $d, $s, $at ) = @_;
  $at //= '$';
  return () unless ref $s eq 'HASH';
  my @e;
  if ( defined( my $t = $s->{type} ) ) {
    my @t = ref $t eq 'ARRAY' ? @$t : $t;
    return ( $at.': erwartet '.join( ' oder ', @t ) ) unless grep { _is_type( $d, $_ ) } @t;
  }
  if ( $s->{enum} && !grep { defined $d ? same_scalar( $d, $_ ) : !defined $_ } @{ $s->{enum} } ) {
    push @e, $at.': erlaubt sind '.join( ', ', map { $_ // 'null' } @{ $s->{enum} } );
  }
  if ( exists $s->{const} && !same_scalar( $d, $s->{const} ) ) {
    my $c = $s->{const};
    push @e, $at.': erlaubt ist '.( JSON::MaybeXS::is_bool($c) ? ( $c ? 'true' : 'false' ) : $c );
  }
  if ( defined $d && !ref $d ) {
    push @e, $at.': zu kurz' if defined $s->{minLength} && length $d < $s->{minLength};
    push @e, $at.': zu lang' if defined $s->{maxLength} && length $d > $s->{maxLength};
    push @e, $at.': passt nicht zu '.$s->{pattern} if defined $s->{pattern} && $d !~ /$s->{pattern}/;
    if ( "$d" =~ /\A-?\d+(?:\.\d+)?\z/ ) {
      push @e, $at.': kleiner als '.$s->{minimum} if defined $s->{minimum} && $d < $s->{minimum};
      push @e, $at.': größer als '.$s->{maximum}  if defined $s->{maximum} && $d > $s->{maximum};
    }
  }
  if ( ref $d eq 'HASH' ) {
    for my $k ( @{ $s->{required} || [] } ) {
      push @e, $at.'.'.$k.': fehlt' unless exists $d->{$k};
    }
    my $p = $s->{properties} || {};
    for my $k ( sort keys %$p ) {
      push @e, schema_errors( $d->{$k}, $p->{$k}, $at.'.'.$k ) if exists $d->{$k};
    }
  }
  if ( ref $d eq 'ARRAY' ) {
    push @e, $at.': zu wenige Einträge' if defined $s->{minItems} && @$d < $s->{minItems};
    push @e, $at.': zu viele Einträge'  if defined $s->{maxItems} && @$d > $s->{maxItems};
    if ( $s->{items} ) {
      push @e, schema_errors( $d->[$_], $s->{items}, $at.'['.$_.']' ) for 0 .. $#$d;
    }
  }
  return @e;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::ToolSchema - The JSON Schema subset of tool parameters, checked at load and per call

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::ToolSchema qw( check_schema schema_errors );

  check_schema( $tool->{parameters}, 'suite.yaml: tools[0].parameters' );   # at load

  my @errors = schema_errors( $args, $tool->{parameters} );                 # per call
  # ( '$.dst: fehlt', '$.metric: erwartet integer' )

=head1 DESCRIPTION

Tool parameters are a subset of JSON Schema: the keys C<type>, C<required>,
C<properties>, C<items>, C<enum>, C<const>, C<pattern>, C<minLength>,
C<maxLength>, C<minimum>, C<maximum>, C<minItems>, C<maxItems>,
C<description>, C<title>, nested through C<properties> and C<items>.

L</check_schema> is the shape check of the loader: anything else is a loud
L<Langertha::Holmgang::Error>. L</schema_errors> checks the arguments of one
call; its texts go to the model (after C<Fehler: Argumente passen nicht zum
Schema:>) and are therefore German, as the suites expect them. Integers and
numbers may arrive as text (C<"3">), as many models send them. C<enum> and
C<const> compare like the expectations do. Unlike cai-platform, which accepts
C<const> but never checks it, C<const> holds per call: the schema the model
sees means what it says.

C<type> may be a list of types, as JSON Schema has it
(C<< type: [string, "null"] >>): the value fits when it fits one of them,
and the model reads C<erwartet string oder null>. The other keys apply as
they stand: an C<enum> beside C<"null"> has to list C<null> for a null to
pass, as in JSON Schema, and a null in C<enum> matches a null (in
cai-platform it matches nothing). cai-platform refuses a type list at load.

=head2 check_schema

  check_schema( $schema, $field );

Refuses an unknown key, an unknown C<type> (a name, or a list of names
that is not empty and names none twice), an invalid C<pattern>, a
C<properties> that is not a hash, a C<required> or C<enum> that is not a
list and a C<const> that is not a scalar (text, number or boolean) —
recursively, with the field path. Returns the schema.

=head2 schema_errors

  my @errors = schema_errors( $data, $schema );

The violations of C<$data> against C<$schema>, each with its path from C<$>
(C<$.dst>, C<$.peers[1]>); empty when the data fit.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
