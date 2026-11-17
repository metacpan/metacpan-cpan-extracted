package Langertha::Holmgang::CLI;
# ABSTRACT: The holmgang command: lint suites, run them against a Langertha engine, evaluate reports

use Moose;
use namespace::autoclean;
use Encode ();
use Getopt::Long ();
use JSON::MaybeXS ();
use Module::Runtime qw( use_module );
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Langertha::Holmgang::Batch;
use Langertha::Holmgang::Evaluation;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Target;

our $VERSION = '0.001';


has out => ( is => 'ro', lazy_build => 1 );

sub _build_out { \*STDOUT }


has err => ( is => 'ro', lazy_build => 1 );

sub _build_err { \*STDERR }


has loader => ( is => 'ro', lazy_build => 1 );

sub _build_loader { $_[0]->loader_class->new }


has checkpoint_seconds => ( is => 'ro', default => 10 );


sub loader_class     { 'Langertha::Holmgang::Loader' }
sub runner_class     { 'Langertha::Holmgang::Runner' }
sub target_class     { 'Langertha::Holmgang::Target' }
sub report_class     { 'Langertha::Holmgang::Report' }
sub evaluation_class { 'Langertha::Holmgang::Evaluation' }
sub batch_class      { 'Langertha::Holmgang::Batch' }

# the statuses of a result the target gave no answer for (ADR 0006)
my %NO_ANSWER = map { $_ => 1 } qw( error context_exceeded no_vision );

# the targets that need no network and no key (ADR 0009)
my %MOCK = ( 'mock-solution' => 'solution', 'mock-text' => 'text' );

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );

#### Plumbing

sub _say { my ( $self, @l ) = @_; print { $self->out } map { $_."\n" } @l; return }

sub _usage_error {
  my ( $self, $msg ) = @_;
  print { $self->err } 'holmgang: '.$msg."\n", "Try 'holmgang help'.\n";
  return 2;
}

# Every die text the CLI relays goes through here (k41): a Path::Tiny error
# down to its reason (the message names the path already, not a temporary file
# next to it), no Perl location (Target's rule), no module search path.
sub _text {
  my ( $self, $err ) = @_;
  my $text = blessed $err && $err->isa('Path::Tiny::Error') ? $err->{err} =~ s/\A.*: //sr
           : blessed $err ? "$err"
           :                $err // '';
  $text = $self->target_class->_strip_location($text);
  $text =~ s/\s*\(\@INC (?:contains|entries checked): [^)]*\)//;
  return $text =~ s/\s+\z//r;
}

sub _options {
  my ( $self, $args, @spec ) = @_;
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, $_[0] };
  my $p = Getopt::Long::Parser->new( config => [qw( no_ignore_case no_auto_abbrev )] );
  my %o;
  my $ok = $p->getoptionsfromarray( $args, \%o, @spec );
  return ( undef, join( '', @warn ) =~ s/\s+\z//r || 'bad options' ) unless $ok;
  return ( \%o, undef );
}

# K=V; the value as JSON when it parses as such, else as written
sub _pairs {
  my ( $self, $what, $list ) = @_;
  my %h;
  for my $p ( @{ $list || [] } ) {
    my ( $k, $v ) = $p =~ /\A([A-Za-z_][A-Za-z0-9_]*)=(.*)\z/s
      or return ( undef, $what.' expects KEY=VALUE, got: '.$p );
    my $d = eval { $JSON->decode($v) };
    $h{$k} = $@ ? $v : $d;
  }
  return ( \%h, undef );
}

sub run {
  my ( $self, @argv ) = @_;
  my $cmd = shift @argv;
  return $self->_usage_error('a command is needed: lint, run, report or export-yaml') unless defined $cmd;
  return $self->help if $cmd =~ /\A(?:help|--help|-h)\z/;
  my $method = { lint => 'cmd_lint', run => 'cmd_run', report => 'cmd_report', 'export-yaml' => 'cmd_export_yaml' }->{$cmd}
    or return $self->_usage_error( 'unknown command: '.$cmd );
  return $self->$method(@argv);
}


sub help {
  my ( $self ) = @_;
  $self->_say(
    'usage: holmgang lint <suite-dir>... [--seed ID=N]...',
    '       holmgang run --suite <dir>... --target <engine|mock-solution|mock-text>',
    '                    [--model M] [--url U] [--option K=V]... [--label L]',
    '                    [--variant [NAME:]K=V]... [--repeat N] [--concurrency N]',
    '                    [--resume earlier.json] [--report out.json] [--seed ID=N]...',
    '       holmgang report <report.json>... [--by topic] [--format text|markdown|json] [--suite <dir>]...',
    '       holmgang export-yaml <suite-dir>... --out <dir> [--seed ID=N]...',
    '',
    'Exit codes: 0 ok, 1 a suite refused, a verdict not ok or no case answered, 2 usage or setup error.',
    'Keys come from the engine\'s environment variable (e.g. LANGERTHA_OPENAI_API_KEY), never from the command line.',
  );
  return 0;
}


#### lint

# a suite directory: suite.yaml (format 2) or suite.pl (the DSL)
sub _is_suite { my ( $p ) = @_; return -f $p->child('suite.yaml') || -f $p->child('suite.pl') }

# the suite directories an argument names: itself, or its subdirectories with a suite
sub _suite_dirs {
  my ( $self, $arg ) = @_;
  my $p = path($arg);
  return unless $p->is_dir;
  return ( "$p" ) if _is_suite($p);
  return map { "$_" } sort { $a->basename cmp $b->basename } grep { $_->is_dir && _is_suite($_) } $p->children;
}

# --seed ID=N (k51): the loader's seed override for the DSL suites among
# @dirs. ( $loader ) -- this CLI's own without --seed -- or ( undef, $error )
sub _seeded_loader {
  my ( $self, $list, $dirs ) = @_;
  return ( $self->loader ) unless @{ $list || [] };
  my %dsl = map { ( path($_)->basename => 1 ) } grep { -f path($_)->child('suite.pl') } @$dirs;
  my %seeds;
  for my $p ( @$list ) {
    my ( $id, $n ) = $p =~ /\A([^=]+)=([0-9]+)\z/
      or return ( undef, '--seed expects SUITE-ID=N, got: '.$p );
    return ( undef, '--seed '.$id.': the seed is an integer from 0 to 4294967295' )
      if length $n > 10 || $n > 4294967295;
    return ( undef, '--seed '.$id.': given twice' ) if exists $seeds{$id};
    return ( undef, '--seed '.$id.': no suite in the case DSL (suite.pl) with this id in this command' )
      unless $dsl{$id};
    $seeds{$id} = 0 + $n;
  }
  my $l = $self->loader;
  return ( ref($l)->new( ( map { ( $_ => $l->$_ ) } qw( simulators haystack structure lint ) ),
    seeds => { %{ $l->seeds }, %seeds } ) );
}

sub cmd_lint {
  my ( $self, @argv ) = @_;
  my ( $o, $bad ) = $self->_options( \@argv, 'seed=s@' );
  return $self->_usage_error($bad) if $bad;
  return $self->_usage_error('lint needs at least one suite directory') unless @argv;
  my @dirs;
  for my $arg ( @argv ) {
    my @d = $self->_suite_dirs($arg);
    return $self->_usage_error( 'no suite at or below '.$arg ) unless @d;
    push @dirs, @d;
  }
  my ( $loader, $lbad ) = $self->_seeded_loader( $o->{seed}, \@dirs );
  return $self->_usage_error($lbad) unless $loader;
  my ( $ok, $refused ) = ( 0, 0 );
  for my $dir ( @dirs ) {
    my $suite = eval { $loader->load($dir) };
    if ( $suite ) {
      $ok++;
      my @cases = @{ $suite->cases };
      $self->_say( 'ok   '.$suite->id.' ('.scalar(@cases).' case'.( @cases == 1 ? '' : 's' ).')', map { '  ok '.$_->id } @cases );
    }
    else {
      $refused++;
      $self->_say( 'FAIL '.path($dir)->basename, '  '.$self->_text($@) );
    }
  }
  $self->_say( scalar(@dirs).' suite'.( @dirs == 1 ? '' : 's' ).': '.$ok.' ok, '.$refused.' refused' );
  return $refused ? 1 : 0;
}


#### export-yaml

sub cmd_export_yaml {
  my ( $self, @argv ) = @_;
  my ( $o, $bad ) = $self->_options( \@argv, 'out=s', 'seed=s@' );
  return $self->_usage_error($bad) if $bad;
  return $self->_usage_error('export-yaml needs --out, the directory the suites are written into')
    unless defined $o->{out} && length $o->{out};
  return $self->_usage_error('export-yaml needs at least one suite directory') unless @argv;
  my @dirs;
  for my $arg ( @argv ) {
    my @d = $self->_suite_dirs($arg);
    return $self->_usage_error( 'no suite at or below '.$arg ) unless @d;
    push @dirs, @d;
  }
  my @dsl = grep { -f path($_)->child('suite.pl') } @dirs;
  return $self->_usage_error( 'no suite in the case DSL (suite.pl) among: '.join( ' ', @argv ) ) unless @dsl;
  for my $dir ( @dsl ) {
    my $to = path( $o->{out}, path($dir)->basename );
    return $self->_usage_error( 'exists already, nothing is overwritten: '.$to ) if -e $to || -l $to;
  }
  my ( $loader, $lbad ) = $self->_seeded_loader( $o->{seed}, \@dirs );
  return $self->_usage_error($lbad) unless $loader;
  my ( $ok, $refused ) = ( 0, 0 );
  for my $dir ( @dirs ) {
    my $id = path($dir)->basename;
    unless ( -f path($dir)->child('suite.pl') ) {
      $self->_say( 'skip '.$id.' (format 2 already)' );
      next;
    }
    my $out = eval { $loader->export( $dir, $o->{out} ) };
    if ( defined $out ) {
      $ok++;
      my $n = () = path( $out, 'cases' )->children(qr/\.yaml\z/);
      $self->_say( 'ok   '.$id.' ('.$n.' case'.( $n == 1 ? '' : 's' ).') -> '.$out );
    }
    else {
      $refused++;
      $self->_say( 'FAIL '.$id, '  '.$self->_text($@) );
    }
  }
  $self->_say( scalar(@dsl).' DSL suite'.( @dsl == 1 ? '' : 's' ).': '.$ok.' exported, '.$refused.' refused' );
  return $refused ? 1 : 0;
}


#### run

sub _load_suites {
  my ( $self, $dirs, $loader ) = @_;
  $loader //= $self->loader;
  my @suites;
  for my $arg ( @{ $dirs || [] } ) {
    return ( undef, 'not a suite directory (no suite.yaml or suite.pl): '.$arg ) unless _is_suite( path($arg) );
    my $s = eval { $loader->load($arg) };
    return ( undef, 'suite '.$arg.' does not load: '.$self->_text($@) ) unless $s;
    push @suites, $s;
  }
  return ( \@suites, undef );
}

sub _thresholds {
  my ( $self, $suites ) = @_;
  return { map { ( $_->id => $_->threshold ) } grep { ref $_->threshold eq 'HASH' } @$suites };
}

# ( $engine_for, $target_meta ) or ( undef, $error ); $engine_for->( $case, $slot )
sub _target {
  my ( $self, $o ) = @_;
  my $name = $o->{target};
  return ( undef, 'run needs --target (an engine name such as OpenAI, or mock-solution / mock-text)' )
    unless defined $name && length $name;
  if ( my $mode = $MOCK{$name} ) {
    return ( undef, '--model, --url and --option do not apply to '.$name )
      if defined $o->{model} || defined $o->{url} || @{ $o->{option} || [] };
    my $runner = $self->runner_class;
    return ( sub { $runner->mock_engine( $_[0], $mode ) },
      { label => $o->{label} // $name, engine => 'Virtual', model => undef, url => undef } );
  }
  return ( undef, 'not an engine name: '.$name ) unless $name =~ /\A[A-Za-z_]\w*(?:::\w+)*\z/;
  my ( $opt, $bad ) = $self->_pairs( '--option', $o->{option} );
  return ( undef, $bad ) if $bad;
  return ( undef, '--option api_key is refused: the key comes from the engine\'s environment variable, never from the command line' )
    if exists $opt->{api_key};
  $opt->{model} = $o->{model} if defined $o->{model};
  $opt->{url}   = $o->{url}   if defined $o->{url};
  my $class = $name =~ /::/ ? $name : 'Langertha::Engine::'.$name;
  # a notice of the engine while it is built (a setting it drops): to stderr,
  # cleaned as a relayed error (k42)
  my @warn;
  my $engine = do {
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    eval { use_module($class)->new(%$opt) };
  };
  print { $self->err } map { 'holmgang: '.$self->target_class->scrub( $self->_text($_) )."\n" } @warn;
  return ( undef, 'target '.$name.' does not build: '.$self->target_class->scrub( $self->_text($@) ) ) unless $engine;
  return ( undef, 'target '.$name.' is no chat engine with tool calling (chat_f, format_tool_results)' )
    unless $engine->can('chat_f') && $engine->can('format_tool_results');
  my $model = $engine->can('model') ? eval { $engine->model } : undef;
  my $url   = $engine->can('url')   ? eval { $engine->url }   : undef;
  my $short = $class =~ s/\ALangertha::Engine:://r;
  # one engine per concurrency slot, each with its own connection: the first
  # is the one built above, the others are built alike when a slot first
  # needs one -- their notices were said with the first
  my @engines = ( $engine );
  my $engine_for = sub {
    my ( $case, $slot ) = @_;
    return $engines[ $slot // 0 ] //= do {
      local $SIG{__WARN__} = sub { };
      use_module($class)->new(%$opt);
    };
  };
  return ( $engine_for,
    { label => $o->{label} // $model // $short, engine => $short, model => $model, url => $url } );
}

# --variant K=V adds to the unnamed variant, --variant NAME:K=V to the variant
# NAME, --variant NAME: names a variant without settings. ( \@variants ) or
# ( undef, $error ); each variant { name, settings } with its settings checked
sub _variants {
  my ( $self, $list ) = @_;
  my ( %named, @order, @plain );
  for my $p ( @{ $list || [] } ) {
    if ( my ( $name, $rest ) = $p =~ /\A([A-Za-z0-9][A-Za-z0-9_.+-]*):(.*)\z/s ) {
      push @order, $name unless $named{$name};
      $named{$name} //= [];
      push @{ $named{$name} }, $rest if length $rest;
    }
    else {
      push @plain, $p;
    }
  }
  my @variants;
  for my $group ( ( @plain || !@order ? [ undef, \@plain ] : () ), map { [ $_, $named{$_} ] } @order ) {
    my ( $name, $pairs ) = @$group;
    my ( $settings, $bad ) = $self->_pairs( '--variant', $pairs );
    return ( undef, $bad ) if $bad;
    my $checked = eval { $self->target_class->check_variant($settings) };
    return ( undef, '--variant'.( defined $name ? ' '.$name : '' ).': '.$self->_text($@) ) unless $checked;
    $name //= %$checked
      ? join( ',', map { $_.'='.$JSON->encode( $checked->{$_} ) =~ s/\A"(.*)"\z/$1/sr } sort keys %$checked )
      : 'default';
    return ( undef, '--variant: the variant '.$name.' is named twice' ) if grep { $_->{name} eq $name } @variants;
    push @variants, { name => $name, settings => $checked };
  }
  return ( \@variants, undef );
}

sub cmd_run {
  my ( $self, @argv ) = @_;
  my ( $o, $bad ) = $self->_options( \@argv,
    'suite=s@', 'target=s', 'model=s', 'url=s', 'option=s@', 'label=s', 'variant=s@', 'repeat=i',
    'concurrency=i', 'resume=s', 'report=s', 'seed=s@' );
  return $self->_usage_error($bad) if $bad;
  return $self->_usage_error( 'unexpected argument: '.$argv[0] ) if @argv;
  return $self->_usage_error('run needs at least one --suite') unless @{ $o->{suite} || [] };
  return $self->_usage_error('--repeat must be between 1 and 100')
    if defined $o->{repeat} && ( $o->{repeat} < 1 || $o->{repeat} > 100 );
  return $self->_usage_error('--concurrency must be between 1 and 64')
    if defined $o->{concurrency} && ( $o->{concurrency} < 1 || $o->{concurrency} > 64 );
  my ( $variants, $vbad ) = $self->_variants( $o->{variant} );
  return $self->_usage_error($vbad) if $vbad;
  my ( $engine_for, $target ) = $self->_target($o);
  return $self->_usage_error($target) unless $engine_for;
  my ( $loader, $lbad ) = $self->_seeded_loader( $o->{seed}, [ grep { _is_suite( path($_) ) } @{ $o->{suite} } ] );
  return $self->_usage_error($lbad) unless $loader;
  my ( $suites, $sbad ) = $self->_load_suites( $o->{suite}, $loader );
  return $self->_usage_error($sbad) if $sbad;
  my $resume;
  if ( defined $o->{resume} ) {
    $resume = eval { $self->report_class->read( $o->{resume} ) };
    return $self->_usage_error( 'report '.$o->{resume}.' does not read: '.$self->_text($@) ) unless $resume;
  }

  my $several = @$variants > 1;
  my $batch;
  my $last_write = time;
  my $on_event = sub {
    my ( $e ) = @_;
    my $at = ( $several ? $e->{variant}.' ' : '' ).$e->{suite}->id;
    if ( $e->{type} eq 'result' ) {
      $self->_say( $at.' '.$e->{case}->id.' #'.$e->{repetition}.' '.$e->{result}{status} );
      $self->_checkpoint( $batch, $o->{report}, \$last_write ) if defined $o->{report};
    }
    elsif ( $e->{type} eq 'vision' ) {
      my $check = $e->{check};
      my $no_vision = $check->{no_vision};
      $self->_say( $at.' vision check: '.(
          defined $no_vision               ? 'no_vision -- '.$self->_one_line($no_vision)
        : defined $check->{added_tokens} ? 'seen (the image added '.$check->{added_tokens}.' input tokens)'
        :                                  'not ruled out -- '.$self->_one_line( $check->{note} // 'no check decided' ) ) );
    }
    elsif ( $e->{type} eq 'aborted' ) {
      $self->_say( $e->{case}
        ? $at.' '.$e->{case}->id.' #'.$e->{repetition}.' aborted: '.$e->{error}
        : $at.' vision check aborted: '.$e->{error} );
    }
    return;
  };
  $batch = eval {
    $self->batch_class->new(
      suites   => $suites,
      targets  => [ {
        target      => $target,
        engine      => $engine_for,
        variants    => $variants,
        concurrency => $o->{concurrency} // 1,
      } ],
      ( defined $o->{repeat} ? ( repeat => $o->{repeat} ) : () ),
      ( $resume ? ( resume => $resume ) : () ),
      on_event => $on_event,
    );
  };
  return $self->_usage_error( $self->target_class->scrub( $self->_text($@) ) ) unless $batch;

  # a signal cancels: no further case starts, the cases in play finish and
  # the report is written; a second signal ends the process at once
  my $cancel = sub {
    my ( $sig ) = @_;
    $SIG{$sig} = 'DEFAULT';
    $batch->cancel;
    print { $self->err } 'holmgang: '.$sig.': cancelling -- no further case starts, the cases in play finish'."\n";
  };
  my $report = do {
    local @SIG{qw( INT TERM )} = ( $cancel, $cancel );
    eval { $batch->run };
  };
  return $self->_usage_error( 'the batch failed: '.$self->target_class->scrub( $self->_text($@) ) ) unless $report;
  if ( defined $o->{report} ) {
    eval { $report->write( $o->{report} ); 1 }
      or return $self->_usage_error( 'report '.$o->{report}.' not written: '.$self->_text($@) );
  }
  my $ev = $self->evaluation_class->new( report => $report, thresholds => $self->_thresholds($suites) );
  $self->_say( '', $ev->to_text );
  $self->_say( 'report: '.$o->{report} ) if defined $o->{report};
  # an aborted or cancelled run (k15)
  return 2 if grep { $_->{status} ne 'complete' } @{ $report->runs };

  # the report holds the results in suite, case and repetition order: the
  # first error text found is the first of the run (k44)
  my ( @unanswered, @silent, $first_error );
  my $measured = 0;
  for my $run ( @{ $report->runs } ) {
    my @reps = map { @{ $_->{repetitions} } } @{ $run->{cases} };
    ( $first_error ) = grep { defined && length } map { $_->{error} } @reps unless defined $first_error;
    my @none = grep { $NO_ANSWER{$_} } map { $_->{status} } @reps;
    push @unanswered, @none;
    $measured += @reps - @none;
    push @silent, [ ( $several ? $run->{variant}{name}.' ' : '' ).$run->{suite}{id}, $self->_tally(@none) ]
      if @reps && @reps == @none;
  }
  # no answer over the whole run: nothing was measured, whatever the verdicts (k42)
  unless ( $measured ) {
    print { $self->err } 'holmgang: no case got an answer from the target ('
      .$self->_tally(@unanswered).')'
      .( defined $first_error ? '; first: '.$self->_one_line($first_error) : '' )."\n";
    return 1;
  }
  print { $self->err } 'holmgang: suite '.$_->[0].': no case got an answer from the target ('.$_->[1].')'."\n" for @silent;
  return ( grep { !$_->{ok} } @{ $ev->verdicts } ) ? 1 : 0;
}

# the report as it stands, at most every checkpoint_seconds; a checkpoint
# that cannot be written is said once and the run goes on
sub _checkpoint {
  my ( $self, $batch, $file, $last ) = @_;
  return unless $batch && time - $$last >= $self->checkpoint_seconds;
  $$last = time;
  return if eval { $batch->report->write($file); 1 };
  print { $self->err } 'holmgang: checkpoint '.$file.' not written: '.$self->_text($@)."\n" unless $self->{_checkpoint_said}++;
  return;
}

# an error text for a note: on one line, cut to 200 characters with an ellipsis.
# The result's error went through the target's scrub already (chat_turn_f).
sub _one_line {
  my ( $self, $text ) = @_;
  $text = join ' ', split ' ', $text;
  return $text if length $text <= 200;
  return substr( $text, 0, 200 ) =~ s/\s+\z//r." \x{2026}";
}

# "2 error, 1 context_exceeded" in the order of the statuses
sub _tally {
  my ( $self, @statuses ) = @_;
  my %n;
  $n{$_}++ for @statuses;
  return join ', ', map { $n{$_}.' '.$_ } grep { $n{$_} } qw( error context_exceeded no_vision );
}


#### report

sub cmd_report {
  my ( $self, @argv ) = @_;
  my ( $o, $bad ) = $self->_options( \@argv, 'by=s', 'format=s', 'suite=s@' );
  return $self->_usage_error($bad) if $bad;
  return $self->_usage_error('report needs at least one report file') unless @argv;
  my $by = $o->{by} // 'topic';
  return $self->_usage_error( '--by '.$by.': the evaluation is per topic, --by topic is the only one' )
    unless $by eq 'topic';
  my $format = $o->{format} // 'text';
  return $self->_usage_error( 'unknown --format '.$format.' (text, markdown, json)' )
    unless $format =~ /\A(?:text|markdown|json)\z/;
  my @reports;
  for my $file ( @argv ) {
    my $r = eval { $self->report_class->read($file) };
    return $self->_usage_error( 'report '.$file.' does not read: '.$self->_text($@) ) unless $r;
    push @reports, $r;
  }
  my ( $suites, $sbad ) = $self->_load_suites( $o->{suite} );
  return $self->_usage_error($sbad) if $sbad;
  my $ev = eval { $self->evaluation_class->new( reports => \@reports, thresholds => $self->_thresholds($suites) ) };
  return $self->_usage_error( 'reports do not evaluate: '.$self->_text($@) ) unless $ev;
  my $verdicts = eval { $ev->verdicts };
  return $self->_usage_error( 'reports do not evaluate: '.$self->_text($@) ) unless $verdicts;
  my $text = $format eq 'json'     ? Encode::decode( 'UTF-8', $ev->to_json )
           : $format eq 'markdown' ? $ev->to_markdown
           :                         $ev->to_text;
  $text .= "\n" unless $text =~ /\n\z/;
  print { $self->out } $text;
  return ( grep { !$_->{ok} } @$verdicts ) ? 1 : 0;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::CLI - The holmgang command: lint suites, run them against a Langertha engine, evaluate reports

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Langertha::Holmgang::CLI;

  exit Langertha::Holmgang::CLI->new->run(@ARGV);

  # in a test: capture the output, get the exit code
  open my $out, '>', \my $text;
  my $code = Langertha::Holmgang::CLI->new( out => $out, err => $out )
    ->run( lint => '/tmp/suites/demo' );

=head1 DESCRIPTION

The commands behind F<bin/holmgang> (ADR 0009): C<lint> loads suites as the
loader does, C<run> plays them against a target and writes a report, C<report>
evaluates report files per topic, C<export-yaml> writes DSL suites as suite
format 2. Every command returns its exit code instead
of exiting: C<0> all well, C<1> a suite refused, a verdict not ok, or a run in
which the target answered no case, C<2> a usage or setup error. The options
are described in L<holmgang>.

The CLI reads no key: a real engine takes its key from where Langertha reads
it (its environment variable). There is no default target.

=head2 out

The handle for the command's output; standard output by default.

=head2 err

The handle for usage and setup errors; standard error by default.

=head2 loader

The L<Langertha::Holmgang::Loader> every suite goes through.

=head2 checkpoint_seconds

How often C<run --report> writes the report while the batch runs, at most:
after a result, when this many seconds have passed since the last write.
Default 10; C<0> writes after every result. The checkpoint is what
C<--resume> continues after a crash.

=head2 run

  my $code = $cli->run( 'lint', @dirs );

Runs one command with its arguments (C<@ARGV> as the shell gives it) and
returns the exit code. C<help>, C<--help> and C<-h> print the usage.

=head2 help

Prints the usage; returns 0.

=head2 cmd_lint

  my $code = $cli->cmd_lint(@dirs);

C<holmgang lint>: loads every suite (a suite directory, or each suite in a
search directory) through L</loader> -- structure, lint and both mock runs.
Prints C<ok> with every case id, or C<FAIL> with the refusal (it names the
case file and field; loading stops at the first refused case). Returns 1 when
a suite was refused, 2 for a path that holds no suite. C<--seed ID=N>
(repeatable) replaces the seed of every C<generate> block of the DSL suite
C<ID> (L<Langertha::Holmgang::Loader/seeds>); an id that is no DSL suite of
the command is a usage error.

=head2 cmd_export_yaml

  my $code = $cli->cmd_export_yaml( @dirs, '--out', $root );

C<holmgang export-yaml>: writes every suite in the case DSL (a suite
directory with F<suite.pl>, or each one in a search directory) as suite
format 2 into C<--out>/I<id> (L<Langertha::Holmgang::Loader/export>): it is
loaded first, lint included, and the export must load back with the same
digest. A format 2 suite among them is skipped (C<skip>). Prints C<ok> with
the case count and the written directory, or C<FAIL> with the refusal.
C<--seed ID=N> as for C<lint>. Returns 1 when a suite was refused; 2 for a
usage error -- no C<--out>, no DSL suite, or a suite directory that already
exists under C<--out> (nothing is overwritten; checked before anything is
written).

=head2 cmd_run

  my $code = $cli->cmd_run( '--suite', $dir, '--target', 'mock-solution', '--report', $file );

C<holmgang run>: loads the suites (C<--seed ID=N> as for C<lint>), builds the target (an engine name with
C<--model>, C<--url>, C<--option>; or C<mock-solution> / C<mock-text>) and its
variants (C<--variant>), and plays them through L<Langertha::Holmgang::Batch>:
every case C<--repeat> times (default the suite's C<repeat>, else 1) under
every variant, at most C<--concurrency> requests at once (default 1, one
engine per slot), continuing the report of C<--resume>. It prints a line per
result as it ends (prefixed with the variant when there are several) and the
evaluation, and writes the report with C<--report> -- at the end, and as a
checkpoint while the batch runs (L</checkpoint_seconds>). Before the cases of
a suite with images the batch runs the vision pre-check once per variant
(L<Langertha::Holmgang::Target/vision_check_f>); the outcome is printed; when
it finds the target blind, every case with images of that suite ends
C<no_vision> without a request. SIGINT and SIGTERM cancel the batch: no
further case starts, the cases in play finish, the report is written. Returns
1 when a verdict is not ok, 2 for a usage or setup error, an aborted or a
cancelled run.

When the target answered no case of the whole run -- every result, over all
suites and repetitions, is C<error>, C<context_exceeded> or C<no_vision> -- the
run measured nothing: it says so on the error handle with the count per status
and the first error text of the run (the first result in suite, case and
repetition order; already scrubbed by the target, put on one line, cut to 200
characters with an ellipsis) and returns 1, whatever the verdicts. The report is written as always. When at
least one result was measured, the verdicts decide; a suite in which no case
got an answer then gets a note on the error handle, and one whose results are
all C<error> also fails its verdict (C<NOT MEASURED>,
L<Langertha::Holmgang::Evaluation/verdicts>), so the run returns 1; all
C<context_exceeded> or C<no_vision> is a measurement and gets only the note.
An aborted run stays 2.
The engine's warnings while it is built go to the error handle, cleaned like
a relayed error.

=head2 cmd_report

  my $code = $cli->cmd_report( @files, '--format', 'markdown', '--suite', $dir );

C<holmgang report>: reads the report files, joins them in one
L<Langertha::Holmgang::Evaluation> and prints it as text, Markdown or JSON.
Thresholds come from the suites given with C<--suite>; without them a verdict
is judged by its hard cases, an unfinished run and whether anything was
measured (L<Langertha::Holmgang::Evaluation/verdicts>). Returns 1 when a
verdict is not ok -- among them a suite whose results are all C<error>, so a
report of a run that measured nothing returns 1 as C<run> did -- and 2 when a
file does not read or the reports conflict.

=head1 SEE ALSO

=over 4

=item * L<holmgang>

=item * L<Langertha::Holmgang::Runner>

=item * L<Langertha::Holmgang::Evaluation>

=back

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
