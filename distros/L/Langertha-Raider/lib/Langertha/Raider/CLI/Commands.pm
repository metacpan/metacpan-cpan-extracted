package Langertha::Raider::CLI::Commands;
# ABSTRACT: Internal slash commands of the raider REPL
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use utf8;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::CLI::PromptBuilder;
use Langertha::Raider::Skill;


has app => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI',
  required => 1,
);

has output => (
  is       => 'ro',
  isa      => 'Langertha::Raider::CLI::Output',
  required => 1,
);

has in => (
  is      => 'ro',
  default => sub { \*STDIN },
);

sub prompt_builder_class { 'Langertha::Raider::CLI::PromptBuilder' }
sub skill_class          { 'Langertha::Raider::Skill' }


sub dispatch {
  my ( $self, $line, %o ) = @_;
  my $r = $self->resolve($line);
  return { prompt => $line } if $r->{kind} eq 'prompt';
  if ( $r->{kind} eq 'entry' ) {
    my $request = $self->app->slash_run_request( $r->{entry}, $r->{arguments}, session => $o{session} );
    if ( defined $request->{error} ) {
      $self->output->say_error($request->{error});
      return 0;
    }
    return $request;
  }
  if ( $r->{kind} eq 'mcp_prompt' ) {
    my $request = $self->app->mcp_prompt_request( $r->{name}, $r->{arguments} );
    unless ($request) {
      $self->output->say_error('unknown command: /'.$r->{name}.' (try /help)');
      return 0;
    }
    if ( defined $request->{error} ) {
      $self->output->say_error($request->{error});
      return 0;
    }
    return $request;
  }
  if ( $r->{kind} eq 'unknown' ) {
    $self->output->say_error('unknown command: /'.$r->{name}.' (try /help)');
    $self->output->say_error('skills and custom commands not read: '.$r->{catalog_error})
      if defined $r->{catalog_error};
    return 0;
  }
  my $method = $r->{method};
  my $result;
  # A built-in that dies (a context that cannot be read) is reported; the REPL goes on.
  unless ( eval { $result = $self->$method( join ' ', split ' ', $r->{arguments} // '' ); 1 } ) {
    $self->output->say_error( '/'.$r->{name}.': '.$self->output->error_text($@) );
    return 0;
  }
  return ref $result eq 'HASH' && defined $result->{prompt} ? $result : 1;
}


sub resolve {
  my ( $self, $line ) = @_;
  my ( $name, $rest ) = $line =~ m{\A\s*/(\S*)\s*(.*?)\s*\z}s;
  $name //= '';
  my %r = ( name => $name, arguments => length( $rest // '' ) ? $rest : undef );
  return { %r, kind => 'prompt' } if $name =~ m{/};
  # A context that cannot be read (a broken config file) has no entries;
  # the built-ins still work and report it.
  if ( length $name ) {
    my $entry = eval { $self->app->context->skill_catalog->find_user_invocable($name) };
    return { %r, kind => 'entry', entry => $entry } if $entry;
    $r{catalog_error} = $self->output->error_text($@) if $@;
  }
  # mcp__SERVER__PROMPT: the prompt of a configured MCP server (ADR 0029 Addendum 1).
  return { %r, kind => 'mcp_prompt' } if $name =~ /\Amcp__.+?__.+\z/s;
  my $method = $self->command_method($name);
  return $method ? { %r, kind => 'builtin', method => $method } : { %r, kind => 'unknown' };
}


sub command_method {
  my ( $self, $name ) = @_;
  return unless defined $name && $name =~ /\A[a-z][a-z0-9-]*\z/;
  my $method = 'cmd_'.( $name =~ tr/-/_/r );
  return $self->can($method) ? $method : ();
}

sub cmd_help {
  my ($self) = @_;
  my $out = $self->output;
  $out->say_meta($_) for (
    'commands:',
    '  /help                 show this help',
    '  /clear /reset /new    reset conversation history',
    '  /compact [TEXT]       summarise the history now (TEXT: what the summary should keep)',
    '  /context              show the context by part with estimated tokens',
    '  /memory [N]           list the instruction files; /memory N edits one in $EDITOR',
    '  /skills               list the skills and custom commands with their sources',
    '  /agents               list the agents the agent tool can start',
    '  /hooks                list the configured hooks by event',
    '  /init                 let the model write or improve the instructions file',
    '  /metrics              show cumulative raid metrics',
    '  /stats                show token usage per model (cache included)',
    '  /reload               reload instructions, memory, settings and skills; re-detect packs',
    '  /prompt               launch the prompt-builder (edits the instructions file)',
    '  /skill [PATH]         export plain-markdown skill doc',
    '  /skill-claude [PATH]  export Claude Code SKILL.md with frontmatter',
    '  /config               show each setting and where it came from',
    '  /permissions          show the permission mode, rules and session rules',
    '  /permissions mode M   switch the mode: default, acceptEdits, auto, plan, bypassPermissions',
    '  /mcp                  show the configured MCP servers, their status and tools',
    '  /mcp reconnect [NAME] restart one MCP server (or all)',
    '  /model [NAME]         set+save model to the config file',
    '  /model list [FILTER]  list available models (optionally filtered)',
    '  /packs                list all available packs and their state',
    '  /pack on NAME         enable a pack (toggle on)',
    '  /pack off NAME        disable a pack',
    '  /pack NAME            toggle pack on/off',
    '  !CMD                  run CMD in the shell (not sent to the model)',
    '  ?CMD                  run CMD, then send it and its output to the model',
    '  /quit /exit :q        leave the REPL',
  );
  my @prompts = @{ $self->app->mcp_prompts };
  if (@prompts) {
    $out->say_meta('MCP prompts:');
    for my $p (@prompts) {
      my $call = '/'.$p->{command}.join('', map { ' '.( $_->{required} ? $_->{name} : '['.$_->{name}.']' ) } @{ $p->{arguments} });
      my $desc = length $p->{description} ? $p->{description}.' ' : '';
      $out->say_meta(sprintf('  %-21s %s(MCP, %s)', $call, $desc, $p->{server}));
    }
  }
  my @entries = sort { $a->{name} cmp $b->{name} } $self->app->context->skill_catalog->user_invocable;
  return unless @entries;
  $out->say_meta('skills and custom commands:');
  for my $e (@entries) {
    my $call = '/'.$e->{name};
    my $hint = $self->_argument_hint($e);
    $call .= ' '.$hint if length $hint;
    my $desc = length $e->{description} ? $e->{description}.' ' : '';
    $out->say_meta(sprintf('  %-21s %s(%s)', $call, $desc, $e->{source}));
  }
  return;
}

# The argument-hint of a catalogue entry as written: YAML reads
# "argument-hint: [message]" as a list, which is shown in its brackets again.
sub _argument_hint {
  my ( $self, $entry ) = @_;
  my $hint = $entry->{frontmatter}{'argument-hint'};
  return '' unless defined $hint;
  return '['.join(', ', grep { defined && !ref } @$hint).']' if ref $hint eq 'ARRAY';
  return ref $hint ? '' : $hint;
}

sub cmd_reset { shift->cmd_clear(@_) }
sub cmd_new   { shift->cmd_clear(@_) }

sub cmd_clear {
  my ($self) = @_;
  my $app = $self->app;
  $app->raider->clear_history;
  $app->note_history_cleared;
  my $t = $app->trace_plugin;
  $t->token_stats({ prompt => 0, completion => 0, total => 0, calls => 0 }) if $t;
  $self->output->say_meta('history cleared.');
  $self->output->say_meta($_) for $app->take_meta_notes;
  return;
}

sub cmd_metrics {
  my ($self) = @_;
  my $m = $self->app->raider->metrics;
  $self->output->say_meta(sprintf(
    'raids=%d iterations=%d tool_calls=%d time_ms=%d',
    $m->{raids}, $m->{iterations}, $m->{tool_calls}, $m->{time_ms},
  ));
  return;
}

sub cmd_stats {
  my ($self) = @_;
  my $u = $self->app->usage_stats;
  return $self->output->say_meta('no model calls yet.') unless $u->{calls};
  my $out = $self->output;
  $out->say_meta($self->_usage_line('total', $u));
  my $models = $u->{models};
  $out->say_meta($self->_usage_line('  '.$_, $models->{$_})) for sort keys %$models;
  return;
}

# "NAME: 1200 in / 80 out (cache 1000 read, 0 written) | 3 calls" (ADR 0026).
sub _usage_line {
  my ( $self, $name, $u ) = @_;
  return sprintf('%s: %d in / %d out (cache %d read, %d written) | %d calls',
    $name, @$u{qw( input_tokens output_tokens cache_read_tokens cache_write_tokens calls )});
}

sub cmd_reload {
  my ($self) = @_;
  my $app = $self->app;
  my $context = $app->reload_context;
  my @detected = $app->redetect_packs;
  my $new = $app->reload_mission;
  my $source = $app->mission_source;
  my $file   = $app->instructions->label;
  my $status = $source eq '-M'  ? '-M mission kept, '.$file.' not used'
             : $source eq q(claude base) ? q(Claude Code base text (no persona))
             : $source eq $file ? 'custom ('.$file.' loaded)'
             :                    'Langertha (default, no '.$file.')';
  $self->output->say_meta('mission reloaded: '.$status.' ('.length($new).' chars)');
  $self->output->say_meta('detected packs: '.join(', ', @detected)) if @detected;
  return unless $context->claude_layout;
  my @memory = $context->instruction_items;
  my @skills = $context->skill_catalog->listed;
  $self->output->say_meta('context reloaded: layout '.$context->mode.', '
    .scalar(@memory).' instruction file'.( @memory == 1 ? '' : 's').', '
    .scalar(@skills).' listed skill'.( @skills == 1 ? '' : 's'));
  return;
}

sub cmd_permissions {
  my ($self, $arg) = @_;
  my $app = $self->app;
  my $out = $self->output;
  $arg //= '';
  if ($arg =~ /\Amode(?:\s+(\S+))?\s*\z/) {
    my $mode = $1;
    my @modes = $app->permissions_class->modes;
    return $out->say_error('usage: /permissions mode MODE ('.join(', ', @modes).')')
      unless defined $mode && $app->permissions_class->is_mode($mode);
    my $from = $app->set_permission_mode($mode, '/permissions');
    $out->say_meta('permission mode: '.$from.' -> '.$mode);
    return;
  }
  return $out->say_error('usage: /permissions [mode MODE]') if length $arg;
  $out->permissions_report($app->permissions->report, rules => 1);
  return;
}

sub cmd_prompt {
  my ($self) = @_;
  $self->prompt_builder_class->new(app => $self->app, output => $self->output, in => $self->in)->run;
  return;
}


sub cmd_mcp {
  my ( $self, $arg ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  $arg //= '';
  if ($arg =~ /\Areconnect(?:\s+(\S+))?\s*\z/) {
    my $name = $1;
    my @done = $app->reconnect_mcp($name);
    return $out->say_error('no configured MCP server '.$name.' that can start (see /mcp)') unless @done || !defined $name || $name eq 'all';
    $out->say_meta('reconnected: '.( @done ? join(', ', @done) : 'nothing to reconnect' ));
  }
  elsif (length $arg) {
    return $out->say_error('usage: /mcp | /mcp reconnect [NAME|all]');
  }
  # Connected first (in parallel, each within MCP_TIMEOUT), so the report says
  # how they are, as claude mcp list checks them.
  $app->loop->await($app->configured_mcp->start_f);
  $out->mcp_report($app->mcp_report, tools => 1);
  return;
}

sub cmd_config {
  my ($self) = @_;
  my $report = eval { $self->app->explain_config };
  unless ($report) {
    my $err = $@; chomp $err;
    return $self->output->say_error($err);
  }
  $self->output->config_report($report);
  return;
}

sub cmd_skill {
  my ( $self, $arg ) = @_;
  my $path = $arg || path($self->app->root)->child('RAIDER-SKILL.md')->stringify;
  my $p = $self->skill_class->new(app => $self->app)->write_markdown($path);
  $self->output->say_meta('wrote '.$p);
  return;
}

sub cmd_skill_claude {
  my ( $self, $arg ) = @_;
  my $skill = $self->skill_class->new(app => $self->app);
  my $p = $skill->write_claude_skill(length $arg ? $arg : undef);
  $self->output->say_meta('wrote '.$p);
  if (my $old = $skill->legacy_claude_skill) {
    $self->output->say_meta('note: '.$old.' is left over from an older raider, remove it');
  }
  return;
}

sub cmd_model {
  my ( $self, $arg ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  my ( $subcmd, $filter ) = split /\s+/, $arg, 2;

  if (!length $arg || $subcmd eq 'list') {
    my $current = $app->has_model ? $app->model : '';
    if ($app->has_provider) {
      my $p = $app->provider;
      $out->emit($out->c(meta => 'provider:'), ' ', $out->c(title => ( defined $p->{alias} ? $p->{alias}.' ('.$p->{provider_id}.')' : $p->{provider_id} )), "\n");
    }
    $out->emit($out->c(meta => 'engine:  '), $out->c(title => $app->engine_name), "\n");
    $out->emit($out->c(meta => 'model:   '), $out->c(title => length $current ? $current : '(engine default)'), "\n");
    my $engine = eval { $app->_engine };
    return unless $engine && $engine->can('list_models');
    my $list = eval { $engine->list_models };
    if ($@) {
      my $err = $@; chomp $err;
      return $out->say_error('list_models failed: '.$err);
    }
    return unless @$list;
    my @filtered = length($filter // '')
      ? grep { index($_, $filter) >= 0 } @$list
      : @$list;
    my @rows  = $self->collapse_model_list(\@filtered, $current);
    my $total = scalar @rows;
    my $cap   = (defined $subcmd && $subcmd eq 'list') ? $total : 20;
    my @show  = @rows[0 .. ($cap < $total ? $cap - 1 : $total - 1)];
    $out->emit($out->c(meta => 'models'.(length($filter // '') ? ' (/'.$filter.'/)' : '').':'), "\n");
    for my $row (@show) {
      my $star  = $row->{current} ? $out->c(accent => '*') : ' ';
      my $n     = scalar @{ $row->{snaps} };
      my $snaps = $n ? $out->c(meta => '  [+'.$n.($n == 1 ? ' snapshot]' : ' snapshots]')) : '';
      $out->emit('  '.$star.' '.$out->c(title => $row->{id}).$snaps."\n");
    }
    $out->emit($out->c(meta => '    … '.$cap.' of '.$total.' shown — /model list [filter] for all'), "\n")
      if $cap < $total;
    return;
  }
  unless (eval { $app->config->set_model($arg); 1 }) {
    my $err = $@; chomp $err;
    return $out->say_error($err);
  }
  $out->emit($out->c(meta => 'model saved: '), $out->c(title => $arg),
    $out->c(meta => ' (takes effect on next start)'), "\n");
  return;
}


sub collapse_model_list {
  my ( $self, $list, $current ) = @_;
  my %groups;   # base => [snapshot variants]
  my %is_snap;  # id => 1

  for my $id (@$list) {
    if (my ($base) = ($id =~ /^(.+?)-\d{4}-\d{2}-\d{2}(?:-.+)?$/)) {
      push @{$groups{$base}}, $id;
      $is_snap{$id} = 1;
    }
    elsif (my ($base2) = ($id =~ /^(.+)-\d{4}$/)) {
      push @{$groups{$base2}}, $id;
      $is_snap{$id} = 1;
    }
  }

  my @rows;
  for my $id (sort @$list) {
    next if $is_snap{$id};
    my @snaps = sort @{$groups{$id} // []};
    push @rows, {
      id      => $id,
      snaps   => \@snaps,
      current => ($id eq $current || !!(grep { $_ eq $current } @snaps)),
    };
  }

  # orphaned snapshot families whose base isn't a standalone model
  my %seen = map { $_->{id} => 1 } @rows;
  for my $base (sort keys %groups) {
    next if $seen{$base};
    my @snaps = sort @{$groups{$base}};
    push @rows, {
      id      => $base,
      snaps   => \@snaps,
      orphan  => 1,
      current => !!(grep { $_ eq $current } @snaps),
    };
  }

  return sort { $a->{id} cmp $b->{id} } @rows;
}

sub cmd_packs {
  my ($self) = @_;
  my $out = $self->output;
  my $collection = $self->app->packs;
  my @all = @{$collection->all_pack_names};
  return $out->say_meta('no packs available.') unless @all;
  my %why = map { $_->{name} => $out->pack_reason($_) } @{$collection->activation_report};
  $out->say_meta('packs:');
  for my $name (sort @all) {
    my $info = $collection->pack_info($name);
    my $active = $info->{is_active} ? $out->c(accent => '*') : ' ';
    $out->emit('  '.$active.' '.$name.' ', $out->c(meta => '('.$info->{exclusive_group}.')'),
      ( length($why{$name} // '') ? ( ' ', $out->c(meta => $why{$name}) ) : () ), "\n");
  }
  for my $s (@{$collection->skipped_packs}) {
    $out->emit('  ', $out->c(warn => 'skipped pack '.$s->{name}.' ('.$s->{origin}.' '.$s->{path}.'): '.$s->{reason}), "\n");
  }
  return;
}

sub cmd_pack {
  my ( $self, $arg ) = @_;
  my $app = $self->app;
  my $out = $self->output;
  my $collection = $app->packs;
  my ( $subcmd, $name ) = split /\s+/, $arg, 2;
  $name   //= '';
  $subcmd //= '';
  my $usage = 'usage: /pack on NAME, /pack off NAME, or /pack NAME (toggle)';

  # /packs lists; a bare /pack is a usage error.
  return $out->say_error($usage) if !$name && ($subcmd eq '' || $subcmd eq 'list');

  if ($subcmd eq 'on') {
    $collection->enable($name);
    $app->reload_mission;
    return $out->say_meta('pack enabled: '.$name);
  }
  if ($subcmd eq 'off') {
    $collection->disable($name);
    $app->reload_mission;
    return $out->say_meta('pack disabled: '.$name);
  }

  # Toggle
  if ($subcmd eq '') {
    $subcmd = $name;
    $name = '';
  }
  if ($name eq '' && grep { $subcmd eq $_ } @{$collection->all_pack_names}) {
    # Direct /pack NAME (no subcmd)
    $name = $subcmd;
    $subcmd = '';
  }
  return $out->say_error($usage) if $name eq '';

  if ($subcmd eq '' || $subcmd eq 'toggle') {
    $collection->toggle($name);
    $app->reload_mission;
    my $now = $collection->is_active($name) ? 'enabled' : 'disabled';
    return $out->say_meta('pack '.$name.' '.$now.'.');
  }

  return $out->say_error('unknown /pack subcommand: '.$subcmd.' (try /help)');
}

#### /skills

sub cmd_skills {
  my ($self) = @_;
  my $out = $self->output;
  my $catalog = $self->app->context->skill_catalog;
  my @entries  = $catalog->skills;
  my @shadowed = $catalog->shadowed;
  my @problems = $catalog->problems;
  return $out->say_meta('no skills or custom commands.') unless @entries || @shadowed || @problems;
  $out->say_meta('skills and custom commands:') if @entries;
  for my $e (@entries) {
    my $line = '  '.$e->{name}.' ('.( $e->{kind} // 'skill' ).', '.$e->{source}.')'
      .' model: '.( $e->{model_invocable} ? 'yes' : 'no' )
      .', user: '.( $e->{user_invocable} ? 'yes' : 'no' );
    if (my @globs = $catalog->paths_of($e)) {
      $line .= ', paths: '.join(', ', @globs);
      $line .= ' (not active yet)' if $e->{model_invocable} && !$catalog->is_listed($e);
    }
    $out->say_meta($line);
  }
  if (@shadowed) {
    $out->say_meta('shadowed:');
    $out->say_meta('  '.$_->{name}.' ('.$_->{source}.') by '.$_->{by}) for @shadowed;
  }
  if (@problems) {
    $out->say_meta('problems:');
    $out->say_meta('  '.$_->{file}.': '.$_->{reason}) for @problems;
  }
  return;
}

#### /compact

sub cmd_compact {
  my ( $self, $arg ) = @_;
  my $out = $self->output;
  my $raider = $self->app->raider;
  my $count = scalar @{ $raider->history };
  return $out->say_meta('nothing to compact.') unless $count;
  my $summary;
  my $ok = eval {
    $summary = $raider->compress_history( defined $arg && $arg =~ /\S/ ? ( instructions => $arg ) : () );
    1;
  };
  unless ($ok) {
    my $err = $@; chomp $err;
    return $out->say_error('compact failed: '.$err);
  }
  $out->say_meta('history compacted ('.$count.' message'.( $count == 1 ? '' : 's' )
    .' → summary, ~'.$self->estimate_tokens($summary).' tokens)');
  return;
}

#### /context


sub estimate_tokens {
  my ( $self, $thing ) = @_;
  return 0 unless defined $thing;
  my $text = ref $thing ? ( eval { $self->_json->encode($thing) } // "$thing" ) : $thing;
  return int( length($text) / 4 );
}

sub _json { JSON::MaybeXS->new( canonical => 1, convert_blessed => 1, allow_blessed => 1, allow_nonref => 1 ) }

sub cmd_context {
  my ($self) = @_;
  my $out = $self->output;
  my $app = $self->app;
  my $context = $app->context;
  my $raider = $app->raider;
  my $mission = $raider->mission // '';
  my $system = $self->estimate_tokens($mission);

  # The parts of the system prompt that can be told apart; the rest (tool
  # list, packs, headers) is "other".
  my @parts;
  # The instructions item -- raider's own; no public accessor on the app.
  my $instructions = $app->instructions_text;
  if (index($mission, $instructions) >= 0) {
    my $file = $app->instructions;
    my $custom = $app->bare ? undef : $file->text;
    my $own = defined $custom && index($instructions, $custom) >= 0 ? $self->estimate_tokens($custom) : 0;
    push @parts, [ 'instructions ('.$app->mission_source.')', $self->estimate_tokens($instructions) - $own ];
    push @parts, [ $file->label, $own ] if $own;
  }
  for my $item ($context->instruction_items) {
    ( my $text = $item->{text} ) =~ s/\s+\z//;
    push @parts, [ $item->{label}, $self->estimate_tokens($text) ] if index($mission, $text) >= 0;
  }
  my $catalog = $context->skill_catalog;
  my $listing = $catalog->prompt_text;
  if (defined $listing && index($mission, $listing) >= 0) {
    my $n = () = $catalog->listed;
    push @parts, [ 'skill listing ('.$n.' skill'.( $n == 1 ? '' : 's' ).')', $self->estimate_tokens($listing) ];
  }
  my $known = 0;
  $known += $_->[1] for @parts;
  push @parts, [ 'other (tool list, packs, headers)', $system > $known ? $system - $known : 0 ];

  # The tool definitions the engine gets -- the app's mounted tools.
  my @tools = $app->mounted_tools;
  my $tool_tokens = 0;
  $tool_tokens += $self->estimate_tokens({
    name         => $_->name,
    description  => $_->description,
    input_schema => $_->input_schema,
  }) for @tools;

  my @history = @{ $raider->history };
  my $history_tokens = 0;
  $history_tokens += $self->estimate_tokens($_) for @history;

  my $line = sub { $out->say_meta(sprintf('%-36s ~%d', @_)) };
  $out->say_meta('context (estimated tokens, about 4 characters each):');
  $line->('  system prompt', $system);
  $line->('    '.$_->[0], $_->[1]) for @parts;
  $line->('  tool definitions ('.scalar(@tools).' tool'.( @tools == 1 ? '' : 's' ).')', $tool_tokens);
  $line->('  history ('.scalar(@history).' message'.( @history == 1 ? '' : 's' ).')', $history_tokens);
  $line->('  total', $system + $tool_tokens + $history_tokens);
  if ($raider->has_max_context_tokens) {
    my $max = $raider->max_context_tokens;
    my $threshold = $raider->context_compress_threshold;
    $out->say_meta('  budget: '.$max.' tokens (max_context_tokens); history compacted above ~'
      .int($max * $threshold).' ('.int($threshold * 100 + 0.5).'%)');
  }
  return;
}

#### /memory


sub memory_files {
  my ($self) = @_;
  my $app = $self->app;
  my $context = $app->context;
  my $native = $app->instructions;
  my ( @files, %seen );
  my $add = sub {
    my ( $label, $file, $loaded ) = @_;
    my $key = $self->_real($file);
    return if $seen{$key}++;
    push @files, { label => $label, file => $key, loaded => $loaded ? 1 : 0, exists => -f $key ? 1 : 0 };
  };
  $add->($_->{label}, $_->{file}, 1) for $context->instruction_items;
  my $custom = $app->bare ? undef : $native->text;
  $add->($native->label, $native->file, 1)
    if defined $custom && index($app->instructions_text, $custom) >= 0;
  if ($context->claude_layout) {
    $add->('CLAUDE.md', $context->layout->project_dir->child('CLAUDE.md'));
    $add->('~/.claude/CLAUDE.md', path($context->claude_home)->child('CLAUDE.md'))
      if defined $context->claude_home;
  }
  $add->($native->label, $native->file) unless $app->claude_persona_off;
  return @files;
}

sub _real {
  my ( $self, $file ) = @_;
  my $p = path($file);
  return ( -e $p ? eval { $p->realpath->stringify } : undef ) // $p->absolute->stringify;
}

sub editor {
  my $e = $ENV{VISUAL};
  $e = $ENV{EDITOR} unless defined $e && $e =~ /\S/;
  return defined $e && $e =~ /\S/ ? $e : undef;
}

sub is_terminal {
  my ($self) = @_;
  return -t $self->in && -t $self->output->out ? 1 : 0;
}

sub run_editor {
  my ( $self, $editor, $file ) = @_;
  system('sh', '-c', $editor.' "$1"', 'sh', $file);
  return $? == 0 ? 1 : 0;
}

sub cmd_memory {
  my ( $self, $arg ) = @_;
  my $out = $self->output;
  my @files = $self->memory_files;
  $arg //= '';
  $arg =~ s/\A\s+|\s+\z//g;
  unless (length $arg) {
    return $out->say_meta('no instruction files.') unless @files;
    $out->say_meta('instruction files (/memory N to edit):');
    my $n = 0;
    for my $f (@files) {
      $n++;
      my $state = $f->{loaded} ? ' (loaded)' : $f->{exists} ? '' : ' (not there)';
      $out->say_meta('  '.$n.'. '.$f->{label}.$state.( $f->{label} eq $f->{file} ? '' : '  '.$f->{file} ));
    }
    return;
  }
  return $out->say_error('usage: /memory [N]'.( @files ? ' (N from 1 to '.scalar(@files).')' : '' ))
    unless $arg =~ /\A[0-9]+\z/ && $arg >= 1 && $arg <= @files;
  my $file = $files[$arg - 1]{file};
  my $editor = $self->editor;
  unless (defined $editor && $self->is_terminal) {
    $out->say_meta($file);
    $out->say_meta('set $VISUAL or $EDITOR to edit it here.') if !defined $editor && $self->is_terminal;
    return;
  }
  my $p = path($file);
  $p->touchpath unless -e $p;
  $out->say_error('editor exited with an error: '.$editor) unless $self->run_editor($editor, $p->stringify);
  my $app = $self->app;
  $app->reload_context;
  $app->reload_mission;
  $out->say_meta('context reloaded after editing '.$files[$arg - 1]{label}.'.');
  return;
}

#### /agents

# The longest description shown by /agents.
sub agent_description_limit { 100 }

sub cmd_agents {
  my ($self) = @_;
  my $out = $self->output;
  my $catalog = $self->app->context->agent_catalog;
  my @agents = $catalog->agents;
  $out->say_meta('agents:');
  for my $agent (@agents) {
    # The first line; agent files often write their newlines as "\n".
    my ($desc) = split /\n|\\n/, $agent->{description} // '';
    $desc //= '';
    $desc =~ s/\A\s+|\s+\z//g;
    my $limit = $self->agent_description_limit;
    $desc = substr($desc, 0, $limit - 3).'...' if length $desc > $limit;
    my $tools = $agent->{tools};
    $out->say_meta('  '.$agent->{name}.' ('.$agent->{source}.')'.( length $desc ? ': '.$desc : '' ));
    $out->say_meta('      tools: '.( !defined $tools ? 'all' : @$tools ? join(', ', @$tools) : 'none' ));
  }
  my @shadowed = $catalog->shadowed;
  if (@shadowed) {
    $out->say_meta('shadowed:');
    $out->say_meta('  '.$_->{name}.' ('.$_->{source}.') by '.$_->{by}) for @shadowed;
  }
  return;
}

#### /hooks

sub cmd_hooks {
  my ($self) = @_;
  my $out = $self->output;
  my $app = $self->app;
  my $hooks = $app->context->claude_layout ? $app->hooks : undef;
  return $out->say_meta('no hooks configured (hooks run in the Claude layout only).') unless $hooks;
  my $settings = $hooks->settings;
  return $out->say_meta('all hooks are disabled (disableAllHooks).')
    if $settings && $settings->disable_all_hooks;
  my $groups = $hooks->groups;
  my @events = sort grep { @{ $groups->{$_} } } keys %$groups;
  $out->say_meta('no hooks configured.') unless @events;
  for my $event (@events) {
    $out->say_meta($event.':');
    for my $g (@{ $groups->{$event} }) {
      my $matcher = defined $g->{matcher} && length $g->{matcher} ? $g->{matcher} : '*';
      for my $h (grep { ref $_ eq 'HASH' } @{ $g->{hooks} }) {
        my $type = $h->{type} // 'command';
        my $what = $type eq 'command'
          ? join(' ', grep { defined && !ref } $h->{command}, ref $h->{args} eq 'ARRAY' ? @{ $h->{args} } : ())
          : $type.' (not run by raider)';
        $out->say_meta('  '.$matcher.'  '.$what
          .( defined $h->{if} && !ref $h->{if} ? '  if '.$h->{if} : '' )
          .( defined $h->{timeout} && !ref $h->{timeout} ? '  timeout '.$h->{timeout}.'s' : '' )
          .( $h->{async} ? '  async' : '' )
          .'  ('.$g->{source}.')');
      }
    }
  }
  my @errors = @{ $hooks->config_errors };
  if (@errors) {
    $out->say_meta('problems:');
    $out->say_meta('  '.$_) for @errors;
  }
  return;
}

#### /init


sub init_prompt_claude {
  my ($self) = @_;
  return $self->init_prompt('CLAUDE.md', 'Claude Code', "# CLAUDE.md\n\n"
    ."This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.");
}

sub init_prompt_native {
  my ( $self, $label ) = @_;
  return $self->init_prompt($label, 'raider', '# '.$label."\n\n"
    .'This file provides guidance to raider when working with code in this repository.');
}

sub init_prompt {
  my ( $self, $file, $agent, $preamble ) = @_;
  return 'Please analyze this codebase and create a '.$file.' file, which will be given to future'
    .' instances of '.$agent.' to operate in this repository.'."\n\n"
    ."What to add:\n"
    .'1. Commands that will be commonly used, such as how to build, lint, and run tests. Include the'
    .' necessary commands to develop in this codebase, such as how to run a single test.'."\n"
    .'2. High-level code architecture and structure so that future instances can be productive more'
    .' quickly. Focus on the "big picture" architecture that requires reading multiple files to'
    .' understand.'."\n\n"
    ."Usage notes:\n"
    ."- If there's already a ".$file.", suggest improvements to it.\n"
    .'- When you make the initial '.$file.', do not repeat yourself and do not include obvious'
    .' instructions like "Provide helpful error messages to users", "Write unit tests for all new'
    .' utilities", "Never include sensitive information (API keys, tokens) into code or commits".'."\n"
    ."- Avoid listing every component or file structure that can be easily discovered.\n"
    ."- Don't include generic development practices.\n"
    .'- If there are Cursor rules (in .cursor/rules/ or in .cursorrules) or Copilot rules (in'
    .' .github/copilot-instructions.md), make sure to include the important parts.'."\n"
    ."- If there is a README.md, make sure to include the important parts.\n"
    .'- Do not make up information such as "Common Development Tasks", "Tips for Development",'
    .' "Support and Documentation" unless this is expressly included in other files that you read.'."\n"
    ."- Be sure to prefix the file with the following text:\n\n"
    ."```\n".$preamble."\n```\n";
}

sub cmd_init {
  my ($self) = @_;
  my $app = $self->app;
  return { prompt => $self->init_prompt_claude } if $app->context->claude_layout;
  my $file = $app->instructions->file;
  my $label = path($file)->relative($app->root)->stringify;
  return { prompt => $self->init_prompt_native($label) };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Commands - Internal slash commands of the raider REPL

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $commands = Langertha::Raider::CLI::Commands->new(app => $app, output => $out);
    $commands->dispatch('/pack on polite');

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The slash commands of the F<raider> REPL (C</help>, C</clear>, C</metrics>,
C</stats>, C</reload>, C</prompt>, C</skill>, C</skill-claude>, C</config>,
C</permissions>, C</mcp>, C</model>, C</packs>, C</pack>). C</permissions> prints the
permission mode with its source and every rule with its source, session
rules included (ADR 0021); C</permissions mode MODE> switches the mode. Each command C</name> is the method
C<cmd_name> (dashes become underscores) and gets the rest of the line as
its argument. Leaving the REPL (C</quit>) is the REPL's business.

The commands of ADR 0030 E<sect>5 (every report prints plain lines and
works without a terminal, for a one-shot run):

=over

=item * C</help> -- the built-in commands, then the user-invocable skills
and custom commands of the catalogue
(L<Langertha::Raider::Context::Skills/user_invocable>), sorted, each as
C</name argument-hint  description (source)>.

=item * C</clear>, C</reset>, C</new> -- forget the conversation history.

=item * C</skills> -- every catalogue entry: name, kind (C<skill> or
C<command>), source, whether the model and the user may invoke it, the
C<paths:> of a conditional skill that is not active yet; then the
shadowed entries and files that could not be read.

=item * C</compact [INSTRUCTIONS]> -- summarise the history now
(L<Langertha::Raider/compress_history>), the instructions passed as focus
for the summary: C<history compacted (N messages → summary, ~T tokens)>,
or C<nothing to compact.>

=item * C</context> -- the context by part with estimated tokens
(L</estimate_tokens>): the system prompt (the instructions item, the
instructions file, each memory file, the skill listing, the rest), the
tool definitions, the history, the total and the compaction budget.

=item * C</memory [N]> -- the numbered instruction files (L</memory_files>):
those loaded, and the editable targets (Claude layout F<./CLAUDE.md> and
F<~/.claude/CLAUDE.md>, the native instructions file outside Claude mode),
C<(not there)> when missing. C</memory N> opens file N in C<$VISUAL> or
C<$EDITOR> (L</run_editor>) when input and output are a terminal --
creating it -- and reloads the context and the mission; otherwise it
prints the path.

=item * C</agents> -- the agent catalogue (ADR 0020): name, source, the
first line of the description, the tools; then the shadowed agents.

=item * C</hooks> -- the hooks of the Claude layout (ADR 0022) by event:
matcher, command (or type), timeout, source; C<no hooks configured.>
otherwise.

=item * C</init> -- returns a run request C<< { prompt => $text } >> with
Claude Code's C</init> request (L</init_prompt_claude>) for F<CLAUDE.md>
in the Claude layout, else the same request for the native instructions
file (L</init_prompt_native>). Sending it is the caller's business.

=back

=head2 app

The L<Langertha::Raider::CLI> the commands act on. Required.

=head2 output

The L<Langertha::Raider::CLI::Output> to print to. Required.

=head2 in

Filehandle C</prompt> reads its conversation from. Defaults to C<STDIN>.

=head2 dispatch

    my $r = $commands->dispatch('/model list gpt');
    my $r = $commands->dispatch('/review src/App.pm', session => sub { $session });
    if ( ref $r eq 'HASH' ) { run_prompt( $r->{prompt}, %$r ) }   # a run request

Resolves one C</name rest> line (ADR 0030 E<sect>3) and runs it:

=over

=item 1. A first word that holds another C</> (C</etc/hosts is broken>) is
no command: the run request C<< { prompt => $line } >>, an ordinary prompt.

=item 2. A user-invocable catalogue entry of that name
(L<Langertha::Raider::Context::Skills/find_user_invocable>) -- it beats a
built-in of the same name, not the built-in's aliases: rendered with the
rest of the line (L<Langertha::Raider::Application/slash_run_request>, with
C<@file> attachments) into a run request. A render that aborts is printed as
an error and nothing runs. C<session> (a L<Langertha::Raider::Session> or a
code reference returning one, called only here) gives
C<${CLAUDE_SESSION_ID}>.

=item 3. C</mcp__SERVER__PROMPT ARGS>: a prompt of a configured MCP server
(L<Langertha::Raider::Application/mcp_prompt_request>, ADR 0029 Addendum 1),
a run request; a server or prompt that does not exist is an unknown command.

=item 4. A built-in: the method C<cmd_NAME> (L</command_method>) with the
rest of the line.

=item 5. Anything else: C<unknown command: /NAME (try /help)>.

=back

Returns false for an unknown command or a failed render (after saying so),
a run request when the line is to be sent to the model, true otherwise. A
run request is a hash C<< { prompt => $text } >>, for a catalogue entry
with C<allow_rules>, C<allow_source>, C<model> and C<attach_reads> -- the
run options of L<Langertha::Raider::CLI::Runner/run_prompt>. A built-in that
wants a model turn (C</init>) returns one too.

=head2 resolve

    my $r = $commands->resolve('/review src/App.pm');
    # { kind => 'entry', name => 'review', arguments => 'src/App.pm', entry => {...} }

How L</dispatch> reads the line, without running anything: C<kind> is
C<prompt> (a path-like first word), C<entry> (with the catalogue
C<entry>), C<mcp_prompt> (a name C<mcp__SERVER__PROMPT>), C<builtin> (with its C<method>) or C<unknown>; C<name> is the
word after the C</>, C<arguments> the rest of the line, trimmed (C<undef>
when empty). A catalogue that cannot be read (a broken config file) holds
no entry: the built-ins still resolve, and its error is in
C<catalog_error>, which L</dispatch> adds to an unknown command.

=head2 command_method

    my $method = $commands->command_method('skill-claude');   # 'cmd_skill_claude'

The method of the built-in command C</NAME> (dashes become underscores),
or nothing when there is none.

=head2 cmd_mcp

    $commands->cmd_mcp('');               # /mcp
    $commands->cmd_mcp('reconnect db');   # /mcp reconnect db (or all / no name)

Without an argument the configured MCP servers (ADR 0029), started first
when they are not yet (in parallel, each within C<MCP_TIMEOUT>): status,
source, scope, transport, reason, approval, the last stderr lines of a
failed one and every server's tools
(L<Langertha::Raider::CLI::Output/mcp_report>). A one-shot C<raider /mcp>
prints the same (L<Langertha::Raider::CLI::Main/oneshot_command>).
C<reconnect> restarts a server (all of them without a name or with C<all>)
and shows the list again.

=head2 collapse_model_list

    my @rows = $commands->collapse_model_list(\@ids, $current);

Folds dated snapshots (C<gpt-4o-2024-08-06>, C<claude-3-5-sonnet-20241022>
style C<-YYYY> suffixes) under their base model. Returns sorted rows
C<{ id, snaps, current, orphan }>; C<orphan> marks a snapshot family whose
base is not listed itself.

=head2 estimate_tokens

    my $n = $commands->estimate_tokens($text);       # or a message / schema hash

Rough token count: the characters over four, the rule
L<Langertha::Raider>'s in-loop compaction estimates with; a reference is
counted as its JSON. C<0> for C<undef>.

=head2 memory_files

    for my $f ($commands->memory_files) { say $f->{label}.' '.$f->{file} }

The files C</memory> numbers, each C<< { label, file, loaded, exists } >>:
first the instruction files in the prompt
(L<Langertha::Raider::Context/instruction_items>, and the native
instructions file when the instructions item holds it), then the editable
targets not listed yet -- in the Claude layout F<CLAUDE.md> of the project
directory and F<CLAUDE.md> of the Claude home, outside Claude mode the
native instructions file (L<Langertha::Raider::Instructions/file>).

=head2 editor

The editor command C</memory N> runs: C<$VISUAL>, else C<$EDITOR>; C<undef>
without either.

=head2 is_terminal

True when L</in> and the output are terminals -- only then C</memory N>
starts an editor.

=head2 run_editor

    my $ok = $commands->run_editor($editor, $file);

Runs C<$editor> on C<$file> through C<sh -c> (so C<$EDITOR> may carry
arguments, C<code -w>) and waits. True when it exited with 0. Override
point for tests.

=head2 init_prompt_claude

The prompt C</init> sends in the Claude layout: Claude Code's C</init>
request for F<CLAUDE.md>.

=head2 init_prompt_native

    my $text = $commands->init_prompt_native('.raider.md');

The same request for raider's native instructions file C<$label>.

=head2 init_prompt

    my $text = $commands->init_prompt($file, $agent, $preamble);

The request both are made of: C<$file> the file to write, C<$agent> who
reads it, C<$preamble> the text the file must start with.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI>

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
