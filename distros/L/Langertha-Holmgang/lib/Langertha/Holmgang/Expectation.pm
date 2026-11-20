package Langertha::Holmgang::Expectation;
# ABSTRACT: The expectations on a value, shared by rules, when conditions and check.expect

use strict;
use warnings;
use utf8;

use Carp qw( croak );
use Exporter qw( import );
use JSON::MaybeXS ();
use Scalar::Util qw( looks_like_number );

our $VERSION = '0.002';

our @EXPORT_OK = qw( condition check_value element_match path get flat same_scalar near interp_text filter_value );

# the expectations, in the order they are checked; a true constant
our @MATCHERS = qw( exists absent equals in regex contains excludes length any none before );

# keys that qualify a matcher and are no expectation of their own; a true constant
our @MODIFIERS = qw( tolerance );

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );



sub path {
  my ( $p, $args ) = @_;
  my @seg = ref $p eq 'ARRAY' ? @$p : split /\./, $p;
  croak 'empty path' unless @seg;
  return map { interp_text( "$_", $args ) } @seg;
}


sub get {
  my ( $d, @seg ) = @_;
  for my $k (@seg) {
    next if defined $d && !ref $d && $k eq 'content';    # file as bare text
    if ( ref $d eq 'HASH' ) {
      return (0) unless exists $d->{$k};
      $d = $d->{$k};
    }
    elsif ( ref $d eq 'ARRAY' ) {
      return (0) unless $k =~ /\A\d+\z/ && $k < @$d;
      $d = $d->[$k];
    }
    else { return (0) }
  }
  return ( 1, $d );
}


sub flat {
  my ( $v ) = @_;
  return undef unless defined $v;
  return join( ',', map { $_ // '' } @$v ) if ref $v eq 'ARRAY';
  return $v ? 'true' : 'false' if JSON::MaybeXS::is_bool($v);
  return ref $v ? $JSON->encode($v) : "$v";
}


sub interp_text {
  my ( $s, $args ) = @_;
  $s =~ s/\{([A-Za-z_][A-Za-z0-9_]*)(?:\|([a-z]+))?\}/flat( filter_value( $args->{$1}, $2 ) ) \/\/ ''/ge;
  return $s;
}


sub filter_value {
  my ( $v, $f ) = @_;
  return $v unless defined $f && defined $v;
  if ( $f eq 'split' ) {
    return [ map { my $x = $_; $x =~ s/\A\s+|\s+\z//g; length $x ? $x : () } ref $v eq 'ARRAY' ? @$v : split /[\s,]+/, "$v" ];
  }
  return int( $v =~ /(-?\d+)/ ? $1 : 0 ) if $f eq 'int';
  return lc "$v" if $f eq 'lc';
  die "dieser Aufruf ist in diesem Szenario nicht vorgesehen.\n";
}

sub _interp_re {
  my ( $re, $args ) = @_;
  $re =~ s/\{([A-Za-z_][A-Za-z0-9_]*)\}/quotemeta( flat( $args->{$1} ) \/\/ '' )/ge;
  return $re;
}


sub same_scalar {
  my ( $x, $y ) = @_;
  my $bool = grep { JSON::MaybeXS::is_bool($_) } $x, $y;
  ( $x, $y ) = map { JSON::MaybeXS::is_bool($_) ? ( $_ ? 1 : 0 ) : $_ } $x, $y;
  ( $x, $y ) = map { defined $_ && !ref $_ && /\A(?:true|false)\z/ ? ( $_ eq 'true' ? 1 : 0 ) : $_ } $x, $y if $bool;
  return 0 if !defined $x || !defined $y || ref $x || ref $y;
  my $num = qr/\A-?\d+(?:\.\d+)?\z/;
  return $x == $y ? 1 : 0 if "$x" =~ $num && "$y" =~ $num;
  return "$x" eq "$y" ? 1 : 0;
}


sub near {
  my ( $x, $want, $tol ) = @_;
  return 0 if !defined $x || ref $x || !looks_like_number($x) || $x =~ /\A\s|\s\z/;
  return 0 unless $x == $x && abs($x) != 9**9**9;    # NaN, Inf
  my $slack = 1e-9 * ( abs($want) > 1 ? abs($want) : 1 );
  return abs( $x - $want ) <= $tol + $slack ? 1 : 0;
}

sub _show {
  my ( $v ) = @_;
  my $s = $JSON->encode($v);
  return length $s > 200 ? substr( $s, 0, 200 ).'…' : $s;
}


sub element_match {
  my ( $el, $m, $args ) = @_;
  $args //= {};
  if ( !ref $m ) {
    my $re = _interp_re( $m, $args );
    return defined $el && !ref $el && $el =~ /$re/ ? 1 : 0;
  }
  return 0 unless ref $el eq 'HASH';
  for my $f ( sort keys %$m ) {
    my $spec = $m->{$f};
    if ( ref $spec eq 'HASH' ) {
      my ( $ok ) = check_value( exists $el->{$f}, $el->{$f}, $spec, $args );
      return 0 unless $ok;
      next;
    }
    my $re = _interp_re( $spec, $args );
    my $v  = flat( $el->{$f} );
    return 0 unless defined $v && $v =~ /$re/;
  }
  return 1;
}


sub condition {
  my ( $state, $c, $args ) = @_;
  $args //= {};
  my ( $found, $v ) = get( $state, path( $c->{path}, $args ) );
  return check_value( $found, $v, $c, $args );
}


sub check_value {
  my ( $found, $v, $c, $args ) = @_;
  $args //= {};
  if ( exists $c->{absent} ) {
    my $gone = !$found || !defined $v;
    return ( 0, 'present: '._show($v) ) if $c->{absent} && !$gone;
    return ( 0, 'missing' ) if !$c->{absent} && $gone;
  }
  if ( exists $c->{exists} ) {
    return ( 0, 'missing' ) if $c->{exists} && !$found;
    return ( 0, 'present: '._show($v) ) if !$c->{exists} && $found;
  }
  my @checks = grep { exists $c->{$_} } qw( equals in regex contains excludes length any none before );
  return ( 1, $found ? _show($v) : 'not present' ) unless @checks;
  return ( 0, 'missing' ) unless $found;
  my $text = sub {
    my ( $want ) = @_;
    return !ref $want && ref $v eq 'HASH' && exists $v->{content} && !ref $v->{content} ? $v->{content} : $v;
  };
  if ( exists $c->{equals} && exists $c->{tolerance} ) {
    return ( 0, 'is '._show($v).', not within '.$c->{tolerance}.' of '.$c->{equals} )
      unless near( $text->( $c->{equals} ), $c->{equals}, $c->{tolerance} );
  }
  elsif ( exists $c->{equals} ) {
    return ( 0, 'is '._show($v) ) unless same_scalar( $text->( $c->{equals} ), $c->{equals} );
  }
  if ( exists $c->{in} ) {
    return ( 0, 'is '._show($v) ) unless grep { same_scalar( $text->($_), $_ ) } @{ $c->{in} };
  }
  if ( exists $c->{regex} ) {
    my $re = _interp_re( $c->{regex}, $args );
    my $t = ref $v eq 'HASH' && exists $v->{content} && !ref $v->{content} ? $v->{content} : $v;
    return ( 0, 'is '._show($v) ) unless defined $t && !ref $t && $t =~ /$re/;
  }
  for my $k (qw( contains excludes )) {
    next unless exists $c->{$k};
    return ( 0, 'not a list: '._show($v) ) unless ref $v eq 'ARRAY';
    for my $want ( @{ $c->{$k} } ) {
      my $has = grep { same_scalar( $_, $want ) } @$v;
      return ( 0, $want.' missing in '._show($v) ) if $k eq 'contains' && !$has;
      return ( 0, $want.' present in '._show($v) ) if $k eq 'excludes' && $has;
    }
  }
  if ( exists $c->{length} ) {
    my $n = ref $v eq 'ARRAY' ? @$v : ref $v eq 'HASH' ? keys %$v : -1;
    return ( 0, $n.' entries' ) unless $n == $c->{length};
  }
  for my $k (qw( any none before )) {
    next unless exists $c->{$k};
    return ( 0, 'not a list: '._show($v) ) unless ref $v eq 'ARRAY';
  }
  if ( exists $c->{any} ) {
    return ( 0, 'no matching entry in '._show($v) ) unless grep { element_match( $_, $c->{any}, $args ) } @$v;
  }
  if ( exists $c->{none} ) {
    my ( $hit ) = grep { element_match( $_, $c->{none}, $args ) } @$v;
    return ( 0, 'unwanted entry: '._show($hit) ) if defined $hit;
  }
  if ( exists $c->{before} ) {
    my ( $first, $second ) = map {
      my $m = $_;
      my ( $i ) = grep { element_match( $v->[$_], $m, $args ) } 0 .. $#$v;
      $i;
    } @{ $c->{before} };
    return ( 0, 'first entry missing' )  unless defined $first;
    return ( 0, 'second entry missing' ) unless defined $second;
    return ( 0, 'order: '.$first.' after '.$second ) unless $first < $second;
  }
  return ( 1, _show($v) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Expectation - The expectations on a value, shared by rules, when conditions and check.expect

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Expectation qw( condition element_match );

  my ( $ok, $why ) = condition( $state, { path => 'gw-a.routes', any => { dst => '^default$' } } );
  my ( $ok, $why ) = condition( $state, { path => [ 'h', 'files', '/etc/x' ], regex => '^listen' }, \%args );

=head1 DESCRIPTION

A format 2 expectation is a hash of matcher keys (C<exists>, C<absent>,
C<equals>, C<in>, C<regex>, C<contains>, C<excludes>, C<length>, C<any>,
C<none>, C<before>) on one value; all that are named must hold. Rules of kind
C<state>, the C<when> conditions of handlers and observations, the C<expect>
of a C<check> rule and the field patterns of C<any>/C<none>/C<where> all go
through here. Keys that are not matchers (C<path>, C<title>, C<state> …) are
ignored, so a rule hash can be handed in as written.

C<tolerance> (k49) qualifies C<equals>: with C<< equals: 42, tolerance: 0.5 >>
the value must be a number no further than 0.5 from 42, bounds included —
for values read off an image. It is no expectation of its own; the shape
check (L<Langertha::Holmgang::Structure>) refuses it without a numeric
C<equals>. The comparison allows for binary rounding
(C<|41.8 - 42| E<lt>= 0.2> holds).

Paths are dotted text or a list of segments (for keys with dots); C<{name}>
in a segment is replaced by the argument C<name>. Lists are addressed by
index from 0.

Plain functions, imported on request. The simulators call
L</condition> and the World and the Grader call all of them; nothing here
knows a simulator.

=head2 path

  my @seg = path( 'gw-a.routes', \%args );
  my @seg = path( [ 'gw-a', 'peers', '{peer}' ], \%args );

A path as a list of segments, C<{name}> in each segment replaced by the
argument. Dies on an empty path.

=head2 get

  my ( $found, $value ) = get( $state, @segments );

The value at a path. A file that stands in the state as bare text has that
text as its C<content>, so C<[host, files, /path, content]> fits both forms of
a file entry.

=head2 flat

An argument as text for a pattern: lists joined with commas, booleans as
C<true>/C<false>, other references as canonical JSON.

=head2 interp_text

  interp_text( 'peer {key|lc}', \%args );

Replaces C<{name}> and C<{name|filter}> in a text by the flattened argument.

=head2 filter_value

  filter_value( '10.0.0.1/32, 10.2.0.0/24', 'split' );   # [ '10.0.0.1/32', '10.2.0.0/24' ]

The argument filters of format 2: C<split> (comma and white space into a
list), C<int> (the first integer), C<lc>. Dies on an unknown filter, with
the world's generic refusal and nothing of the filter, file or line: the
text can reach the model as a tool result. Lint refuses such a case at load
time (L<Langertha::Holmgang::Lint>), so this only guards a case that
bypassed it.

=head2 same_scalar

True when two plain values are the same: numbers numerically, text exactly,
booleans against C<1>/C<0> and C<true>/C<false>.

=head2 near

  near( $value, $want, $tolerance );

True when C<$value> is a finite number (or numeric text) no further than
C<$tolerance> from C<$want>, bounds included, allowing for binary rounding
(a relative 1e-9). A boolean, a reference or other text is not near anything.

=head2 element_match

  element_match( $element, $pattern, \%args );

Does a list element fit? C<$pattern> is a regular expression (for a text
element) or a hash field → pattern (text = regular expression, hash =
expectations as in L</check_value>). C<{name}> in patterns is replaced
literally (C<\Q…\E>).

=head2 condition

  my ( $ok, $why ) = condition( $state, { path => 'gw-a.routes', any => {…} }, \%args );

Checks the expectations of C<$spec> on the value at C<< $spec->{path} >>.
Returns true or false and a short reason.

=head2 check_value

  my ( $ok, $why ) = check_value( $found, $value, \%expectations, \%args );

The expectations on a value already looked up. A file entry with attributes
(C<< { content, mode, … } >>, as after C<cp>) counts with its C<content>
against C<equals>, C<in> and C<regex>.

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
