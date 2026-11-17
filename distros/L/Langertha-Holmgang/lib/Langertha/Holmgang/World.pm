package Langertha::Holmgang::World;
# ABSTRACT: The simulated world of a case — state, tool dispatch, handlers, end-state diff

use Moose;
use namespace::autoclean;
use utf8;

use JSON::MaybeXS ();
use Langertha::Holmgang::Expectation qw( condition element_match path get flat filter_value interp_text );
use Langertha::Holmgang::Shell ();
use Langertha::Holmgang::Shell::Filter ();
use Langertha::Holmgang::Simulators;
use Langertha::Holmgang::Target ();
use Langertha::Holmgang::Template ();
use Langertha::Holmgang::ToolSchema qw( schema_errors );

our $VERSION = '0.001';

# the state changes of a handler's apply, in format 2; a true constant
our @OPS = qw( set push insert delete remove move );

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

# what the model gets for a simulator that fails in Perl, and how such a text looks
# (" at FILE line N.", as die without "\n" ends); a line only counts when FILE is a
# source file of this process (_own_file) — simulated log text with Perl-style lines
# of invented paths is output the case asks for (ADR 0004)
my $FAULT      = 'Fehler: interner Fehler beim Ausführen des Aufrufs.';
my $PERL_ERROR = qr/^((.*?$Langertha::Holmgang::Target::LOCATION\.)[ \t]*)$/m;


has state => (
  is       => 'ro',
  writer   => '_set_state',
  required => 1,
);


has tools => (
  is      => 'ro',
  default => sub { [] },
);


has observe => (
  is      => 'ro',
  default => sub { [] },
);


has simulators => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_simulators',
);
sub _build_simulators { Langertha::Holmgang::Simulators->new }


around BUILDARGS => sub {
  my ( $orig, $class, @args ) = @_;
  my $a = $class->$orig(@args);
  $a->{state} = $class->clone( $a->{state} // {} );
  $a->{tools} //= [];
  $a->{observe} //= [];
  return $a;
};


sub clone {
  my ( $self, $d ) = @_;
  return $JSON->decode( $JSON->encode($d) );
}


sub offer {
  my ( $self ) = @_;
  return [ map { { name => $_->{name}, description => $_->{description}, parameters => $_->{parameters} } } @{ $self->tools } ];
}


sub call {
  my ( $self, $name, $raw ) = @_;
  my ( $tool ) = grep { $_->{name} eq ( $name // '' ) } @{ $self->tools };
  return ( "Fehler: unbekanntes Werkzeug '".( $name // '' )."'.", {}, 0 ) unless $tool;

  my $args = {};
  if ( ref $raw eq 'HASH' ) {
    $args = $raw;
  }
  elsif ( defined $raw && length $raw ) {
    my $text = $raw;
    utf8::decode($text) unless utf8::is_utf8($text);
    $args = eval { $JSON->decode($text) };
    return ( 'Fehler: Argumente sind kein JSON-Objekt.', {}, 0 ) unless ref $args eq 'HASH';
  }
  if ( my @e = schema_errors( $args, $tool->{parameters} ) ) {
    return ( 'Fehler: Argumente passen nicht zum Schema: '.join( '; ', @e ), $args, 0 );
  }
  return $self->_simulate( $tool, $args ) if defined $tool->{simulator};
  return $self->_handle( $tool, $args );
}

sub _simulate {
  my ( $self, $tool, $args ) = @_;
  my $sim  = $tool->{simulator};
  my $sims = $self->simulators;
  if ( $sim eq 'run_command' ) {
    my @r = $self->_observed_command($args);
    return @r if @r;
  }
  my $next = $self->clone( $self->state );
  my ( $died, $out, $ok, $gap ) = _guarded( sub {
      $sim eq 'write_file'  ? $sims->write_file( $next, @{$args}{qw( host path content )} )
    : $sim eq 'run_command' ? $sims->run_command( $next, @{$args}{qw( host command )} )
    :                         $sims->tool_call( $next, $sim, $tool->{name}, $args );
  } );
  $self->_set_state($next) unless $died;
  return ( $out, $args, $ok ? 1 : 0, $gap );
}

# a file this process runs from: a loaded module (%INC) or the script; only these
# paths are a host leak (never touches the file system)
sub _own_file {
  my ( $file ) = @_;
  return $file eq $0 || scalar grep { defined && $_ eq $file } values %INC;
}

# runs a simulator call; ( died, output, ok, gap ) with a Perl error of the simulator —
# its die, or such a text in its output — turned into $FAULT and the original into the gap
sub _guarded {
  my ( $code ) = @_;
  my ( $out, $ok, $gap );
  unless ( eval { ( $out, $ok, $gap ) = $code->(); 1 } ) {
    my $err = $@ =~ s/\s+\z//r;
    return ( 1, $FAULT, 0, join( '; ', grep { defined } $gap, 'simulator error: '.$err ) );
  }
  my @faults;
  $out =~ s/$PERL_ERROR/_own_file($3) ? do { push @faults, $2; $FAULT } : $1/ge if defined $out && !ref $out;
  return ( 0, $out, $ok, $gap ) unless @faults;
  return ( 0, $out, 0, join( '; ', grep { defined } $gap, map { 'simulator error: '.$_ } @faults ) );
}

# run_command with observations: a single command an observation answers, or a chain on
# a linux device of which at least one link is observed; else the empty list
sub _observed_command {
  my ( $self, $args ) = @_;
  return unless @{ $self->observe };
  my $host = $args->{host};
  my $dev  = defined $host && !ref $host ? $self->state->{$host} : undef;
  # a chain on a linux shell (a && b; c): observations per link — first, so that a pattern
  # without an end anchor does not answer the whole chain
  my @chain = ref $dev eq 'HASH' && ( $dev->{type} // '' ) eq 'linux' && defined $args->{command} && !ref $args->{command}
    ? Langertha::Holmgang::Shell::split_chain( $args->{command} ) : ();
  if ( @chain <= 1 ) {
    my ( $obs, $obs_ok ) = $self->_observe($args);
    return defined $obs ? ( $obs, $args, $obs_ok ) : ();
  }
  return unless grep { defined( ( $self->_observe( { %$args, command => $_->[1] } ) )[0] ) } @chain;
  my ( @out, @gaps );
  my $ok = 1;
  for my $g ( @chain ) {
    my ( $op, $cmd ) = @$g;
    next if $op eq '&&' && !$ok || $op eq '||' && $ok;
    my ( $o, $o_ok ) = $self->_observe( { %$args, command => $cmd } );
    if ( defined $o ) { push @out, $o if length $o; $ok = $o_ok; next }
    my $next = $self->clone( $self->state );
    # status of the previous link as $? (a trace the simulator takes out again)
    $next->{$host}{_rc} = $ok ? 0 : 1 if ref $next->{$host} eq 'HASH';
    my ( $died, $t, $k, $gap ) = _guarded( sub { $self->simulators->run_command( $next, $host, $cmd ) } );
    delete $next->{$host}{_rc} if ref $next->{$host} eq 'HASH';
    $self->_set_state($next) unless $died;
    push @out, $t if defined $t && length $t;
    push @gaps, $gap if defined $gap;
    $ok = $k ? 1 : 0;
  }
  return ( join( "\n", @out ), $args, $ok, @gaps ? join( '; ', @gaps ) : undef );
}

# the first fitting observation for these arguments (rendered, pipe filters applied) and
# whether the command succeeds; ( undef, 0 ) when none fits
sub _observe {
  my ( $self, $args ) = @_;
  for my $h ( @{ $self->observe } ) {
    my $with = $self->_fits( $h, $args ) or next;
    my $out = $self->_pipe_filters( $self->_render( $h->{output}, $with ), $args->{command} );
    return ( $out, $h->{error} ? 0 : 1 );
  }
  return ( undef, 0 );
}

sub _handle {
  my ( $self, $tool, $args ) = @_;
  for my $h ( @{ $tool->{handlers} || [] } ) {
    my $with = $self->_fits( $h, $args ) or next;
    my @apply = @{ $h->{apply} || [] };
    my $next = @apply ? $self->clone( $self->state ) : $self->state;
    for my $op ( @apply ) {
      my $err = $self->_apply( $next, $op, $with );
      return ( 'Fehler: '.$err, $args, 0 ) if defined $err;
    }
    $self->_set_state($next);
    return ( $self->_render( $h->{output}, $with ), $args, $h->{error} ? 0 : 1 );
  }
  return ( 'Fehler: dieser Aufruf ist in diesem Szenario nicht vorgesehen.', $args, 0 );
}

# match and when of a handler or an observation: the arguments with the named captures,
# or undef; a when that cannot be evaluated (an unknown filter in its path, only past
# lint) does not hold -- never a die out of call (k39)
sub _fits {
  my ( $self, $h, $args ) = @_;
  my $cap = $self->_args_match( $h->{match}, $args ) or return;
  my $with = { %$args, %$cap };
  for my $w ( @{ $h->{when} || [] } ) {
    my $holds = eval { ( condition( $self->state, $w, $with ) )[0] };
    return unless $holds;
  }
  return $with;
}

sub _render {
  my ( $self, $tmpl, $args ) = @_;
  return Langertha::Holmgang::Template::render( $tmpl, $self->state, $args, $self->simulators );
}

# filters behind a pipe (| grep, | head …) on the output of an observation
sub _pipe_filters {
  my ( $self, $out, $command ) = @_;
  return $out unless defined $command && $command =~ /\|/;
  my @w = eval { Langertha::Holmgang::Shell::shell_words($command) } or return $out;
  my @stages = ( [] );
  for ( @w ) {
    if    ( ref $_ && $_->{op} eq '|' ) { push @stages, [] }
    elsif ( !ref $_ )                   { push @{ $stages[-1] }, $_ }
  }
  shift @stages;
  for my $st ( @stages ) {
    shift @$st while @$st && $st->[0] eq 'sudo';
    next unless @$st;
    my ( $t ) = Langertha::Holmgang::Shell::Filter::filter_output( $out, $st );
    $out = $t if defined $t;
  }
  return $out;
}

# the patterns per argument: a hash of the named captures (true, maybe empty) or undef
sub _args_match {
  my ( $self, $m, $args ) = @_;
  my %cap;
  for my $k ( sort keys %{ $m || {} } ) {
    my $v = flat( $args->{$k} );
    return undef unless defined $v && $v =~ /$m->{$k}/;
    %cap = ( %cap, %+ );
  }
  return \%cap;
}


sub value {
  my ( $self, $t, $args ) = @_;
  return { map { $_ => $self->value( $t->{$_}, $args ) } keys %$t } if ref $t eq 'HASH';
  return [ map { $self->value( $_, $args ) } @$t ] if ref $t eq 'ARRAY';
  return $t if !defined $t || ref $t;
  return filter_value( $args->{$1}, $2 ) if $t =~ /\A\{([A-Za-z_][A-Za-z0-9_]*)(?:\|([a-z]+))?\}\z/;
  return $t =~ /\{[A-Za-z_]/ ? interp_text( $t, $args ) : $t;
}

# the container at a path without its last segment; hashes on the way are created
sub _parent {
  my ( $self, $d, @seg ) = @_;
  my $last = pop @seg;
  for my $k ( @seg ) {
    if ( ref $d eq 'HASH' ) {
      $d->{$k} //= {};
      $d = $d->{$k};
    }
    elsif ( ref $d eq 'ARRAY' && $k =~ /\A\d+\z/ && $k < @$d ) {
      $d = $d->[$k];
    }
    else { return ( undef, $last ) }
  }
  return ( $d, $last );
}

sub _list_at {
  my ( $self, $state, $seg, $create ) = @_;
  my ( $p, $last ) = $self->_parent( $state, @$seg );
  return undef unless ref $p;
  if ( ref $p eq 'HASH' ) {
    $p->{$last} = [] if $create && !defined $p->{$last};
    return ref $p->{$last} eq 'ARRAY' ? $p->{$last} : undef;
  }
  return $last =~ /\A\d+\z/ && ref $p->[$last] eq 'ARRAY' ? $p->[$last] : undef;
}

sub _index {
  my ( $self, $v, $list, $what, $allow_end ) = @_;
  my $max = @$list - ( $allow_end ? 0 : 1 );
  die $what." '".( $v // '' )."' ist keine Nummer\n" unless defined $v && "$v" =~ /\A\d+\z/;
  die $what.' '.$v.' gibt es nicht (0 bis '.$max.")\n" if $v > $max;
  return 0 + $v;
}

# one change of a handler's apply, as format 2 writes it ({ set => PATH, value => … });
# returns undef or the error text for the model
sub _apply {
  my ( $self, $state, $op, $args ) = @_;
  my ( $kind ) = grep { exists $op->{$_} } @OPS;
  my $err;
  eval {
    die 'unbekannte Aenderung '.join( ',', sort keys %$op )."\n" unless defined $kind;
    my @seg = path( $op->{$kind}, $args );
    if ( $kind eq 'set' ) {
      my ( $p, $last ) = $self->_parent( $state, @seg );
      die "Pfad nicht vorhanden\n" unless ref $p;
      if ( ref $p eq 'HASH' ) { $p->{$last} = $self->value( $op->{value}, $args ) }
      else                    { $p->[ $self->_index( $last, $p, 'Eintrag' ) ] = $self->value( $op->{value}, $args ) }
    }
    elsif ( $kind eq 'push' ) {
      my $l = $self->_list_at( $state, \@seg, 1 ) or die "keine Liste\n";
      push @$l, $self->value( $op->{value}, $args );
    }
    elsif ( $kind eq 'insert' ) {
      my $l = $self->_list_at( $state, \@seg, 1 ) or die "keine Liste\n";
      my $at = $self->_index( $self->value( $op->{at}, $args ), $l, 'Position', 1 );
      splice @$l, $at, 0, $self->value( $op->{value}, $args );
    }
    elsif ( $kind eq 'delete' ) {
      my ( $p, $last ) = $self->_parent( $state, @seg );
      die "nicht vorhanden\n" unless ref $p eq 'HASH' && exists $p->{$last}
        || ref $p eq 'ARRAY' && $last =~ /\A\d+\z/ && $last < @$p;
      if   ( ref $p eq 'HASH' ) { delete $p->{$last} }
      else                      { splice @$p, $last, 1 }
    }
    elsif ( $kind eq 'remove' ) {
      my $l = $self->_list_at( $state, \@seg, 0 ) or die "keine Liste\n";
      my @keep = grep { !element_match( $_, $op->{where}, $args ) } @$l;
      die "kein passender Eintrag\n" if @keep == @$l;
      @$l = @keep;
    }
    else {    # move
      my $l = $self->_list_at( $state, \@seg, 0 ) or die "keine Liste\n";
      my $from = $self->_index( $self->value( $op->{from}, $args ), $l, 'Eintrag' );
      my ( $item ) = splice @$l, $from, 1;
      my $to = $self->_index( $self->value( $op->{to}, $args ), $l, 'Ziel', 1 );
      splice @$l, $to, 0, $item;
    }
    1;
  } or $err = ( $@ =~ s/$Langertha::Holmgang::Target::LOCATION\.?\n?\z//r =~ s/\s+\z//r );
  return $err;
}


sub diff {
  my ( $self, $a, $b, @at ) = @_;
  if ( ref $a eq 'HASH' && ref $b eq 'HASH' ) {
    my %k = map { $_ => 1 } grep { !/\A_/ } keys %$a, keys %$b;
    my @out;
    for my $k ( sort keys %k ) {
      # a new or removed hash is shown key by key
      if ( !exists $b->{$k} ) {
        push @out, ref $a->{$k} eq 'HASH' && %{ $a->{$k} } ? $self->diff( $a->{$k}, {}, @at, $k )
          : { path => [ @at, $k ], before => $a->{$k} };
      }
      elsif ( !exists $a->{$k} ) {
        push @out, ref $b->{$k} eq 'HASH' && %{ $b->{$k} } ? $self->diff( {}, $b->{$k}, @at, $k )
          : { path => [ @at, $k ], after => $b->{$k} };
      }
      else { push @out, $self->diff( $a->{$k}, $b->{$k}, @at, $k ) }
    }
    return @out;
  }
  if ( ref $a eq 'ARRAY' && ref $b eq 'ARRAY' && @$a == @$b && grep { ref } @$a, @$b ) {
    return map { $self->diff( $a->[$_], $b->[$_], @at, $_ ) } 0 .. $#$a;
  }
  return () if $JSON->encode($a) eq $JSON->encode($b);
  return { path => \@at, before => $a, after => $b };
}


sub path_text {
  my ( $self, $seg ) = @_;
  my $s = '';
  for my $k ( @$seg ) {
    if ( $k =~ /[.\s"\[\]]/ || !length $k ) { $s .= '['.$JSON->encode("$k").']' }
    else                                     { $s .= ( length $s ? '.' : '' ).$k }
  }
  return $s;
}


sub covered {
  my ( $self, $seg, $allowed ) = @_;
  ALLOWED: for my $al ( @$allowed ) {
    next if @$al > @$seg;
    for my $i ( 0 .. $#$al ) {
      next if $al->[$i] eq '*' || $al->[$i] eq $seg->[$i];
      next ALLOWED unless index( $al->[$i], '*' ) >= 0;
      my $re = join '[^/]*', map { quotemeta } split /\*/, $al->[$i], -1;
      next ALLOWED unless $seg->[$i] =~ /\A$re\z/;
    }
    return 1;
  }
  return 0;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::World - The simulated world of a case — state, tool dispatch, handlers, end-state diff

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $world = Langertha::Holmgang::World->new(
    state   => $case->initial_state,
    tools   => $suite->tools,
    observe => $case->observe,
  );

  my ( $output, $args, $ok, $gap ) = $world->call( run_command => '{"host":"gw-a","command":"ip route"}' );
  $world->state;                                          # after all calls

  my @diff = Langertha::Holmgang::World->diff( $case->initial_state, $world->state );

=head1 DESCRIPTION

A case describes a small world: a B<state> (nested data: devices with their
files and services, or plain entries for handler worlds) and the suite's
B<tools>. A call goes through, in this order:

=over 4

=item 1. B<Observations> of the case (C<observe>), for a tool with
C<simulator: run_command>: the first entry whose C<match> (a regular
expression per argument; named captures become arguments) and C<when>
(expectations on the state) fit answers with its rendered C<output>, pipe
filters behind a C<|> applied. C<error: true> makes the call fail. An
observation never changes the state. On a C<linux> device a command chain
(C<a && b; c>) is answered link by link: an observation for its link, the
simulator for the others, with C<&&>, C<||> and C<$?> following the exit
status.

=item 2. The B<simulator> of the device type (C<run_command>, C<write_file>,
or the tool of an answer world), through L<Langertha::Holmgang::Simulators>.
An unknown host answers like C<ssh>. A simulator that fails in Perl never
hands its error text (with a host file path) to the model: a die answers
C<Fehler: interner Fehler beim Ausführen des Aufrufs.> and leaves the state
unchanged; a Perl error line in its output that names a source file of the
running process (a die the simulator caught) is replaced by that same text,
the rest of the output and the state stay — a simulated line of the same
shape with any other path is output and passes unchanged. Either
way the call fails, and the original text goes into the gap of the simulation
as C<simulator error: …> — for the report, never for the model.

=item 3. B<Handlers> of a tool without simulator: the first whose C<match>
and C<when> fit applies its C<apply> list (C<set>, C<push>, C<insert>,
C<delete>, C<remove>, C<move>) to a copy of the state and renders its
C<output> (L<Langertha::Holmgang::Template>) after the change. A failed change
leaves the state untouched.

=back

A C<when> of an observation or a handler that cannot be evaluated (an unknown
filter in its path, which lint refuses at load time) does not hold: the entry
does not fit, and the call never dies.

Tools, handlers and observations are read as format 2 writes them. In paths,
values and C<where> patterns C<{name}> stands for the argument C<name>; a value
that is exactly C<{name}> takes the argument as it is (list, number),
C<{name|split}> splits text at commas and white space, C<{name|int}> makes an
integer, C<{name|lc}> lower case.

Everything is deterministic: the same calls give the same state and outputs.
The texts the model gets for a refused call (C<Fehler: …>) are German, as the
suites expect them.

=head2 state

The current state. The constructor takes a deep copy, so the case stays
untouched; do not change the returned hash (copy it with L</clone>).

=head2 tools

The suite's tools as format 2 writes them (C<name>, C<description>,
C<parameters>, and C<simulator> or C<handlers>).

=head2 observe

The case's observations (C<match>, C<when>, C<output>, C<error>).

=head2 simulators

The simulator registry (L<Langertha::Holmgang::Simulators>); a fresh one by
default.

=head2 clone

  my $copy = Langertha::Holmgang::World->clone($data);

A deep copy through canonical JSON (a state must be storable as JSON).

=head2 offer

The tools as they are offered to the model: C<name>, C<description>,
C<parameters> — nothing else.

=head2 call

  my ( $output, $args, $ok, $gap ) = $world->call( $name, $arguments );

Runs one tool call. C<$arguments> is the JSON text the model sent, or a hash
already. Returns the text for the tool message, the decoded arguments (empty
hash when unreadable), whether the call succeeded and, for a simulator, the
B<gap of the simulation> it hit (C<undef> without). An unknown tool, arguments
that are no JSON object or do not fit the schema, and a call no handler takes
answer with a text starting C<Fehler:> and leave the state unchanged.

=head2 value

  my $v = $world->value( $template, \%args );

Puts arguments into a value: a text that is exactly C<{name}> (with optional
filter) becomes the argument itself, else C<{name}> is replaced inside the
text; hashes and lists recursively.

=head2 diff

  my @diff = Langertha::Holmgang::World->diff( $before, $after );
  # ( { path => [ 'gw-a', 'routes' ], before => […], after => […] }, … )

What changed: hashes key by key, lists of the same length holding hashes or
lists entry by entry (index in the path), other lists and values as a whole.
C<before> or C<after> is missing when the path did not exist then. Keys
starting with C<_> are a simulator's bookkeeping and never compared. Sorted by
path.

=head2 path_text

  Langertha::Holmgang::World->path_text( [ 'gw-a', 'peers', 'Qm4.=' ] );   # gw-a.peers["Qm4.="]

A path for display; segments with a dot, white space, quote or bracket (or
empty ones) in brackets as JSON text.

=head2 covered

  Langertha::Holmgang::World->covered( \@segments, \@allowed_paths );

True when an allowed path (a list of segments; C<*> fits any one segment) is a
prefix of the path or equal to it. A C<*> inside a segment fits any characters
but C</> (C</etc/x.service.d/*.conf>).

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
