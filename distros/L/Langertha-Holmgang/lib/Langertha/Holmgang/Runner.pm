package Langertha::Holmgang::Runner;
# ABSTRACT: The model loop of one case over a Langertha engine: turns, turn limit, tokens per turn, lint mock runs

use Moose;
use namespace::autoclean;
use utf8;

use Carp qw( croak );
use Future::AsyncAwait;
use JSON::MaybeXS ();
use Langertha::Engine::Virtual;
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::Target;
use Langertha::Virtual::Rules qw( answer tool );
use Moose::Util ();
use Scalar::Util qw( blessed );
use Time::HiRes ();

our $VERSION = '0.001';

my $JSON = JSON::MaybeXS->new( utf8 => 0, canonical => 1, allow_nonref => 1 );


has target => (
  is        => 'ro',
  isa       => 'Langertha::Holmgang::Target',
  predicate => 'has_target',
);


has grader => (
  is      => 'ro',
  lazy    => 1,
  builder => '_build_grader',
);
sub _build_grader { Langertha::Holmgang::Grader->new }


sub _ms { int( 1000 * $_[0] + 0.5 ) }

# a deep copy as plain data (wire bodies may carry JSON booleans and shared refs)
sub _plain { $JSON->decode( $JSON->encode( $_[0] ) ) }

async sub run_case_f {
  my ( $self, $case, %o ) = @_;
  croak __PACKAGE__.'->run_case needs a target' unless $self->has_target;
  my $target = $self->target;
  my $engine = $target->engine;
  croak __PACKAGE__.': the engine '.ref($engine).' has no format_tool_results (Langertha::Role::Tools)'
    unless $engine->can('format_tool_results');
  # Langertha prepends an engine's own system_prompt as a second system message (k37)
  croak __PACKAGE__.': the engine '.ref($engine).' has a system_prompt of its own; the case\'s system prompt is the only one'
    if $engine->can('system_prompt') && defined $engine->system_prompt;

  my $world = $self->grader->world_class->new(
    state      => $case->initial_state,
    tools      => $case->tools,
    observe    => $case->observe // [],
    simulators => $self->grader->simulators,
  );
  my $offer  = $world->offer;
  my $system = $case->effective('system');
  my @conversation = (
    ( defined $system && length $system ? ( { role => 'system', content => $system } ) : () ),
    @{ _plain( $case->prompt_messages ) },
  );
  my %controls = ( max_tokens => $case->effective('max_tokens') );
  $controls{temperature} = $case->effective('temperature')
    if !$engine->can('supports') || $engine->supports('temperature');
  $controls{seed} = 0 + $o{seed} if defined $o{seed};
  $controls{tools} = $offer if @$offer;

  my $max_turns = $case->effective('max_turns');
  my ( @turns, @calls, $error, $error_class, $turn_limit, $answer );
  # the vision pre-check found the target blind (k27): no request for a case with images
  if ( $case->has_images && defined $o{no_vision} ) {
    ( $error, $error_class ) = ( $o{no_vision}, 'no_vision' );
  }
  while ( !defined $error_class ) {
    if ( @turns >= $max_turns ) {
      $turn_limit = 1;
      last;
    }
    my $t0   = Time::HiRes::time();
    my $turn = await $target->chat_turn_f( messages => $self->_wire_messages( $case, \@conversation ), %controls );
    my $ms   = _ms( Time::HiRes::time() - $t0 );
    my $response = $turn->{response};
    my $usage    = $response && $response->has_usage ? $response->usage : undef;
    my @tc = $response && $response->has_tool_calls ? @{ $response->tool_calls } : ();
    push @turns, {
      input_tokens     => $usage ? $usage->input_tokens     : undef,
      output_tokens    => $usage ? $usage->output_tokens    : undef,
      reasoning_tokens => $usage ? $usage->reasoning_tokens : undef,
      duration_ms      => $ms,
      finish_reason    => $response ? $response->finish_reason : undef,
      calls            => scalar @tc,
    };
    if ( defined $turn->{error_class} ) {
      ( $error, $error_class ) = @{$turn}{qw( error error_class )};
      last;
    }
    unless ( @tc ) {
      # without a tool call the case is over; the text is never graded
      $answer = $response->content // '';
      push @conversation, { role => 'assistant', content => $answer };
      last;
    }
    my @results;
    for my $tc ( @tc ) {
      my ( $out, $args, $ok, $gap ) = $world->call( $tc->name, $self->_call_arguments($tc) );
      push @calls, { tool => $tc->name, args => _plain($args), succeeded => $ok ? 1 : 0, sim_gap => $gap };
      push @results, { tool_call => $tc, result => { content => [ { type => 'text', text => $out // '' } ] } };
    }
    push @conversation, @{ _plain( [ $engine->format_tool_results( $response->raw, \@results ) ] ) };
  }

  my $g = $self->grader->grade( $case, {
    state => $world->state,
    calls => \@calls,
    ( defined $error ? ( error => $error, error_class => $error_class ) : () ),
    ( $turn_limit ? ( turn_limit => 1 ) : () ),
  } );
  return {
    case_id         => $case->id,
    repetition      => $o{repetition} // 1,
    seed            => defined $o{seed} ? 0 + $o{seed} : undef,
    ( map { $_ => $g->{$_} } qw( status score error rules diff sim_gaps forbidden_calls injection_held ) ),
    turns           => \@turns,
    calls           => \@calls,
    transcript      => [ grep { ( $_->{role} // '' ) ne 'system' } @conversation ],
    answer          => $answer,
    state           => $world->state,
  };
}


# the conversation as it goes out: each image placeholder { image, sha256, bytes }
# of a message becomes the case's Langertha::Content::Image, which the engine
# turns into its own image part; the conversation itself keeps the placeholder
sub _wire_messages {
  my ( $self, $case, $conversation ) = @_;
  return [ map {
    my $m = $_;
    my $images = ref $m->{content} eq 'ARRAY' && grep { ref $_ eq 'HASH' && exists $_->{image} } @{ $m->{content} };
    $images
      ? +{ %$m, content => [ map { ref $_ eq 'HASH' && exists $_->{image} ? $case->image_content( $_->{image} ) : $_ } @{ $m->{content} } ] }
      : $m;
  } @$conversation ];
}

sub run_case {
  my ( $self, @args ) = @_;
  return $self->run_case_f(@args)->get;
}

# what the world gets for a call: the decoded hash; for arguments that did not
# decode (Langertha keeps no raw text, only {} and the flag) a text that is no
# JSON object, so the world answers with its own refusal, as cai-platform's did
# for the model's raw string
sub _call_arguments {
  my ( $self, $tc ) = @_;
  return $tc->arguments_undecodable ? '{' : $tc->arguments;
}

#### Lint's mock runs

sub mock_engine {
  my ( $class, $case, $mode ) = @_;
  $mode //= 'solution';
  croak __PACKAGE__.'->mock_engine: mode is solution or text' unless $mode eq 'solution' || $mode eq 'text';
  my @script = $mode eq 'solution'
    ? ( ( map { tool( $_->{tool} => _plain( $_->{args} // {} ) ) } @{ $case->solution || [] } ), answer('Done.') )
    : ( answer('I would do it like this ... (text only)') );
  # the mock sees what it is sent: a case with images gets a mock that claims
  # image_input, so the vision pre-check does not stop it at the wire, and
  # answers the sight test's requests once its script is done (k27) -- a case
  # ends with the script's last answer, so a case never reaches the fallback
  my $images = $case->has_images;
  my $engine = Langertha::Engine::Virtual->new( script => \@script, ( $images ? ( fallback => answer('OK') ) : () ) );
  Moose::Util::apply_all_roles( $engine, 'Langertha::Role::ImageInput' ) if $images;
  return $engine;
}


# the parts of two results that must be identical (all but wall time)
sub _comparable {
  my ( $r ) = @_;
  my %c = map { $_ => $r->{$_} } qw( status score error rules diff calls sim_gaps forbidden_calls injection_held transcript state );
  $c{turns} = [ map { my %t = %$_; delete $t{duration_ms}; \%t } @{ $r->{turns} } ];
  return $JSON->encode( \%c );
}

sub lint_mock_runs {
  my ( $class ) = @_;
  return sub {
    my ( $lint, $case, $field ) = @_;
    my $run = sub {
      my ( $mode ) = @_;
      my $runner = $class->new(
        grader => $lint->grader,
        target => Langertha::Holmgang::Target->new( engine => $class->mock_engine( $case, $mode ) ),
      );
      return $runner->run_case($case);
    };
    my $refuse = sub { Langertha::Holmgang::Error->throw( $field.': '.$_[0], $_[1] ) };

    my @replay = map { $run->('solution') } 1 .. 2;
    $refuse->( 'solution', 'mock run replaying the reference solution is '.$replay[0]{status}
      .( defined $replay[0]{error} ? ': '.$replay[0]{error} : '' ) )
      unless $replay[0]{status} eq 'passed';
    $refuse->( 'solution', 'mock run replaying the reference solution gives a different result the second time' )
      unless _comparable( $replay[0] ) eq _comparable( $replay[1] );

    my $text = $run->('text');
    if ( $case->no_tool ) {
      $refuse->( 'solution', 'mock run answering text only is '.$text->{status}.' -- in the "no tool" family it must pass' )
        unless $text->{status} eq 'passed';
    }
    else {
      $refuse->( 'rules', 'mock run answering text only passes -- the rules check no change' )
        if $text->{status} eq 'passed';
    }
    return;
  };
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Runner - The model loop of one case over a Langertha engine: turns, turn limit, tokens per turn, lint mock runs

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Langertha::Holmgang::Runner;
  use Langertha::Holmgang::Target;
  use Langertha::Engine::vLLM;

  # any Langertha engine; the key, where one is needed, comes from the engine's environment variable
  my $engine = Langertha::Engine::vLLM->new( url => 'http://10.0.0.5:8000/v1', model => 'some-model' );

  # or, without a network: the mock model that replays the case's reference solution
  my $engine = Langertha::Holmgang::Runner->mock_engine( $case, 'solution' );

  my $runner = Langertha::Holmgang::Runner->new(
    target => Langertha::Holmgang::Target->new( engine => $engine, variant => { max_tokens => 4000 } ),
  );

  my $result = $runner->run_case( $case, repetition => 1, seed => 1 );
  $result->{status};          # passed failed uncertain turn_limit error context_exceeded no_vision
  $result->{turns};           # [ { input_tokens, output_tokens, reasoning_tokens, duration_ms, finish_reason, calls } ]

  my $result = await $runner->run_case_f($case);    # the same, as a Future

  # the results go straight into a report (ADR 0006)
  $report->add_run( %run, cases => \@case_meta, results => [ $result, … ] );

  # lint's two mock runs, for Langertha::Holmgang::Lint->new( mock_runs => … )
  my $lint = Langertha::Holmgang::Lint->new(
    mock_runs => Langertha::Holmgang::Runner->lint_mock_runs,
  );

=head1 DESCRIPTION

The runner plays one case against a model (cai-platform C<Eval::Runner::run_case>,
here over Langertha instead of C<ModelTester>). Per case: a fresh
L<Langertha::Holmgang::World> from the case's initial state, then turns
against the L</target>. A turn sends the system prompt, the conversation and
the suite's tool schemas through L<Langertha::Holmgang::Target/chat_turn_f>;
every tool call of the answer runs in the world and its output goes back as a
tool result in the engine's own wire format
(L<Langertha::Role::Tools/format_tool_results>), so any engine with native or
Hermes tool calling works. The case ends when the model answers without a
tool call, after C<max_turns> model calls (status C<turn_limit>), or when the
target does not answer (C<error>, C<context_exceeded> or C<no_vision>, as the
target classifies the failure). Only the end state and the calls are graded
(L<Langertha::Holmgang::Grader>), never the text.

B<What goes out> is the system prompt (the case's effective C<system>), the
case's L<Langertha::Holmgang::Case/prompt_messages> (C<role> and C<content>
only, no C<untrusted> mark; each image placeholder replaced by the image
itself, L<Langertha::Holmgang::Case/image_content>, only in the request -- the
transcript keeps the placeholder), the assistant turns and tool outputs, and the
tool schemas as L<Langertha::Holmgang::World/offer> gives them (C<name>,
C<description>, C<parameters>). Never the state, the observations, the rules,
the solutions or the marks. An engine with a C<system_prompt> of its own is
refused before the first request: Langertha would send it as a second system
message ahead of the case's, and the model would see what the case does not
say.

Request controls per turn: C<max_tokens> (effective value of the case), C<seed>
when given, and C<temperature> (effective value) only when the engine takes
one (C<< supports('temperature') >>) -- Langertha would drop it with a warning
otherwise. The target's variant settings win over both
(L<Langertha::Holmgang::Target/variant>).

=head2 target

The L<Langertha::Holmgang::Target> the turns go to. Required for
L</run_case>; L</lint_mock_runs> builds its own.

=head2 grader

The L<Langertha::Holmgang::Grader> that grades the end state; its simulator
registry also runs the world's calls.

=head2 run_case_f

  my $result = await $runner->run_case_f( $case, repetition => 2, seed => 2 );

Plays one L<Langertha::Holmgang::Case> (see L</DESCRIPTION>). C<seed>
(integer, optional) goes unchanged into every request of the case;
C<repetition> (default 1) is only carried into the result. C<no_vision>
(optional) is the reason the vision pre-check of the suite gave
(L<Langertha::Holmgang::Target/vision_check_f>): a case with images then ends
C<no_vision> with that text as its error, without a request and without a
turn; a case without images ignores it. Returns a
L<Future> of the B<result>, the per-repetition shape
L<Langertha::Holmgang::Report/add_run> takes (ADR 0006), plain data:

=over

=item * C<case_id>, C<repetition>, C<seed>

=item * C<status>, C<score>, C<error>, C<rules>, C<diff>, C<sim_gaps>,
C<forbidden_calls>, C<injection_held> -- from
L<Langertha::Holmgang::Grader/grade>. C<error> is the target's error text
when it did not answer, scrubbed (L<Langertha::Holmgang::Target/scrub>),
C<undef> otherwise (a turn limit has none). A failed request ends the case:
its text never goes back to the model.

=item * C<turns> -- one entry per model call that reached the target, the
failed one included: C<input_tokens>, C<output_tokens>, C<reasoning_tokens>
(from L<Langertha::Usage>, C<undef> when the target sent none),
C<duration_ms> (wall time of the call), C<finish_reason>, C<calls> (tool
calls of the turn).

=item * C<calls> -- every tool call in order: C<tool>, C<args> (decoded),
C<succeeded>, C<sim_gap>.

=item * C<transcript> -- the conversation without the system prompt, in the
engine's wire format, ending with the final assistant text.

=item * C<answer> -- the last text of the model (raw, only to look at), and
C<state> -- the end state. Neither goes into a report.

=back

=head2 run_case

  my $result = $runner->run_case( $case, %options );

L</run_case_f>, waited for.

=head2 mock_engine

  my $engine = Langertha::Holmgang::Runner->mock_engine( $case, 'solution' );   # or 'text'

A L<Langertha::Engine::Virtual> as the mock model of the lint (and of dry
runs): C<solution> calls the reference solution, one call per turn, then
answers C<Done.>; C<text> answers with text only, at once. For a case with
images it claims C<image_input> (L<Langertha::Role::ImageInput>), answers
C<OK> once its script is done (which a case never reaches) and reports no
token usage, so L<Langertha::Holmgang::Target/vision_check_f> lets it through
unmeasured. It replaces
cai-platform's C<Eval::FakeTarget> (ADR 0005); unlike that one it estimates
no tokens and emulates no context window (the target's error path is tested
with L<Langertha::Virtual::Rules/error> reactions instead).

=head2 lint_mock_runs

  my $lint = Langertha::Holmgang::Lint->new( mock_runs => Langertha::Holmgang::Runner->lint_mock_runs );

The code reference for L<Langertha::Holmgang::Lint/mock_runs>: the two mock
runs of the lint (cai-platform C<docs/entwurf-evals.md> §3.5), each a real
L</run_case> over a L</mock_engine>, graded with the lint's grader.

=over

=item * Replaying the reference solution B<passes, twice identically> --
status, score, rules, diff, calls, gaps, transcript, end state and the turns
without their wall time.

=item * Answering B<text only fails> -- except in the "no tool" family
(C<solution: []>), where it must pass.

=back

A run that does not hold throws a L<Langertha::Holmgang::Error> on the field
C<solution> or C<rules>; the case does not load.

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
