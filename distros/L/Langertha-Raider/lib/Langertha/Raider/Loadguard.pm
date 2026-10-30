package Langertha::Raider::Loadguard;
# ABSTRACT: Internal gate that refuses heavy shell commands while the host is out of room
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use File::Which ();
use Langertha::Raider::Binary qw( packed_binary );
use Path::Tiny;


has proc_dir => (
  is      => 'ro',
  isa     => 'Str',
  default => '/proc',
);


has env => (
  is      => 'ro',
  isa     => 'HashRef',
  default => sub { \%ENV },
);


has cgroup_dir => (
  is      => 'ro',
  isa     => 'Str',
  default => '/sys/fs/cgroup',
);


use constant {
  PSI_FULL_DEFAULT  => 10,
  SWAP_USED_DEFAULT => 90,
  MAX_WORDS         => 32,
  WORD_MAX          => 255,
  MAX_HEREDOCS      => 8,
  HOLDERS_SHOWN     => 3,
};

my %INTERPRETERS = map { $_ => 1 } qw( perl python python3 node sh bash dash );
my %SHELLS       = map { $_ => 1 } qw( bash sh dash zsh );
my %PREFIXES     = map { $_ => 1 } qw(
  ! { } if then else elif while until do time exec nice ionice nohup timeout env stdbuf setsid xargs
);
my %CLAUDE_HEADLESS = map { $_ => 1 } qw( -p --print --bg );
my %CODEX_HEADLESS  = map { $_ => 1 } qw( exec e review );

#### Environment

# An integer of the environment, a trailing % allowed; the default when it is
# missing, not a number or outside lo..hi.
sub _env_int {
  my ( $self, $name, $default, $lo, $hi ) = @_;
  my $v = $self->env->{$name};
  return $default unless defined $v && $v =~ /\A(\d{1,9})%?\z/;
  return $1 >= $lo && $1 <= $hi ? 0 + $1 : $default;
}


sub enabled { my ( $self ) = @_; return ( $self->env->{LOADGUARD_THROTTLE} // '' ) eq '0' ? 0 : 1 }

sub limits {
  my ( $self ) = @_;
  return {
    psi_full  => $self->_env_int( 'LOADGUARD_PSI_FULL',  PSI_FULL_DEFAULT,  1, 100 ),
    swap_used => $self->_env_int( 'LOADGUARD_SWAP_USED', SWAP_USED_DEFAULT, 1, 100 ),
    slots     => $self->_env_int( 'LOADGUARD_HEAVY_SLOTS', $self->default_slots, 1, 4096 ),
  };
}


sub default_slots {
  my ( $self ) = @_;
  my $cpus = 0;
  if ( defined( my $status = $self->_slurp('self/status') ) ) {
    if ( $status =~ /^Cpus_allowed_list:\s*(\S+)/m ) {
      for my $range ( split /,/, $1 ) {
        $cpus += $range =~ /\A(\d+)-(\d+)\z/ ? $2 - $1 + 1 : $range =~ /\A\d+\z/ ? 1 : 0;
      }
    }
  }
  if ( !$cpus && defined( my $info = $self->_slurp('cpuinfo') ) ) {
    $cpus = () = $info =~ /^processor\s*:/mg;
  }
  my $slots = int( $cpus / 2 );
  return $slots < 1 ? 1 : $slots;
}

# A file below proc_dir, or undef when it cannot be read.
sub _slurp {
  my ( $self, $rel ) = @_;
  my $file = path( $self->proc_dir )->child($rel);
  return unless -f $file;
  my $text = eval { $file->slurp_raw };
  return $text;
}

#### Pressure


sub pressure {
  my ( $self ) = @_;
  my %p = ( full => undef, swap => undef );
  if ( defined( my $psi = $self->_slurp('pressure/memory') ) ) {
    $p{full} = $1 + 0 if $psi =~ /^full\s+avg10=(\d+(?:\.\d+)?)/m;
  }
  if ( defined( my $mem = $self->_slurp('meminfo') ) ) {
    my ( $total ) = $mem =~ /^SwapTotal:\s*(\d+)/m;
    my ( $free )  = $mem =~ /^SwapFree:\s*(\d+)/m;
    $p{swap} = int( ( $total - $free ) * 100 / $total ) if $total && defined $free;
  }
  return \%p;
}

sub _pressured {
  my ( $self, $p, $limits ) = @_;
  return 1 if defined $p->{full} && $p->{full} >= $limits->{psi_full};
  return 1 if defined $p->{swap} && $p->{swap} >= $limits->{swap_used};
  return 0;
}

sub _figures {
  my ( $self, $p, $limits ) = @_;
  return ( defined $p->{full} ? sprintf( 'memory pressure full=%.1f%% (limit %d%%)', $p->{full}, $limits->{psi_full} ) : 'memory pressure n/a' )
    .( defined $p->{swap} ? sprintf( ', swap %d%% used (limit %d%%)', $p->{swap}, $limits->{swap_used} ) : '' );
}

#### Which commands are heavy


sub heavy {
  my ( $self, $command ) = @_;
  return unless defined $command;
  for my $words ( $self->_simple_commands($command) ) {
    my @hit = $self->_classify_words($words);
    return wantarray ? @hit : $hit[0] if @hit;
  }
  return;
}

# The simple commands of a shell string, each as the list of its words that
# stand in command position (after assignments and prefixes).
sub _simple_commands {
  my ( $self, $cmd ) = @_;
  my @c = split //, $cmd;
  my ( @out, @words, @heredocs );
  my ( $word, $open, $skip, $quote ) = ( '', 0, 0, '' );

  my $put = sub {
    my ($ch) = @_;
    unless ($open) { $open = 1; $word = '' }
    $word .= $ch if @words < MAX_WORDS && length $word < WORD_MAX;
  };
  my $end_word = sub {
    return unless $open;
    $open = 0;
    if ($skip) { $skip = 0 }
    elsif ( @words < MAX_WORDS ) { push @words, $word }
  };
  my $end_command = sub {
    $end_word->();
    $skip = 0;
    push @out, [@words];
    @words = ();
  };

  for ( my $i = 0 ; $i < @c ; $i++ ) {
    my $ch = $c[$i];
    if ( $quote eq "'" ) {
      if ( $ch eq "'" ) { $quote = '' } else { $put->($ch) }
      next;
    }
    if ( $quote eq '"' ) {
      if ( $ch eq '"' ) { $quote = '' }
      elsif ( $ch eq '\\' && $i + 1 < @c && index( "\"\\\$`\n", $c[ $i + 1 ] ) >= 0 ) {
        $put->( $c[ $i + 1 ] ) unless $c[ $i + 1 ] eq "\n";
        $i++;
      }
      else { $put->($ch) }
      next;
    }
    if ( $ch eq "'" || $ch eq '"' ) {
      $quote = $ch;
      unless ($open) { $open = 1; $word = '' }
    }
    elsif ( $ch eq '\\' ) {
      if    ( ( $c[ $i + 1 ] // '' ) eq "\n" ) { $i++ }
      elsif ( $i + 1 < @c )                    { $put->( $c[ ++$i ] ) }
    }
    elsif ( $ch =~ /[ \t\r]/ ) { $end_word->() }
    elsif ( $ch eq '#' ) {
      if   ($open) { $put->($ch) }
      else         { $i++ while $i + 1 < @c && $c[ $i + 1 ] ne "\n" }
    }
    elsif ( $ch eq '<' && ( $c[ $i + 1 ] // '' ) eq '<' && ( $c[ $i + 2 ] // '' ) ne '<' ) {
      $end_word->();
      my ( $delim, $strip );
      ( $i, $delim, $strip ) = $self->_heredoc_start( \@c, $i );
      push @heredocs, [ $delim, $strip ] if length $delim && @heredocs < MAX_HEREDOCS;
    }
    elsif ( $ch eq '<' || $ch eq '>' ) {
      $end_word->();
      $i++ while $i + 1 < @c && $c[ $i + 1 ] =~ /[<>&|]/;
      $skip = 1;
    }
    elsif ( $ch eq '&' && ( $c[ $i + 1 ] // '' ) eq '>' ) {
      $end_word->();
      $i++ while ( $c[ $i + 1 ] // '' ) eq '>';
      $skip = 1;
    }
    elsif ( $ch =~ /[&\n;|()`]/ ) {
      $end_command->();
      if ( $ch eq "\n" && @heredocs ) {
        my $at = $self->_skip_heredocs( $cmd, $i, \@heredocs );
        @heredocs = ();
        last unless defined $at && $at < length $cmd;
        $i = $at;
      }
    }
    else { $put->($ch) }
  }
  $end_command->();

  return map { $self->_command_words($_) } @out;
}

# From the "<<" at $i: the delimiter word (quotes removed), whether it is
# "<<-", and the index of the last character consumed.
sub _heredoc_start {
  my ( $self, $c, $i ) = @_;
  my $j = $i + 2;
  my $strip = 0;
  if ( ( $c->[$j] // '' ) eq '-' ) { $strip = 1; $j++ }
  $j++ while ( $c->[$j] // '' ) =~ /\A[ \t]\z/;
  my ( $delim, $quote ) = ( '', '' );
  for ( ; $j < @$c ; $j++ ) {
    my $ch = $c->[$j];
    if ($quote) {
      if ( $ch eq $quote ) { $quote = '' } elsif ( length $delim < 63 ) { $delim .= $ch }
      next;
    }
    if ( $ch eq "'" || $ch eq '"' ) { $quote = $ch; next }
    if    ( $ch eq '\\' && $j + 1 < @$c ) { $j++; $ch = $c->[$j] }
    elsif ( index( " \t\n;&|()<>`", $ch ) >= 0 ) { last }
    $delim .= $ch if length $delim < 63;
  }
  return ( $j - 1, $delim, $strip );
}

# At the newline $at ending the line with here-document operators: the index
# of the newline (or end) after the last delimiter line, undef when the text
# ends inside a body.
sub _skip_heredocs {
  my ( $self, $cmd, $at, $heredocs ) = @_;
  my $pos = $at;
  for my $h (@$heredocs) {
    my ( $delim, $strip ) = @$h;
    while (1) {
      return unless $pos < length $cmd && substr( $cmd, $pos, 1 ) eq "\n";
      my $start = $pos + 1;
      my $end   = index( $cmd, "\n", $start );
      $end = length $cmd if $end < 0;
      my $line = substr( $cmd, $start, $end - $start );
      $pos = $end;
      $line =~ s/\A\t+// if $strip;
      last if $line eq $delim;
    }
  }
  return $pos;
}

# The words from the command word on: assignments, prefixes and their options
# and numbers skipped.
sub _command_words {
  my ( $self, $words ) = @_;
  my ( $i, $prefixed ) = ( 0, 0 );
  for ( ; $i < @$words ; $i++ ) {
    my $w = $words->[$i];
    next if $w =~ /\A[A-Za-z_][A-Za-z0-9_]*\+?=/;
    next if $prefixed && $w =~ /\A[-0-9]/;
    if ( $PREFIXES{$w} ) { $prefixed = 1; next }
    last;
  }
  return [ @$words[ $i .. $#$words ] ];
}

sub _base { my ( $self, $path ) = @_; return $path =~ s{.*/}{}r }

# ( label, kind ) of the argv of a command, or nothing. An interpreter is
# looked through to its script; inline code (-c, -e, -E) is no script.
sub _classify_words {
  my ( $self, $av ) = @_;
  my @av = @$av;
  return unless @av && length $av[0];
  my $at = 0;
  if ( $INTERPRETERS{ $self->_base( $av[0] ) } ) {
    for ( $at = 1 ; $at < @av && $av[$at] =~ /\A-/ ; $at++ ) {
      return if $av[$at] =~ /\A-[ceE]\z/;
    }
    return if $at == @av;
  }
  @av = @av[ $at .. $#av ];
  my $name = $self->_base( $av[0] );
  my ($sub) = grep { !/\A[-+]/ } @av[ 1 .. $#av ];
  $sub //= '';

  return ( 'prove', 'prove' ) if $name eq 'prove';
  return ( $name, 'build' )   if $name eq 'cpanm' || $name eq 'perlbench';
  if ( $name eq 'dzil' ) {
    return ( 'dzil build', 'build' ) if $sub eq 'build';
    return ( 'dzil '.$sub, 'suite' ) if $sub eq 'test' || $sub eq 'release';
  }
  elsif ( $name eq 'make' ) {
    return ( 'make test', 'suite' ) if grep { $_ eq 'test' } @av[ 1 .. $#av ];
  }
  elsif ( $name eq 'docker' || $name eq 'podman' ) {
    return ( $name.' '.$sub, 'build' ) if $sub eq 'build' || $sub eq 'run';
  }
  elsif ( $name eq 'cargo' ) {
    return ( 'cargo build', 'build' ) if $sub eq 'build';
    return ( 'cargo test',  'suite' ) if $sub eq 'test';
  }
  elsif ( $name eq 'npm' ) {
    return ( 'npm test', 'suite' ) if $sub eq 'test';
  }
  elsif ( $name eq 'claude' ) {
    my ($flag) = grep { $CLAUDE_HEADLESS{$_} } @av[ 1 .. $#av ];
    return ( 'claude '.$flag, 'agent' ) if $flag;
  }
  elsif ( $name eq 'codex' ) {
    my ($flag) = grep { $CODEX_HEADLESS{$_} } @av[ 1 .. $#av ];
    return ( 'codex '.$flag, 'agent' ) if $flag;
  }
  return;
}

#### Slots


sub slot_holders {
  my ( $self ) = @_;
  my $root = path( $self->proc_dir );
  my %proc;
  my @dirs = eval { $root->children(qr/\A\d+\z/) };
  for my $dir (@dirs) {
    my $pid  = $dir->basename;
    my $stat = eval { $dir->child('stat')->slurp_raw } // next;
    my ( $comm, $ppid ) = $stat =~ /\A\d+ \((.*)\) \S (\d+)/s or next;
    my $cmdline = eval { $dir->child('cmdline')->slurp_raw } // '';
    my @argv = split /\0/, $cmdline;
    $proc{$pid} = { pid => $pid, ppid => $ppid, comm => $comm, argv => \@argv };
  }
  for my $p ( values %proc ) {
    ( $p->{label}, $p->{kind} ) = $self->_process_kind( $p->{argv} );
    $p->{raider} = $self->_is_raider($p);
  }
  my @holders;
  for my $p ( sort { $a->{pid} <=> $b->{pid} } values %proc ) {
    next unless $p->{kind} && $p->{kind} ne 'agent';
    my ( $above_heavy, $above_raider, $cur, $depth ) = ( 0, 0, $proc{ $p->{ppid} }, 0 );
    while ( $cur && $depth++ < 64 ) {
      $above_heavy = 1 if $cur->{kind} && $cur->{kind} ne 'agent';
      $above_raider = 1 if $cur->{raider};
      $cur = $proc{ $cur->{ppid} };
    }
    next if $above_heavy || !$above_raider;
    push @holders, { pid => $p->{pid}, label => $p->{label}, cwd => scalar eval { readlink $root->child( $p->{pid}, 'cwd' ) } };
  }
  return @holders;
}

# ( label, kind ) of a running process: its argv, or for a shell -c its string.
sub _process_kind {
  my ( $self, $argv ) = @_;
  return unless @$argv;
  my @hit = $self->_classify_words($argv);
  return @hit if @hit;
  if ( $SHELLS{ $self->_base( $argv->[0] ) } && @$argv >= 3 && $argv->[1] =~ /\A-l?c\z/ ) {
    return $self->heavy( $argv->[2] );
  }
  return;
}

# Is it a raider: the executable, or a script run by an interpreter.
sub _is_raider {
  my ( $self, $p ) = @_;
  my @argv = @{ $p->{argv} };
  return 1 if $p->{comm} eq 'raider';
  return unless @argv;
  return 1 if $self->_base( $argv[0] ) eq 'raider';
  if ( $INTERPRETERS{ $self->_base( $argv[0] ) } ) {
    my ($script) = grep { !/\A-/ } @argv[ 1 .. $#argv ];
    return 1 if defined $script && $self->_base($script) eq 'raider';
  }
  return 0;
}

#### The decision


sub check {
  my ( $self, $command ) = @_;
  return unless $self->enabled;
  my ( $label, $kind ) = $self->heavy($command) or return;
  my $limits   = $self->limits;
  my $pressure = $self->pressure;
  my $head     = 'refused by loadguard: heavy command ('.$label.'): ';
  if ( $self->_pressured( $pressure, $limits ) ) {
    return $head.$self->_figures( $pressure, $limits ).".\n"
      .'Wait and retry later; light commands (git status, ls, cat) still run.'
      .$self->_advice( $kind, 0 );
  }
  my @holders = $self->slot_holders;
  return if @holders < $limits->{slots};
  my @shown = map { $_->{label}.( defined $_->{cwd} ? ' in '.$self->_tilde( $_->{cwd} ) : '' ) } @holders[ 0 .. ( @holders > HOLDERS_SHOWN ? HOLDERS_SHOWN : scalar @holders ) - 1 ];
  push @shown, '+'.( @holders - HOLDERS_SHOWN ).' more' if @holders > HOLDERS_SHOWN;
  return $head.scalar(@holders).'/'.$limits->{slots}.' heavy slots busy ('.join( '; ', @shown ).'), '
    .$self->_figures( $pressure, $limits ).".\n"
    .'Wait for one to finish, then retry; light commands (git status, ls, cat) still run.'
    .$self->_advice( $kind, 1 );
}

sub _tilde {
  my ( $self, $dir ) = @_;
  my $home = $self->env->{HOME};
  return $dir unless defined $home && length $home > 1 && ( $dir eq $home || index( $dir, $home.'/' ) == 0 );
  return '~'.substr( $dir, length $home );
}

# The advice for the retry. Under pressure no test run is advised, not even a
# small one: any run adds memory, and a command the classifier lets through
# would teach the way around the gate.
sub _advice {
  my ( $self, $kind, $slots ) = @_;
  return ' Do not start new `claude -p`/`claude --bg` or `codex exec`/`codex review` sessions now; do the work in this one.'
    if $kind eq 'agent';
  return '' unless $slots;
  return ' When you retry, run fewer tests: `prove -l t/foo.t` instead of `-r`.' if $kind eq 'prove';
  return ' When you retry, run a single test file instead of the whole suite.'   if $kind eq 'suite';
  return '';
}


sub validator {
  my ( $self ) = @_;
  return sub { my ($command) = @_; return $self->check($command) // 1 };
}

#### Confinement


sub confine_command {
  my ( $self, %arg ) = @_;
  my $env = $self->env;
  return unless ( $env->{LOADGUARD_CONFINE} // '' ) eq '1';
  return if $env->{LOADGUARD_CONFINED};
  my $command = $arg{command} or croak __PACKAGE__.'->confine_command needs a command';
  my $run = File::Which::which('systemd-run') or return;
  my $xdg = $env->{XDG_RUNTIME_DIR};
  return unless defined $xdg && -S $xdg.'/bus';
  my $uid = $arg{uid} // $<;
  my $controllers = path( $self->cgroup_dir )->child( 'user.slice', 'user-'.$uid.'.slice', 'user@'.$uid.'.service', 'cgroup.controllers' );
  return unless -f $controllers && ( eval { $controllers->slurp_raw } // '' ) =~ /\bmemory\b/;
  my ($total_kb) = ( $self->_slurp('meminfo') // '' ) =~ /^MemTotal:\s*(\d+)/m;
  return unless $total_kb;
  my $bytes = sub { int( $total_kb * 1024 * $_[0] / 100 ) };
  return (
    $run, qw( --user --scope --quiet --collect --slice=app-loadguard.slice ),
    '--unit=loadguard-raider-'.( $arg{pid} // $$ ),
    '-p', 'MemoryHigh='.$bytes->( $self->_env_int( 'LOADGUARD_MEMORY_HIGH', 30, 1, 100 ) ),
    '-p', 'MemoryMax='.$bytes->( $self->_env_int( 'LOADGUARD_MEMORY_MAX', 40, 1, 100 ) ),
    '-p', 'MemorySwapMax='.$bytes->( $self->_env_int( 'LOADGUARD_MEMORY_SWAP_MAX', 10, 0, 100 ) ),
    '-p', 'CPUWeight='.$self->_env_int( 'LOADGUARD_CPU_WEIGHT', 50, 1, 10000 ),
    '-p', 'OOMPolicy=continue',
    '--', @$command,
  );
}


sub self_command {
  my ( $self ) = @_;
  my $packed = packed_binary();
  return $packed ? ( $packed, @ARGV ) : ( $^X, $0, @ARGV );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Loadguard - Internal gate that refuses heavy shell commands while the host is out of room

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    my $guard = Langertha::Raider::Loadguard->new;
    my $why   = $guard->check('prove -lr t/');     # undef: let it run

    # as the validator of the bash tool: true to run, else the reason
    validator => sub { $guard->check( $_[0] ) // 1 },

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

A port of the mechanism of the loadguard plugin for Claude Code (the C hook
of F<~/dev/loadguard>) into raider, so that a raider cannot take down the
host with the commands it runs, and tells the model why and what to do
instead. It is a gate in front of C<bash>; it refuses, it never queues or
rewrites. The decisions are those of the plugin and use its environment
variables, so one setting serves both.

B<Which commands are heavy.> The command string is split into simple
commands (at C<;> C<&> C<|> C<(> C<)>, backticks and newlines, respecting
quotes, comments, redirections and here-documents); the first one that
matches is heavy: C<prove>; C<make test>; C<dzil test|build|release>;
C<cpanm>; C<perlbench>; C<docker|podman build|run>; C<cargo build|test>;
C<npm test>; C<claude -p|--print|--bg>; C<codex exec|e|review>. Before the
command word C<VAR=x>, C<nice>, C<ionice>, C<nohup>, C<timeout>, C<env>,
C<stdbuf>, C<setsid>, C<xargs>, C<time>, C<exec> with their options and
numbers, and shell keywords such as C<if> and C<then> are skipped. A script
run by an interpreter (C<perl /usr/bin/prove>) counts as the script. This is
no shell parser: what it cannot tell is light (C<bash -c 'prove'>, C<sudo
prove>, C<find -exec prove>). A light command is never refused -- the model
must always be able to look at what is going on.

B<When a heavy command is refused> (L</check>): when the host is under
memory pressure -- the C<full> C<avg10> figure of F</proc/pressure/memory>
at or above C<LOADGUARD_PSI_FULL> (default 10 %), or swap used at or above
C<LOADGUARD_SWAP_USED> (default 90 %) -- or when all heavy slots are taken.
The slots are C<LOADGUARD_HEAVY_SLOTS> (default C<max(1, nproc/2)>); a slot
is held by the topmost running heavy process under any running C<raider>
process (any raider of the user, found in F</proc>; a C<claude -p> or C<codex
exec> holds none). Under pressure the processes are not scanned at all:
reading the memory of others can stall on swap, and a slow scan would let
the heavy command through. The reason names the figures and gives the
advice that fits: wait; run a single test file when the slots are the
problem (never under pressure, when any run adds memory); start no new
agent sessions.

B<Fail-open.> No F</proc/pressure/memory>, no swap, an unreadable F</proc>:
that signal reports no pressure. C<LOADGUARD_THROTTLE=0> (exactly) turns the
gate off.

B<Confinement> (L</confine_command>): off by default. With
C<LOADGUARD_CONFINE=1> the raider starts itself again inside a transient
systemd user scope with memory limits (C<LOADGUARD_MEMORY_HIGH> 30,
C<LOADGUARD_MEMORY_MAX> 40, C<LOADGUARD_MEMORY_SWAP_MAX> 10, in percent of the
memory of the host; C<LOADGUARD_CPU_WEIGHT> 50), so a runaway command is
killed in the scope instead of taking the machine. Without a user manager
of systemd with the memory controller it does nothing.

Every path into F</proc> goes through L</proc_dir>, so the tests give it a
tree of their own and create no load.

=head2 proc_dir

Where F<pressure/memory>, F<meminfo> and the process directories are read.
Default F</proc>; the tests point it at a directory they built.

=head2 env

The environment the C<LOADGUARD_*> variables are read from. Default C<%ENV>.

=head2 cgroup_dir

Where the cgroup v2 tree is, for L</confine_command>. Default F</sys/fs/cgroup>.

=head2 enabled

False when C<LOADGUARD_THROTTLE> is exactly C<0>.

=head2 limits

    my $limits = $guard->limits;   # { psi_full => 10, swap_used => 90, slots => 4 }

The thresholds from C<LOADGUARD_PSI_FULL>, C<LOADGUARD_SWAP_USED> (1 to 100)
and C<LOADGUARD_HEAVY_SLOTS> (1 to 4096). A value that is no whole number
(a trailing C<%> is fine) or out of range counts as unset.

=head2 default_slots

C<max(1, nproc/2)>: the CPUs this process may run on (F<self/status>
C<Cpus_allowed_list>, else the C<processor> lines of F<cpuinfo>, else 1).

=head2 pressure

    my $p = $guard->pressure;   # { full => 0.12, swap => 51 }

The memory signals: C<full> is the C<avg10> of the C<full> line of
F<pressure/memory> in percent, C<swap> the share of swap in use in whole
percent. Each is undef when the host does not say (the gate then takes it as
no pressure).

=head2 heavy

    my $label = $guard->heavy('cd /x && dzil test');   # 'dzil test'
    my ( $label, $kind ) = $guard->heavy($command);

The label of the first heavy simple command in the command string (C<prove>,
C<make test>, C<podman run>, C<claude -p> ...) and its kind (C<prove>,
C<suite>, C<build> or C<agent>), or nothing for a light command.

=head2 slot_holders

    my @holders = $guard->slot_holders;   # ( { pid => 123, label => 'prove', cwd => '/x' }, ... )

The running heavy processes that hold a slot: the topmost heavy process of
a chain, below a running C<raider>. A C<bash -c STRING> counts as its
string. Scans F</proc>; an unreadable process is skipped.

=head2 check

    my $reason = $guard->check($command);

Undef when the command may run: the gate is off, it is light, or there is
room. Otherwise the reason it is refused, to be handed to the model: the
heavy command found, the figures and the advice. The text continues the
words C<Command > that the bash tool puts in front of a reason.

=head2 validator

    my $code = $guard->validator;     # for Langertha::Raider::BashTools

A code reference for the C<validator> of L<Langertha::Raider::BashTools>: it gets the command and
returns C<1> to run it or the reason of L</check>.

=head2 confine_command

    exec @cmd if @cmd = $guard->confine_command( command => [ $guard->self_command ] );

The command line that runs C<command> inside a transient systemd user
scope with memory limits, or nothing: when C<LOADGUARD_CONFINE> is not
C<1>, the process already is confined (C<LOADGUARD_CONFINED> set), there is
no C<systemd-run> or no user manager (F<$XDG_RUNTIME_DIR/bus>), or the memory
controller is not delegated to the user manager. The caller sets
C<LOADGUARD_CONFINED=1> and execs it; if the exec fails it goes on
unconfined. For the raider itself the command is L</self_command>. Run
from a script, options given to perl itself on the command line (C<-I>) are
not carried over; C<PERL5LIB> is. The standalone binary carries its modules
and starts as it is.

=head2 self_command

    my @command = $guard->self_command;

The command line that starts this raider again: the packed binary itself
(there is no perl of its own inside it, see L<Langertha::Raider::Binary>), or
this perl with the script and its arguments.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Application>

=item * L<Langertha::Raider::Binary>

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
