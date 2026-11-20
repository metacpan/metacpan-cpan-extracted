package Langertha::Holmgang;
# ABSTRACT: Deterministic tool-use benchmarks for language models via Langertha

# Runs the code of a suite.pl. Defined before any pragma and any lexical of
# this file, so the suite file sees neither -- as under "do FILE".
sub _compile { eval $_[0]; return $@ }

use strict;
use warnings;

our $VERSION = '0.002';

use Carp qw( croak );
use Moose::Exporter;
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Expectation ();
use Langertha::Holmgang::Random;

my @KEYWORDS = qw(
  suite title description version topic license repeat threshold source
  system_prompt settings tool handler case generate difficulty weight tags tier
  ask message image device world observe rule
  at unchanged_except calls not_called only_tools check packet login
  solution alternative wrong call run put file haystack excerpt
);

Moose::Exporter->setup_import_methods( as_is => \@KEYWORDS );

# The block being declared: the innermost open suite or case, and the
# loader's context while it runs a suite.pl. Package state by necessity:
# exported keywords have no other way to reach the block they belong to;
# both are only ever set with local, so they hold for one block (one file).
our $OPEN;
our $LOADING;

my $PACKAGES = 0;

my %SETTINGS   = map { $_ => 1 } qw( temperature max_tokens max_turns );
my %RULE_REST  = (
  state            => [ @Langertha::Holmgang::Expectation::MATCHERS, @Langertha::Holmgang::Expectation::MODIFIERS ],
  unchanged_except => [],
  calls            => [],
  not_called       => [],
  only_tools       => [],
  check            => ['expect'],
  packet           => [qw( verdict boot )],
  login            => ['result'],
);

#### the block a keyword belongs to

sub _block {
  my ( $kw, @kinds ) = @_;
  croak $kw.': only inside a '.join( ' or ', @kinds ).' block'
    unless $OPEN && grep { $OPEN->{kind} eq $_ } @kinds;
  return $OPEN;
}

# a single-valued keyword: once per block
sub _once {
  my ( $blk, $kw ) = @_;
  croak $kw.': given twice in '.$blk->{kind}.' '.$blk->{id} if $blk->{once}{$kw}++;
  return;
}

sub _pairs {
  my ( $kw, $ok, @pairs ) = @_;
  croak $kw.': pairs expected (key => value)' if @pairs % 2;
  my %h  = @pairs;
  my %ok = map { $_ => 1 } @$ok;
  for my $k ( sort keys %h ) {
    croak $kw.": unknown key '".$k."' (".join( ', ', @$ok ).')' unless $ok{$k};
  }
  return \%h;
}

sub _here { my ( undef, $file, $line ) = caller(1); return ( $file, $line ) }

#### suite and case

sub suite {
  my ( $id, $code ) = @_;
  croak 'suite: id and block expected (suite ID => sub { ... })' unless defined $id && !ref $id && ref $code eq 'CODE';
  croak 'suite: a suite does not nest' if $OPEN;
  my ( $file ) = (caller)[1];
  my ( $label, $dir );
  if ( $LOADING ) {
    croak 'suite: a suite.pl declares exactly one suite' if $LOADING->{declared}++;
    ( $label, $dir ) = ( 'suite.pl', $LOADING->{dir} );
  }
  else {
    my $p = path($file);
    ( $label, $dir ) = ( $p->basename, $p->parent->stringify );
  }
  my $blk = { kind => 'suite', id => $id, head => { id => $id }, cases => [], seen => {}, dir => $dir };
  {
    local $OPEN = $blk;
    $code->();
  }
  my $tools = $blk->{head}{tools} || [];
  my $head  = _finish( $blk->{head}, $tools );
  my @cases = map { _finish( $_, $tools ) } @{ $blk->{cases} };
  my $loader = $LOADING ? $LOADING->{loader} : do { require Langertha::Holmgang::Loader; Langertha::Holmgang::Loader->new };
  my $suite = $loader->assemble(
    head  => $head,
    cases => \@cases,
    file  => $label,
    dir   => $dir,
    ( $LOADING ? ( dirname => $LOADING->{dirname} ) : () ),
  );
  push @{ $LOADING->{suites} }, $suite if $LOADING;
  return $suite;
}

sub case {
  my ( $id, $code ) = @_;
  croak 'case: id and block expected (case ID => sub { ... })' unless defined $id && !ref $id && ref $code eq 'CODE';
  my $suite = _block( 'case', 'suite' );
  croak "case: id '".$id."' twice in suite ".$suite->{id} if $suite->{seen}{$id}++;
  my $blk = { kind => 'case', id => $id, data => { id => $id }, suite => $suite };
  {
    local $OPEN = $blk;
    $code->();
  }
  push @{ $suite->{cases} }, $blk->{data};
  return;
}

sub generate {
  my ( @args ) = @_;
  my $code = pop @args;
  croak 'generate: seed and block expected (generate seed => N, sub { ... })' unless ref $code eq 'CODE';
  my $o = _pairs( 'generate', ['seed'], @args );
  croak 'generate: seed missing' unless defined $o->{seed};
  my $suite = _block( 'generate', 'suite' );
  my $seed  = $o->{seed};
  if ( $LOADING && defined( my $over = $LOADING->{loader}->seeds->{ $suite->{id} } ) ) { $seed = $over }
  my $rng = eval { Langertha::Holmgang::Random->new( seed => $seed ) }
    or croak 'generate: seed must be an integer from 0 to 4294967295';
  $code->($rng);
  return;
}

#### suite head

sub _head_or_case {
  my ( $kw, $value ) = @_;
  my $blk = _block( $kw, 'suite', 'case' );
  _once( $blk, $kw );
  ( $blk->{kind} eq 'suite' ? $blk->{head} : $blk->{data} )->{$kw} = $value;
  return;
}

sub _head {
  my ( $kw, $value ) = @_;
  my $blk = _block( $kw, 'suite' );
  _once( $blk, $kw );
  $blk->{head}{$kw} = $value;
  return;
}

sub _case {
  my ( $kw, $value ) = @_;
  my $blk = _block( $kw, 'case' );
  _once( $blk, $kw );
  $blk->{data}{$kw} = $value;
  return;
}

sub title       { _head_or_case( title => $_[0] ) }
sub description { _head( description => $_[0] ) }
sub version     { _head( version => $_[0] ) }
sub topic       { _head( topic => $_[0] ) }
sub license     { _head( license => $_[0] ) }
sub repeat      { _head( repeat => $_[0] ) }
sub threshold   { _head( threshold => _pairs( 'threshold', [qw( pass_rate pass_k )], @_ ) ) }
sub source      { _head_or_case( source => _pairs( 'source', [qw( title authors license url location )], @_ ) ) }

sub system_prompt {
  my ( $text ) = @_;
  my $blk = _block( 'system_prompt', 'suite', 'case' );
  _once( $blk, 'system_prompt' );
  if ( $blk->{kind} eq 'suite' ) { $blk->{head}{defaults}{system} = $text }
  else                           { $blk->{data}{system} = $text }
  return;
}

sub settings {
  my $o   = _pairs( 'settings', [ sort keys %SETTINGS ], @_ );
  my $blk = _block( 'settings', 'suite', 'case' );
  my $to  = $blk->{kind} eq 'suite' ? ( $blk->{head}{defaults} //= {} ) : $blk->{data};
  for my $k ( sort keys %$o ) {
    _once( $blk, 'settings '.$k );
    $to->{$k} = $o->{$k};
  }
  return;
}

sub tool {
  my ( $name, @pairs ) = @_;
  croak 'tool: name expected' unless defined $name && !ref $name;
  my $o   = _pairs( 'tool', [qw( description parameters simulator handlers )], @pairs );
  my $blk = _block( 'tool', 'suite' );
  push @{ $blk->{head}{tools} }, { name => $name, %$o };
  return;
}

sub handler { _pairs( 'handler', [qw( match when apply output error )], @_ ) }

#### case

sub difficulty { _case( difficulty => $_[0] ) }
sub weight     { _case( weight => $_[0] ) }

sub tags {
  my ( @tags ) = @_;
  my $blk = _block( 'tags', 'case' );
  croak 'tags: one tier per case (tier already set)' if $blk->{once}{tier} && grep { defined && /\Astufe-/ } @tags;
  push @{ $blk->{data}{tags} }, @tags;
  return;
}

sub tier {
  my ( $tier ) = @_;
  my $blk = _block( 'tier', 'case' );
  croak "tier: a length tier like '48k' expected" unless defined $tier && !ref $tier && $tier =~ /\A\d+k\z/;
  croak 'tier: one tier per case' if $blk->{once}{tier}++ || grep { /\Astufe-/ } @{ $blk->{data}{tags} || [] };
  push @{ $blk->{data}{tags} }, 'stufe-'.$tier;
  return;
}

sub image {
  my ( $file, @pairs ) = @_;
  croak 'image: file expected' unless defined $file && !ref $file;
  return { file => $file, %{ _pairs( 'image', ['untrusted'], @pairs ) } };
}

sub _message {
  my ( $kw, $role, $content, @pairs ) = @_;
  my $o   = _pairs( $kw, [qw( untrusted images )], @pairs );
  my $blk = _block( $kw, 'case' );
  if ( ref $o->{images} eq 'ARRAY' ) {
    $o->{images} = [ map { defined $_ && !ref $_ ? { file => $_ } : $_ } @{ $o->{images} } ];
  }
  push @{ $blk->{data}{messages} }, { role => $role, content => $content, %$o };
  return;
}

sub ask     { _message( 'ask', 'user', @_ ) }
sub message { _message( 'message', @_ ) }

sub device {
  my ( $name, $type, $state ) = ( shift, shift, shift );
  croak 'device: NAME => TYPE => { ... } expected' if @_ || !defined $name || ref $name || !defined $type || ref $type;
  $state //= {};
  croak 'device: the state of '.$name.' must be a hash' unless ref $state eq 'HASH';
  croak 'device: the type is the second argument, not a key of the state' if exists $state->{type};
  my $blk = _block( 'device', 'case' );
  croak 'device: '.$name.' twice in the state' if exists $blk->{data}{state}{$name};
  $blk->{data}{state}{$name} = { type => $type, %$state };
  return;
}

sub world {
  croak 'world: NAME => VALUE expected' unless @_ == 2 && defined $_[0] && !ref $_[0];
  my ( $name, $value ) = @_;
  my $blk = _block( 'world', 'case' );
  croak 'world: '.$name.' twice in the state' if exists $blk->{data}{state}{$name};
  $blk->{data}{state}{$name} = $value;
  return;
}

sub observe {
  my $o   = _pairs( 'observe', [qw( match when output error )], @_ );
  my $blk = _block( 'observe', 'case' );
  push @{ $blk->{data}{observe} }, $o;
  return;
}

sub rule {
  my ( $title, $kind, @rest ) = @_;
  croak 'rule: TITLE => KIND expected (a rule kind: at, unchanged_except, calls, not_called, only_tools, check, packet, login)'
    if @rest || !defined $title || ref $title || ref $kind ne 'HASH'
    || exists $kind->{title} || 1 != grep { exists $kind->{$_} } sort keys %RULE_REST;
  my $blk = _block( 'rule', 'case' );
  push @{ $blk->{data}{rules} }, { title => $title, %$kind };
  return;
}

#### rule kinds (constructors)

sub _kind {
  my ( $kw, $kind, $value, @pairs ) = @_;
  my $o = _pairs( $kw, [ @{ $RULE_REST{$kind} }, 'required' ], @pairs );
  return { %$o, $kind => $value };
}

sub at               { _kind( at => state => @_ ) }
sub unchanged_except { _kind( unchanged_except => unchanged_except => @_ ) }
sub calls            { _kind( calls => calls => @_ ) }
sub not_called       { _kind( not_called => not_called => @_ ) }
sub only_tools       { _kind( only_tools => only_tools => @_ ) }
sub check            { _kind( check => check => @_ ) }
sub packet           { _kind( packet => packet => @_ ) }
sub login            { _kind( login => login => @_ ) }

#### solutions and calls

sub _calls_of {
  my ( $kw, @calls ) = @_;
  for ( @calls ) {
    croak $kw.': calls expected (call, run, put)' unless ref $_ eq 'HASH' || blessed $_ && $_->isa('Langertha::Holmgang::_Pending');
  }
  return \@calls;
}

sub solution {
  my $blk = _block( 'solution', 'case' );
  _once( $blk, 'solution' );
  $blk->{data}{solution} = _calls_of( 'solution', @_ );
  return;
}

sub alternative {
  my ( $title, @calls ) = @_;
  my $blk = _block( 'alternative', 'case' );
  push @{ $blk->{data}{alternatives} }, { title => $title, calls => _calls_of( 'alternative', @calls ) };
  return;
}

sub wrong {
  my ( $title, @calls ) = @_;
  my $blk = _block( 'wrong', 'case' );
  push @{ $blk->{data}{wrong_solutions} }, { title => $title, calls => _calls_of( 'wrong', @calls ) };
  return;
}

sub call($$) {
  my ( $tool, $args ) = @_;
  croak 'call: TOOL => { ARGS } expected' unless defined $tool && !ref $tool && ( !defined $args || ref $args eq 'HASH' );
  return { tool => $tool, args => $args // {} };
}

sub run($$) {
  my ( $host, $command ) = @_;
  return bless { simulator => 'run_command', args => { host => $host, command => $command }, at => [ _here() ] },
    'Langertha::Holmgang::_Pending';
}

sub put($$$) {
  my ( $host, $p, $content ) = @_;
  return bless { simulator => 'write_file', args => { host => $host, path => $p, content => $content }, at => [ _here() ] },
    'Langertha::Holmgang::_Pending';
}

sub file($) {
  my ( $name ) = @_;
  croak 'file: a file name expected' unless defined $name && !ref $name && length $name;
  my $base = $OPEN ? _suite_dir() : path( (caller)[1] )->parent;
  my $p    = path( $base, $name );
  my $text = eval { $p->slurp_utf8 };
  croak 'file: cannot read '.$name.' (relative to '.$base.')' unless defined $text;
  return $text;
}

sub _suite_dir { return ( $OPEN->{kind} eq 'suite' ? $OPEN : $OPEN->{suite} )->{dir} }

# the spec's keys are checked when the suite closes, by Haystack through
# Structure, with the field path
sub haystack {
  croak 'haystack: pairs expected (key => value)' if @_ % 2;
  return { generate => {@_} };
}

# an excerpt from a statute text under quellen/ (k52): the format 2 part
# { auszug => { datei, von, bis } }; the file and the range are checked when
# the suite closes, by Structure through ::Excerpt, with the field path
sub excerpt {
  my ( $file, @pairs ) = @_;
  croak "excerpt: a file under quellen/ expected (excerpt 'quellen/NAME.txt', from => ..., to => ...)"
    unless defined $file && !ref $file && length $file;
  my $o = _pairs( 'excerpt', [qw( from to )], @pairs );
  for my $k (qw( from to )) {
    croak 'excerpt: '.$k.' => the label of a provision expected' unless defined $o->{$k} && !ref $o->{$k};
  }
  return { auszug => { datei => $file, von => $o->{from}, bis => $o->{to} } };
}

#### closing a suite

# a defensive deep copy of what the blocks recorded, in format 2 terms: a qr//
# becomes its string form, run/put become calls of the one tool with that
# simulator
sub _finish {
  my ( $data, $tools ) = @_;
  my %by_sim;
  for my $t ( grep { ref $_ eq 'HASH' && defined $_->{simulator} && !ref $_->{simulator} } @$tools ) {
    push @{ $by_sim{ $t->{simulator} } }, $t->{name};
  }
  return _walk( $data, \%by_sim );
}

sub _walk {
  my ( $d, $sim ) = @_;
  return "$d" if re::is_regexp($d);
  if ( blessed $d && $d->isa('Langertha::Holmgang::_Pending') ) {
    my $names = $sim->{ $d->{simulator} } || [];
    die sprintf( "%s: the suite needs exactly one tool with simulator %s, it has %d at %s line %d.\n",
      ( $d->{simulator} eq 'run_command' ? 'run' : 'put' ), $d->{simulator}, scalar @$names, @{ $d->{at} } )
      unless @$names == 1;
    return { tool => $names->[0], args => _walk( $d->{args}, $sim ) };
  }
  return { map { ( $_ => _walk( $d->{$_}, $sim ) ) } keys %$d } if ref $d eq 'HASH';
  return [ map { _walk( $_, $sim ) } @$d ] if ref $d eq 'ARRAY';
  return $d;
}

#### suite.pl (called by the loader)

sub _load_file {
  my ( %o ) = @_;
  local $LOADING = { %o, suites => [], declared => 0 };
  local $OPEN;
  my $pkg = 'Langertha::Holmgang::_SuiteFile'.++$PACKAGES;
  ( my $line = $o{path} ) =~ s/["\r\n]/_/g;
  # UTF-8 source whether the file says use utf8 or not (k60): a suite's texts
  # are what the model is sent, and Latin-1 mojibake is never what was meant
  my $err = _compile( 'package '.$pkg.";use utf8;\n#line 1 \"".$line."\"\n".$o{code}."\n" );
  if ( ref $err || length $err ) {
    die $err if Langertha::Holmgang::Error->caught($err);
    Langertha::Holmgang::Error->throw( 'suite.pl', "$err" =~ s/\s+\z//r );
  }
  Langertha::Holmgang::Error->throw( 'suite.pl', 'declares no suite' ) unless @{ $LOADING->{suites} };
  return $LOADING->{suites}[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang - Deterministic tool-use benchmarks for language models via Langertha

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  # lint a suite in format 2: shape checks, the self-check of every case, two mock runs
  holmgang lint /data/suites/demo-motd

  # a dry run without network: the mock model replays every reference solution
  holmgang run --suite /data/suites/demo-motd --target mock-solution --report /data/reports/dry.json

  # a real target: any Langertha engine; the key comes from the engine's environment variable
  holmgang run --suite /data/suites/demo-motd --target vLLM \
    --url http://10.0.0.5:8000/v1 --model some-model --repeat 3 --report /data/reports/run.json

  # evaluate reports per topic
  holmgang report /data/reports/*.json --suite /data/suites/demo-motd --format markdown

=head1 DESCRIPTION

Langertha::Holmgang measures language models on B<tasks with tools> and grades
them B<deterministically>: no judge model and no text comparison. A case is a
task in a simulated world; the model works on it through general tools with
real syntax, and the case passes only when the world ends up in the right
state. Any engine that L<Langertha> speaks can be measured.

A I<holmgang> was a Norse duel under fixed rules: a marked-out ground,
witnesses, agreed weapons, and a verdict everyone accepted.

=head1 STATUS

Usable today: suites in B<format 2> (F<suite.yaml> plus F<cases/*.yaml>) and
in the B<case DSL> of this module (F<suite.pl>, L</THE CASE DSL>) with the
loader and its lint, the simulators, the grader, the runner over any
Langertha engine, several variants per target, parallel requests and resume
(L<Langertha::Holmgang::Batch>), the JSON report, the evaluation per topic,
the YAML export of a DSL suite (L<Langertha::Holmgang::Loader/export>), and
the F<holmgang> command line (C<lint>, C<run>, C<report>, C<export-yaml>).

The distribution ships B<no real benchmark cases>: published cases end up in
the training data of the next models.

=head1 THE CASE DSL

  use Langertha::Holmgang;

  suite 'example-sums' => sub {
    title   'Example: add numbers, hand in the sum';
    version 1;
    topic   'reasoning';
    system_prompt 'Use the tool to hand in your answer. Then reply briefly without a tool.';

    tool submit_answer => (
      description => 'Hand in the final answer. A later call replaces an earlier one.',
      parameters  => { type => 'object', required => ['value'],
                       properties => { value => { type => 'integer' } } },
      handlers    => [ handler apply => [ { set => 'answer', value => '{value|int}' } ], output => 'ok' ],
    );

    generate seed => 4711, sub {
      my ( $rng ) = @_;
      for my $n ( 1 .. 3 ) {
        my @terms = map { $rng->int( 10, 99 ) } 1 .. 4;
        my $sum = 0;
        $sum += $_ for @terms;
        case sprintf( 'sum-%02d', $n ) => sub {
          title      'Sum of four numbers, variant '.$n;
          difficulty 'leicht';
          world answer => undef;
          ask 'Add '.join( ', ', @terms ).' and hand in the sum.';
          rule 'sum handed in'      => at 'answer', equals => $sum;
          rule 'nothing else moved' => unchanged_except ['answer'];
          solution    call submit_answer => { value => $sum };
          alternative 'corrected answer' =>
            call( submit_answer => { value => $sum - 1 } ), call( submit_answer => { value => $sum } );
          wrong 'off by one' => call submit_answer => { value => $sum + 1 };
        };
      }
    };
  };

C<use Langertha::Holmgang> exports the keywords below (and, as every
L<Moose::Exporter> module does, turns on C<strict> and C<warnings>);
C<no Langertha::Holmgang> removes them. A keyword can be renamed on import, for
a file that also uses a module exporting the same name:

  use Langertha::Holmgang call => { -as => 'tool_call' };

The DSL is sugar over suite format 2 (ADR 0004, ADR 0007): every keyword
writes a format 2 key, and when the C<suite> block closes the suite goes
through the same structure checks, the same lint with both mock runs and the
same runner as a F<suite.yaml> (L<Langertha::Holmgang::Loader/assemble>). A
refusal names the file, the case and the field like the loader's:
C<suite.pl: case sum-01: rules[0].equals>. A keyword outside its block, a
single-valued keyword given twice, or an unknown key in a keyword's pairs
dies at the line that wrote it.

=head2 Where DSL suites live

A suite directory in a search directory holds B<either> F<suite.yaml> with
F<cases/> B<or> a F<suite.pl>; both is refused. F<suite.pl> declares exactly
one C<suite>, whose id is the directory name; texts for L</file> and images
sit beside it. The loader runs the file in a package of its own: it is code,
with the trust of an installed module, so load it only from directories you
control. Outside the loader -- in a test or a script -- C<suite> returns the
L<Langertha::Holmgang::Suite> as well, and paths are relative to the calling
file.

Cases are ordered by the name of their export file, F<E<lt>idE<gt>.yaml> --
the order format 2 loads case files in, so C<a-b> comes before C<a>; an id
given twice dies.

=head2 The YAML export

  holmgang export-yaml /srv/dsl-suites/example-sums --out /srv/exported

writes the suite as suite format 2 -- F<suite.yaml>, F<cases/E<lt>idE<gt>.yaml>
and the images -- so its cases can be read and compared without Perl
(L<Langertha::Holmgang::Loader/export>). Texts read by C<file> are inline,
C<haystack> specs stay C<generate> specs, generated cases are plain cases. The
export loads into the same suite, and a DSL suite's digest I<is> the digest of
its export: a run of the one is a run of the other.

=head2 Two kinds of keywords

I<Declarations> (C<suite>, C<case>, C<title>, C<rule>, C<device>, ...) record
into the innermost open C<suite> or C<case> block and return nothing.
I<Constructors> (C<at>, C<call>, C<run>, C<file>, C<handler>, ...) record
nothing and return a piece of format 2 data, so they can be used anywhere,
also in variables and loops. Fixed-arity constructors carry a prototype --
C<call($$)>, C<run($$)>, C<put($$$)>, C<file($)> -- so several in one list are
written with parentheses: C<< run( a => 'x' ), run( b => 'y' ) >>.

=head2 The suite

=over 4

=item C<suite ID =E<gt> sub { ... }>

The suite; C<id>. Returns the loaded L<Langertha::Holmgang::Suite>.

=item C<title>, C<description>, C<version>, C<topic>, C<license>, C<repeat>

The format 2 key of the same name, once each. C<title> and C<source> are
also case keywords: they belong to the innermost open block.

=item C<threshold pass_rate =E<gt> ..., pass_k =E<gt> ...>

=item C<source title =E<gt> ..., authors =E<gt> ..., license =E<gt> ..., url =E<gt> ..., location =E<gt> ...>

=item C<system_prompt TEXT>

C<defaults.system> in a suite, C<system> in a case.

=item C<settings temperature =E<gt> ..., max_tokens =E<gt> ..., max_turns =E<gt> ...>

C<defaults.*> in a suite, the case keys in a case; each key once.

=item C<tool NAME =E<gt> ( description =E<gt> ..., parameters =E<gt> {...}, simulator =E<gt> ... | handlers =E<gt> [...] )>

One entry of C<tools>. C<parameters> is the JSON Schema subset of
L<Langertha::Holmgang::ToolSchema>, as data (type lists and C<const>
included).

=item C<handler match =E<gt> ..., when =E<gt> [...], apply =E<gt> [...], output =E<gt> ..., error =E<gt> 1>

Constructor of one handler. The C<apply> operations (C<set>, C<push>,
C<delete> ...) stay data hashes: C<push> and C<delete> are Perl builtins.

=item C<case ID =E<gt> sub { ... }>

One case, in a suite or a C<generate> block.

=item C<generate seed =E<gt> N, sub { my ( $rng ) = @_; ... }>

Runs its block once, while the suite is built, with a
L<Langertha::Holmgang::Random> seeded with C<N>: the same seed gives the same
cases on every perl and platform. The block declares ordinary C<case>s;
nothing about the seed reaches the structure. Never use C<rand> or C<srand>
in it, and never let the order of C<keys %hash> pick a case. The loader can
replace the seed per suite id (L<Langertha::Holmgang::Loader/seeds>; on the
command line C<--seed ID=N>), so a private measurement seed never has to be
written into a public file.

=back

=head2 The case

=over 4

=item C<title>, C<difficulty>, C<weight>

The case key of the same name, once each (C<difficulty>: C<leicht>,
C<mittel>, C<schwer>; C<weight>: a positive number).

=item C<tags LIST>

Appends to C<tags>.

=item C<tier '48k'>

The length tier: the tag C<stufe-48k>; one per case.

=item C<ask CONTENT, untrusted =E<gt> 1, images =E<gt> [ ... ]>

=item C<message ROLE =E<gt> CONTENT, untrusted =E<gt> 1, images =E<gt> [ ... ]>

A message (C<ask>: C<role: user>). C<CONTENT> is a text, a
C<< { generate => ... } >> spec (L</haystack>), an L</excerpt> or a list of
parts. C<images>
(only on a user message) lists file names relative to the suite directory, or
L</image> entries; a plain file name C<'img/a.png'> is C<< { file => 'img/a.png' } >>.

=item C<image FILE, untrusted =E<gt> 1>

Constructor of one image entry, C<< { file, untrusted } >>.

=item C<device NAME =E<gt> TYPE =E<gt> { ... }>

C<state.NAME> with C<type: TYPE>; the type is checked against the simulator
registry when the suite closes, so a plugin only has to be registered by then.

=item C<world NAME =E<gt> VALUE>

C<state.NAME> without a type (handler worlds).

=item C<observe match =E<gt> { ... }, when =E<gt> [ ... ], output =E<gt> ..., error =E<gt> 1>

One entry of C<observe>.

=item C<rule TITLE =E<gt> KIND>

One rule. C<KIND> is one of the rule constructors, each C<KIND VALUE, %rest>
with the format 2 pairs of that kind and C<< required => 0 >>:
C<at PATH, %expectations> (the rule kind C<state>; C<state> is a Perl
feature keyword), C<unchanged_except [PATHS]>, C<calls [CALLS]>,
C<not_called CALL>, C<only_tools [NAMES]>,
C<check { host, command }, expect =E<gt> { ... }>,
C<packet { ... }, verdict =E<gt> ...> and C<login { ... }, result =E<gt> ...>.
Expectations are pair keys (C<equals>, C<tolerance>, C<in>, C<regex>,
C<any>, C<before> ...); a C<regex> may be a C<qr//>, stored as its string
form.

=item C<solution CALLS>

The reference solution; C<solution()> is C<[]>, the "no tool" family.

=item C<alternative TITLE =E<gt> CALLS>, C<wrong TITLE =E<gt> CALLS>

One entry of C<alternatives>, of C<wrong_solutions>.

=back

=head2 Calls and contents

=over 4

=item C<call TOOL =E<gt> { ARGS }>

A call, C<< { tool, args } >>. In C<calls> and C<not_called> the arguments
are patterns, as in format 2. A parameter of C<type: boolean> takes a
boolean (C<JSON::PP::true>), not C<1>.

=item C<run HOST =E<gt> COMMAND>, C<put HOST =E<gt> PATH =E<gt> CONTENT>

A call of the suite's one tool with C<simulator: run_command> (C<write_file>);
resolved when the suite closes, which dies unless exactly one such tool
exists.

=item C<excerpt 'quellen/NAME.txt', from =E<gt> LABEL, to =E<gt> LABEL>

A message part with the provisions C<from> to C<to> (such as C<'§ 305'>,
C<'Artikel 28'>) of a statute text under F<quellen/> of the suite directory:
the format 2 part C<< { auszug => { datei, von, bis } } >>
(L<Langertha::Holmgang::Excerpt>), set in when the suite closes. Use it alone
or in a list of parts: C<< ask [ "The statute:\n\n", excerpt( ... ), "\n\nThe contract: ..." ] >>.
The YAML export writes the part as it is and copies the fixture.

=item C<file 'NAME'>

The text of a file, relative to the suite file's directory.

=item C<haystack kind =E<gt> ..., tokens =E<gt> ..., seed =E<gt> ..., insert =E<gt> [ ... ], exclude =E<gt> [ ... ]>

Generated long content, C<< { generate => { ... } } >>
(L<Langertha::Holmgang::Haystack>); its keys are checked when the suite
closes.

=back

=head2 Names that collide

C<state> (a feature keyword) is C<at> for a rule and C<device>/C<world> for
the world; C<system> is C<system_prompt>; C<write> is C<put>. C<version>
shadows the core package in the suite file: write C<version::-E<gt>parse>
there if needed. L<Test2::V0> exports C<call> and C<check>, L<Path::Class>
C<file>: rename on import (above).

=head1 EXAMPLE SUITES

Six small, invented suites to learn from ship in the distribution's share
directory (ADR 0010): C<demo-linux> (a Linux device), C<demo-lamp> (a world
without devices, its tool described by handlers), C<demo-haystack> (generated
input), C<demo-sehen> (an image on a user message, handed in through the
answer world C<sehen>), C<demo-roost> (a typed answer world plugin, an
invented dragon roost) -- all five in format 2 -- and C<demo-beacons>, a
F<suite.pl> in the case DSL whose three cases a C<generate> block builds from
a seed (an invented chain of hill beacons). In a checkout they are under
F<share/suites>; after installation under

  perl -MFile::ShareDir=dist_dir -E 'say dist_dir("Langertha-Holmgang")."/suites"'

  holmgang lint "$(perl -MFile::ShareDir=dist_dir -E 'say dist_dir("Langertha-Holmgang")')/suites"

Details in L<Langertha::Holmgang::Loader/Example suites>.

=head1 HOW IT FITS TOGETHER

=over 4

=item 1. B<Load.> L<Langertha::Holmgang::Loader> reads a suite directory in
format 2 (the format: L<Langertha::Holmgang::Loader/SUITE FORMAT 2>),
checks every file's shape (L<Langertha::Holmgang::Structure>) and lints every
case (L<Langertha::Holmgang::Lint>). The result is a
L<Langertha::Holmgang::Suite> with its L<Langertha::Holmgang::Case>s. A case
that fails lint does not load.

=item 2. B<Simulate.> Each case starts a fresh L<Langertha::Holmgang::World>
from its initial state. A tool call goes to the case's observations, then to
the simulator of the device's type (L<Langertha::Holmgang::Simulators>,
plugins composing L<Langertha::Holmgang::Role::Simulator> or
L<Langertha::Holmgang::Role::AnswerWorld>), or to the tool's handlers.
Simulators touch only their state: no shell-out, no socket, no host file.

=item 3. B<Run.> L<Langertha::Holmgang::Runner> plays the case against a
L<Langertha::Holmgang::Target> — a Langertha engine plus variant settings —
turn by turn until the model answers without a tool call, C<max_turns> is
reached, or the target fails. The model sees only the system prompt, the
messages and the tool schemas; never the state, the observations, the rules,
the solutions or the C<untrusted> marks.

=item 4. B<Grade.> L<Langertha::Holmgang::Grader> checks the rules at the
end state and on the calls (L<Langertha::Holmgang::Grader/RULES>) and gives
each repetition one status (L<Langertha::Holmgang::Grader/STATUSES>):
C<passed>, C<failed>, C<uncertain>, C<turn_limit>, C<error>,
C<context_exceeded> or C<no_vision>.

=item 5. B<Report.> L<Langertha::Holmgang::Report> writes what was measured
as one JSON document; L<Langertha::Holmgang::Evaluation> derives rates per
topic, weights, curves per length tier, verdicts per suite and the comparison
of targets from one or more reports.

=back

The command line ties these together: L<holmgang>
(L<Langertha::Holmgang::CLI>).

=head1 SEE ALSO

=over 4

=item * L<holmgang> — the command line

=item * L<Langertha::Holmgang::Loader> — suite format 2

=item * L<Langertha::Holmgang::Grader> — rules and statuses

=item * L<Langertha::Holmgang::Role::Simulator> — writing a simulator

=item * L<Langertha::Holmgang::Runner> — the model loop

=item * L<Langertha::Holmgang::Report>, L<Langertha::Holmgang::Evaluation> — results

=item * L<Langertha>

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
