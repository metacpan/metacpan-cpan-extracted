package Langertha::Raider::CLI::Output;
# ABSTRACT: Internal terminal renderer of the raider CLI
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS ();
use Term::ANSIColor qw( colored color );


# Palette: blue tones + yellow accents.
my %PALETTE = (
  brand  => 'bold bright_blue',
  title  => 'bold blue',
  prompt => 'bold cyan',
  agent  => 'bright_green',
  meta   => 'bright_black',
  accent => 'yellow',
  warn   => 'yellow',
  err    => 'red',
);


has out => (
  is      => 'ro',
  default => sub { \*STDOUT },
);


has color => (
  is      => 'ro',
  isa     => 'Bool',
  lazy    => 1,
  builder => '_build_color',
);

sub _build_color { -t $_[0]->out ? 1 : 0 }


sub c {
  my ( $self, $key, @text ) = @_;
  my $text = join '', @text;
  return $self->color ? colored([ $PALETTE{$key} ], $text) : $text;
}


sub emit {
  my ( $self, @text ) = @_;
  print { $self->out } @text;
  return;
}


sub say_agent { $_[0]->emit($_[0]->c(agent => $_[0]->render_inline_code($_[1])), "\n") }
sub say_meta  { $_[0]->emit($_[0]->c(meta => $_[1]), "\n") }
sub say_error { $_[0]->emit($_[0]->c(err => 'error: '), $_[0]->c(warn => $_[1]), "\n") }


sub error_text {
  my ( $self, $error ) = @_;
  $error = "$error";
  $error =~ s/ at (?:\w+ \S+ \(defined at .+ line \d+\)|(?:(?! at ).)+) line \d+\.?\n?\z//s;
  chomp $error;
  return $error;
}


sub render_inline_code {
  my ( $self, $text ) = @_;
  return $text unless $self->color && !$ENV{ANSI_COLORS_DISABLED};
  my $code_on  = color('on_grey3');
  my $agent_on = color($PALETTE{agent});
  my $reset    = color('reset');
  $text =~ s{(?<!`)`([^`\n]+?)`(?!`)}{$code_on$1$reset$agent_on}g;
  return $text;
}


sub config_report {
  my ( $self, $report ) = @_;
  my $json = JSON::MaybeXS->new(canonical => 1, allow_nonref => 1);
  $self->emit($self->c(meta => 'file:   '), $self->c(title => $report->{file}),
    $self->c(meta => $report->{exists} ? '' : ' (not present)'), "\n");
  for my $ign (@{ $report->{ignored_files} // [] }) {
    $self->emit('  ', $self->c(warn => 'ignored file '.$ign->{file}.': '.$ign->{reason}), "\n");
  }
  $self->emit($self->c(meta => 'home:   '), $self->c(title => $report->{home_file}), "\n")
    if defined $report->{home_file};
  $self->emit($self->c(meta => 'engine: '), $self->c(title => $report->{engine}), "\n");
  $self->emit($self->c(meta => 'instructions: '), $self->c(title => $report->{instructions}),
    $self->c(meta => $report->{bare} ? ' (bare)' : ''), "\n") if defined $report->{instructions};
  for my $ign (@{ $report->{ignored_instructions_files} // [] }) {
    $self->emit('  ', $self->c(warn => 'ignored file '.$ign->{file}.': '.$ign->{reason}), "\n");
  }
  if (my $l = $report->{layout}) {
    $self->emit($self->c(meta => 'layout: '), $self->c(title => $l->{mode}),
      $self->c(meta => ' ('.$l->{reason}.'); Claude layout '
        .( $l->{claude_layout} ? 'on' : 'off' ).' ('.$l->{claude_layout_reason}.')'), "\n");
    $self->emit('  ', $self->c(meta => 'project dir: '), $l->{project_dir}, "\n") if defined $l->{project_dir};
  }
  for my $m (@{ $report->{memory} // [] }) {
    $self->emit('  ', $self->c(meta => 'memory '), $self->c(title => $m->{label}),
      $self->c(meta => ' ('.$m->{scope}.( @{ $m->{imports} } ? ', imports '.join(', ', @{ $m->{imports} }) : '' ).')'), "\n");
  }
  for my $v (@{ $report->{values} }) {
    my $value = ref $v->{value} ? $json->encode($v->{value}) : $v->{value} // '';
    my $from  = 'from '.$v->{source};
    $from .= ', merged with '.join(', ', @{ $v->{merged_with} }) if @{ $v->{merged_with} // [] };
    $from .= ', overrides '.join(', ', @{ $v->{shadowed} }) if @{ $v->{shadowed} // [] };
    $from .= ', merged' if $v->{merged};
    $self->emit(sprintf("  %s %s  %s\n", $self->c(title => sprintf('%-22s', $v->{key})), $value,
      $self->c(meta => '('.$from.'; '.$v->{applies_to}.')')));
  }
  for my $ign (@{ $report->{ignored} }) {
    $self->emit('  ', $self->c(warn => 'ignored '.$ign->{key}.': '.$ign->{reason}), "\n");
  }
  if (my $packs = $report->{packs}) {
    $self->emit($self->c(meta => 'packs:  '), $self->c(meta => '(detection '.$report->{detection}.')'), "\n");
    for my $p (@$packs) {
      $self->emit(sprintf("  %s %-8s  %-7s  %s\n", $self->c(title => sprintf('%-20s', $p->{name})),
        $p->{active} ? 'active' : 'inactive', $p->{origin} // '',
        $self->c(meta => $self->pack_reason($p, rule => 1))));
      $self->emit('    ', $self->c(warn => 'note: '.$_), "\n") for @{ $p->{detection}{notes} // [] };
    }
  }
  for my $s (@{ $report->{skipped_packs} // [] }) {
    $self->emit('  ', $self->c(warn => 'skipped pack '.$s->{name}.' ('.$s->{origin}.' '.$s->{path}.'): '.$s->{reason}), "\n");
  }
  if (my $perl = $report->{perl_tools}) {
    $self->emit($self->c(meta => 'perl tools: '), $perl->{enabled} ? 'on' : 'off',
      '  ', $self->c(meta => '('.$perl->{reason}.')'), "\n");
  }
  if (my $se = $report->{session_embeddings}) {
    $self->emit($self->c(meta => 'session embeddings: '), $se->{enabled} ? 'on' : 'off',
      $se->{reason} ? ( '  ', $self->c(meta => '('.$se->{reason}.')') ) : (), "\n");
  }
  if (my $tools = $report->{tools}) {
    $self->emit($self->c(meta => 'tools:  '), $self->c(meta => '(what a tool can do: information only)'), "\n");
    for my $t (@$tools) {
      my $fx = $t->{effects};
      $self->emit(sprintf("  %s %-10s  %s\n", $self->c(title => sprintf('%-22s', $t->{name})), $t->{source},
        $self->c(meta => !$fx ? 'unknown' : @$fx ? join(', ', @$fx) : 'none')));
    }
  }
  $self->permissions_report($report->{permissions}) if $report->{permissions};
  $self->mcp_report($report->{mcp}) if $report->{mcp};
  if (my $skills = $report->{skills}) {
    $self->emit($self->c(meta => 'skills: '), $self->c(meta => '(listed in the prompt, loaded by the skill tool)'), "\n")
      if @$skills || @{ $report->{shadowed_skills} // [] } || @{ $report->{skill_problems} // [] };
    # The name column as wide as the longest name (plugin:skill names run long).
    my ( $width ) = sort { $b <=> $a } 22, map { length $_->{name} } @$skills;
    for my $s (@$skills) {
      $self->emit(sprintf("  %s %-8s  %s\n", $self->c(title => sprintf('%-'.$width.'s', $s->{name})),
        $s->{listed} ? 'listed' : 'hidden', $self->c(meta => $s->{source}.( $s->{listed} ? '' : '; disable-model-invocation' ))));
    }
    for my $s (@{ $report->{shadowed_skills} // [] }) {
      $self->emit('  ', $self->c(warn => 'shadowed skill '.$s->{name}.' ('.$s->{source}.') by '.$s->{by}), "\n");
    }
    for my $p (@{ $report->{skill_problems} // [] }) {
      $self->emit('  ', $self->c(warn => 'skill file '.$p->{file}.': '.$p->{reason}), "\n");
    }
  }
  if (my $agents = $report->{agents}) {
    $self->emit($self->c(meta => 'agents: '), $self->c(meta => '(started by the agent tool; tools in raider names)'), "\n");
    my ( $width ) = sort { $b <=> $a } 22, map { length $_->{name} } @$agents;
    for my $ag (@$agents) {
      my $m = $ag->{model};
      $self->emit('  ', $self->c(title => sprintf('%-'.$width.'s', $ag->{name})), ' ', $self->c(meta => $ag->{source}), "\n");
      $self->emit('    ', join('; ',
        'tools '.( ref $ag->{tools} ? ( @{ $ag->{tools} } ? join(', ', @{ $ag->{tools} }) : 'none' ) : $ag->{tools} ),
        ( @{ $ag->{disallowed} } ? 'not '.join(', ', @{ $ag->{disallowed} }) : () ),
        'model '.( defined $m->{model} ? $m->{model} : 'inherit ('.$m->{reason}.')' ),
        ( @{ $ag->{skills} } ? 'skills '.join(', ',
          map { defined $ag->{skill_via}{$_} ? $_.' ('.$ag->{skill_via}{$_}.')' : $_ } @{ $ag->{skills} }) : () ),
      ), "\n");
      $self->emit('    ', $self->c(warn => 'unknown skills: '.join(', ',
        map { defined $ag->{missing_reasons}{$_} ? $_.' ('.$ag->{missing_reasons}{$_}.')' : $_ } @{ $ag->{missing_skills} })
        .' (the agent tool refuses to start it)'), "\n") if @{ $ag->{missing_skills} // [] };
      $self->emit('    ', $self->c(warn => 'unknown tools: '.join(', ', @{ $ag->{unknown_tools} })), "\n")
        if @{ $ag->{unknown_tools} };
      $self->emit('    ', $self->c(meta => 'not used by raider: '.join(', ', @{ $ag->{ignored_keys} })), "\n")
        if @{ $ag->{ignored_keys} };
    }
    for my $s (@{ $report->{shadowed_agents} // [] }) {
      $self->emit('  ', $self->c(warn => 'shadowed agent '.$s->{name}.' ('.$s->{source}.') by '.$s->{by}), "\n");
    }
    for my $p (@{ $report->{agent_problems} // [] }) {
      $self->emit('  ', $self->c(warn => 'agent file '.$p->{file}.': '.$p->{reason}), "\n");
    }
  }
  if (my $st = $report->{settings}) {
    my $perm = $st->{permissions};
    $self->emit($self->c(meta => 'settings: '), $self->c(meta => '(Claude Code settings; permissions and hooks read only)'), "\n");
    for my $f (@{ $st->{files} }) {
      $self->emit('  ', $self->c(title => sprintf('%-30s', $f->{label})), ' ',
        $f->{error} ? $self->c(warn => $f->{error}) : $f->{exists} ? 'read' : $self->c(meta => 'not present'), "\n");
    }
    $self->emit('  ', $self->c(meta => 'permissions: '), join(', ', map { $_.' '.$perm->{$_} } qw( allow ask deny )),
      ( defined $perm->{default_mode} ? ', default mode '.$perm->{default_mode} : '' ),
      ( $perm->{additional_directories} ? ', '.$perm->{additional_directories}.' additional directories' : '' ), "\n");
    $self->emit('  ', $self->c(meta => 'env: '), join(', ', @{ $st->{env} }), $self->c(meta => ' (set for tools)'), "\n")
      if @{ $st->{env} };
    $self->emit('  ', $self->c(meta => 'hooks: '), join(', ', map { $_.' ('.$st->{hooks}{$_}.')' } sort keys %{ $st->{hooks} }),
      $self->c(meta => ' (not run yet)'), "\n") if %{ $st->{hooks} };
    $self->emit('  ', $self->c(meta => 'enabled plugins: '), join(', ', @{ $st->{enabled_plugins} }), "\n")
      if @{ $st->{enabled_plugins} };
    for my $i (@{ $st->{ignored} }) {
      $self->emit('  ', $self->c(warn => 'ignored '.$i->{key}.' ('.$i->{source}.'): not used by raider'), "\n");
    }
  }
  if (my @plugins = @{ $report->{plugins} // [] }) {
    $self->emit($self->c(meta => 'plugins: '), join(', ', map { $_->{name}.' ('.$_->{scope}.')' } @plugins), "\n");
  }
  if (my $providers = $report->{providers}) {
    $self->emit($self->c(meta => 'providers: '), $self->c(meta => '(stored aliases of the home file; raider provider list|show|remove)'), "\n");
    for my $p (@$providers) {
      $self->emit(sprintf("  %s %s\n", $self->c(title => sprintf('%-20s', $p->{alias})),
        $p->{problem} ? $self->c(warn => 'unusable: '.$p->{problem})
          : join('  ', $p->{origin},
            $self->c(meta => 'auth: '.( @{ $p->{auth} } ? join(', ', @{ $p->{auth} }) : 'none' )),
            $self->c(meta => 'credential: '.( $p->{credential_env} // 'none' )),
            ( $p->{allow_internal} ? $self->c(warn => 'internal allowed') : () ))));
    }
  }
  if (my $pt = $report->{project_tools}) {
    $self->emit($self->c(meta => 'project tools: '), $self->c(title => $pt->{label}),
      '  ', $self->c(meta => '(granted by project_tools: information only, nothing is mounted by it)'), "\n");
    $self->emit('  ', $self->c(meta => 'selectors:'), "\n") if @{ $pt->{selectors} };
    for my $s (@{ $pt->{selectors} }) {
      $self->emit(sprintf("    %s %-11s  %s\n", $self->c(title => sprintf('%-20s', $s->{selector})),
        $s->{matched} ? 'matched' : 'not matched',
        $self->c(meta => $s->{reason}.( @{ $s->{tools} } ? '; '.join(', ', @{ $s->{tools} }) : '' ))));
    }
    $self->emit('  ', $self->c(meta => 'tools:'), "\n") if @{ $pt->{tools} };
    for my $t (@{ $pt->{tools} }) {
      my @about = (
        @{ $t->{requested_by} } ? 'requested by '.join(', ', @{ $t->{requested_by} }) : 'not requested',
        $t->{known} // 'unknown',
      );
      $self->emit(sprintf("    %s %s  %s\n", $self->c(title => sprintf('%-20s', $t->{name})),
        @{ $t->{granted_by} } ? 'granted by '.join(', ', @{ $t->{granted_by} }) : 'not granted',
        $self->c(meta => '('.join('; ', @about).')')));
    }
  }
  return;
}


sub permissions_report {
  my ( $self, $p, %o ) = @_;
  $self->emit($self->c(meta => 'permissions: '), 'mode ', $self->c(title => $p->{mode}),
    $self->c(meta => ' (from '.$p->{mode_source}.')'), "\n");
  $self->emit('  ', $self->c(meta => $p->{mode_note}), "\n") if defined $p->{mode_note};
  for my $m (@{ $p->{ignored_modes} }) {
    $self->emit('  ', $self->c(warn => 'ignored mode '.$m->{value}.' ('.$m->{source}.'): '.$m->{reason}), "\n");
  }
  for my $kind (qw( deny ask allow )) {
    my $rules = $p->{rules}{$kind};
    if ($o{rules}) {
      $self->emit(sprintf("  %s %s  %s\n", $self->c(title => sprintf('%-6s', $kind)), $_->{rule},
        $self->c(meta => '('.$_->{source}.')'))) for @$rules;
      next;
    }
    next unless @$rules;
    my ( %count, @order );
    for my $r (@$rules) { push @order, $r->{source} unless $count{ $r->{source} }++ }
    $self->emit(sprintf("  %s %d  %s\n", $self->c(title => sprintf('%-6s', $kind)), scalar @$rules,
      $self->c(meta => '('.join(', ', map { $_.' '.$count{$_} } @order).')')));
  }
  for my $r (@{ $p->{invalid_rules} }) {
    $self->emit('  ', $self->c(warn => 'ignored '.$r->{kind}.' rule '.$r->{rule}.' ('.$r->{source}.'): '.$r->{error}), "\n");
  }
  for my $d (@{ $p->{additional_directories} }) {
    $self->emit('  ', $self->c(meta => 'additional directory '), $d->{path}, $self->c(meta => ' ('.$d->{source}.')'), "\n");
  }
  return;
}


my %MCP_STATUS = ( pending => 'pending approval', not_configured => 'not configured' );

sub mcp_report {
  my ( $self, $r, %o ) = @_;
  my $servers = $r->{servers} // [];
  $self->emit($self->c(meta => 'mcp servers: '), @$servers ? scalar(@$servers) : 'none',
    $self->c(meta => sprintf(' (start %ds each%s)', $r->{startup_timeout_ms} / 1000,
      defined $r->{tool_timeout_ms} ? sprintf(', calls %ds', $r->{tool_timeout_ms} / 1000) : '')), "\n");
  for my $s (@$servers) {
    my $status = $MCP_STATUS{ $s->{status} } // $s->{status};
    my $color = $s->{status} eq 'connected' ? 'title' : $s->{status} =~ /\A(?:configured|starting|stopped)\z/ ? 'meta' : 'warn';
    $self->emit('  ', $self->c(title => $s->{name}), ' ', $self->c($color => $status),
      $self->c(meta => '  '.$s->{scope}.', '.( $s->{transport} // '?' ).', '.$s->{source}), "\n");
    $self->emit('    ', $self->c(meta => $s->{reason}), "\n")
      if defined $s->{reason} && $s->{status} ne 'pending';
    my $ap = $s->{approval};
    $self->emit('    ', $self->c(meta => 'approval: '.$ap->{state}
      .( defined $ap->{source} ? ' ('.$ap->{by}.' in '.$ap->{source}.')' : '' )), "\n") if $ap && $ap->{required};
    $self->emit('    ', $self->c(warn => 'warning: '.$_), "\n") for @{ $s->{warnings} // [] };
    $self->emit('    ', $self->c(meta => 'shadows '.$_->{scope}.' entry in '.$_->{source}), "\n") for @{ $s->{shadowed} // [] };
    if ($s->{status} eq 'failed') {
      my @err = @{ $s->{stderr} // [] };
      @err = @err[ -3 .. -1 ] if @err > 3;
      $self->emit('    ', $self->c(meta => 'stderr: '.$_), "\n") for @err;
    }
    if ($o{tools} && @{ $s->{tools} // [] }) {
      $self->emit('    ', $self->c(meta => 'tools: '), join(', ', @{ $s->{tools} }), "\n");
    }
  }
  $self->emit('  ', $self->c(warn => 'cannot read '.$_->{source}.': '.$_->{error}), "\n") for @{ $r->{errors} // [] };
  $self->emit('  ', $self->c(warn => 'warning: '.$_), "\n") for @{ $r->{warnings} // [] };
  if (grep { $_->{approval} && $_->{approval}{required} } @$servers) {
    my $t = $r->{trust} // {};
    $self->emit('  ', $self->c(meta => 'folder '.( $t->{trusted} ? 'trusted ('.$t->{source}.')' : 'not trusted by Claude Code' )
      .( defined $r->{approvals_go_to} ? '; answers are saved in '.$r->{approvals_go_to} : '' )), "\n");
  }
  return;
}


sub migrate_report {
  my ( $self, $plan, %opt ) = @_;
  unless (@{ $plan->{steps} }) {
    $self->emit($self->c(meta => 'nothing to migrate: no .raider.yml or .raider.md in '.$plan->{root}), "\n");
    return;
  }
  for my $s (@{ $plan->{steps} }) {
    $self->emit($self->c(title => $s->{from_label}), ' -> ', $self->c(title => $s->{to_label}), "\n");
    $self->emit('  ', $self->c(meta => 'backup:  '), $s->{backup_label},
      $self->c(meta => ' ('.$s->{from_label}.' is renamed to it)'), "\n");
    my $lines = $s->{lines}.' line'.( $s->{lines} == 1 ? '' : 's' );
    my $content = $s->{rewritten} ? 'rewritten from the parsed YAML, comments and layout are not kept'
      : @{ $s->{removed_lines} } ? 'copied without its api_key line'.( @{ $s->{removed_lines} } == 1 ? ' ' : 's ' )
          .join(', ', @{ $s->{removed_lines} }).' ('.$lines.' left)'
      : 'copied unchanged ('.$lines.')';
    $self->emit('  ', $self->c(meta => 'content: '), $content, "\n");
    $self->emit('  ', $self->c(warn => 'not copied: api_key in '.join(', ', map { $self->_layer_name($_) } @{ $s->{api_keys} })),
      "\n") if @{ $s->{api_keys} };
    if ($s->{rewritten}) {
      my $text = $s->{bytes};
      utf8::decode($text);
      $self->emit('    ', $self->c(meta => '| '), $_, "\n") for split /\n/, $text;
    }
  }
  $self->emit($self->c(meta => 'creates .raider/.gitignore (sessions/, lib/)'), "\n") if $plan->{gitignore};
  if (my @keyed = grep { @{ $_->{api_keys} } } @{ $plan->{steps} }) {
    $self->emit($self->c(warn => 'api_key is not copied: .raider/config.yml is meant to be shared, and a project'
      .' must not choose a secret. Put the key into ~/.raider/config.yml (same place) or the engine\'s'
      .' *_API_KEY environment variable. '.join(', ', map { $_->{backup_label} } @keyed)
      .' still holds it: delete the backup once the key is moved.'), "\n");
  }
  $self->emit($self->c(meta => 'dry run: nothing written'), "\n") if $opt{dry_run};
  return;
}

# A layer of Config::explain as the user reads it.
sub _layer_name {
  my ( $self, $layer ) = @_;
  return $layer eq 'top' ? 'the top level' : $layer.':';
}


sub migrate_done {
  my ( $self, @results ) = @_;
  for my $r (grep { !$_->{error} && !$_->{skipped} } @results) {
    my $s = $r->{step};
    $self->emit('migrated ', $self->c(title => $s->{from_label}), ' -> ', $self->c(title => $s->{to_label}),
      $self->c(meta => ' (backup '.$s->{backup_label}.')'), "\n");
  }
  return;
}


sub pack_reason {
  my ( $self, $p, %opt ) = @_;
  my $d = $p->{detection};
  my $text = defined $p->{source} ? $p->{source}.( defined $p->{reason} ? ': '.$p->{reason} : '' )
           : $d                   ? $d->{result}.': '.$d->{reason}
           :                        '';
  $text .= ' [rule: '.$d->{rule_from}.']'
    if $opt{rule} && $d && ( !defined $p->{source} || $p->{source} eq 'detected' );
  return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Output - Internal terminal renderer of the raider CLI

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $out = Langertha::Raider::CLI::Output->new;

    $out->say_meta('history cleared.');
    $out->say_error('something failed');
    $out->say_agent($result);
    $out->config_report($app->explain_config);

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Everything the F<raider> CLI prints for a human goes through here: the
blue/yellow palette, the agent/meta/error lines, the C<raider config
explain> report and the C<raider config migrate> report. The machine output (C<--json> and friends) is
L<Langertha::Raider::CLI::Machine>.

=head2 out

Filehandle everything is printed to. Defaults to C<STDOUT>.

=head2 color

Whether to emit ANSI colors. Defaults to true when L</out> is a terminal;
C<ANSI_COLORS_DISABLED> switches them off as well.

=head2 c

    my $text = $out->c(meta => 'some', ' text');

The text in the palette color C<meta>, C<title>, C<agent>, ... -- plain
when L</color> is off.

=head2 emit

Prints its arguments to L</out>.

=head2 say_agent

One line of agent output, inline C<`code`> highlighted.

=head2 say_meta

One line of meta information.

=head2 say_error

An C<error:> line.

=head2 error_text

    my $text = $out->error_text($@);

An exception as one line for the user: without the trailing newline and
the Perl source location C<croak> appends, also the form Moose adds for a
constructor or accessor.

=head2 render_inline_code

Wraps C<`...`> spans in a darker background when colors are on. Triple
backticks stay untouched so fenced code blocks keep their own flow.

=head2 config_report

Prints a report of L<Langertha::Raider::Application/explain_config>: the
config file in use and any config file ignored next to it (a legacy
F<.raider.yml> beside F<.raider/config.yml>); the home file
F<~/.raider/config.yml> when it is loaded; one line per
setting with its value, source, what it was merged with, what it overrides
and whether it applies to the engine or to raider; the instructions source (C<-M>,
C<.raider/instructions.md>, C<.raider.md>, C<default>) with C<(bare)> under
C<--bare>, and any instructions file ignored next to the one in use (a
legacy F<.raider.md> beside F<.raider/instructions.md>); the layout mode
(ADR 0019) with what decided it and whether the Claude layout is read, and
each memory file with its scope and imports; each pack with its state, the
kind of place it was found in (C<project>, C<home>, C<shipped>, C<env>)
and why it is on or off; the pack directories that were skipped, and why; the perl tools grant; and
each mounted tool with its source and effect classes; the permission policy
(L</permissions_report>) (C<unknown> for a tool
the built-in table does not know); each skill with its state (C<listed>,
or C<hidden> for C<disable-model-invocation>) and root, the shadowed skills
and the broken skill files; each agent (ADR 0020) with its root, its tools
in raider names (C<*> for all of the caller's), the disallowed ones, the
model it would get or why it inherits, its declared skills (marked with
the skilletor source of those found there) and those that do not resolve,
each with the reason a resolver gives (the agent tool would refuse it), the tool names
and frontmatter keys raider does not use, then the shadowed agents and the
files in an agent root that are not agents; in the Claude layout the settings -- each file
(read, not present, or its error), the permission rule counts and default
mode, the names of the C<env> keys (never their values), the hook events
with their group counts, the enabled plugins and the keys raider does not
use -- and the plugins whose skills are offered; and, when F<~/.raider/config.yml> has a
C<project_tools>, each of its selectors (matched or not, and why) and each
tool name with the selectors granting it, the packs requesting it and
whether raider knows it -- information only; and, when the home file has
stored provider aliases (C<providers:>), each with origin, auth types,
credential variable name and whether an internal address is allowed.

=head2 permissions_report

    $out->permissions_report( $app->permissions->report );

Prints the permission policy (L<Langertha::Raider::Permissions/report>):
the mode and where it came from, ignored mode names, per kind the number of
rules by source (with C<rules =E<gt> 1> each rule), the invalid rules and
the additional directories. Part of L</config_report>; the REPL's
C</permissions> prints it with every rule.

=head2 mcp_report

    $out->mcp_report( $app->mcp_report );
    $out->mcp_report( $app->mcp_report, tools => 1 );   # /mcp

Prints the configured MCP servers (ADR 0029,
L<Langertha::Raider::Application/mcp_report>): per server its name and
status in Claude Code's words (C<connected>, C<failed>, C<pending
approval>, C<rejected>, C<disabled>, C<unsupported>, C<not configured>,
C<invalid>, C<configured> before the start), scope, transport and source,
the reason, the approval and where it came from, warnings, shadowed
entries; for a failed server its last stderr lines. With C<tools> each
server's tools too. Then the files that could not be read, the timeouts,
whether the folder is trusted and where answers are written. Part of
L</config_report>; the REPL's C</mcp> prints it with the tools.

=head2 migrate_report

    $out->migrate_report($plan, dry_run => 1);

Prints what C<raider config migrate> does, from a
L<Langertha::Raider::Config::Migrate/plan> that was not refused: per
legacy file its new file, its backup and whether the content changes --
copied unchanged, without the C<api_key> lines (their line numbers), or
rewritten (then the new content follows, it holds no C<api_key>) -- and
where an C<api_key> was left out; whether F<.raider/.gitignore> is
created; with C<dry_run> that nothing was written. Never prints the value
of an C<api_key>.

=head2 migrate_done

    $out->migrate_done(@results);

One line per step of L<Langertha::Raider::Config::Migrate/apply> that was
done: C<migrated FROM -E<gt> TO (backup BACKUP)>. Failed and skipped
steps are the caller's to report.

=head2 pack_reason

    my $text = $out->pack_reason($entry, rule => 1);

Why a pack of L<Langertha::Raider::Packs::Collection/activation_report> is
on or off: C<SOURCE: REASON> (C<detected: must file=cpanfile (cpanfile)>,
C<flag: --no-pack>), or the detection outcome of an inactive pack
(C<not matched: ...>). With C<rule> the origin of a detection rule is
appended (C<[rule: pack default]>).

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
