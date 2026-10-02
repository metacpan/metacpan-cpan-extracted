package Langertha::Raider::CLI::Commands;
# ABSTRACT: Internal slash commands of the raider REPL
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use utf8;
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
  my ( $self, $line ) = @_;
  my ( $cmd, @rest ) = split /\s+/, $line;
  $cmd =~ s{^/}{};
  my $method = 'cmd_'.($cmd =~ tr/-/_/r);
  unless ($self->can($method)) {
    $self->output->say_error('unknown command: /'.$cmd.' (try /help)');
    return 0;
  }
  $self->$method(join ' ', @rest);
  return 1;
}

sub cmd_help {
  my ($self) = @_;
  $self->output->say_meta($_) for (
    'commands:',
    '  /help                 show this help',
    '  /clear                reset conversation history',
    '  /metrics              show cumulative raid metrics',
    '  /stats                show token usage (when trace is on)',
    '  /reload               reload the instructions file, re-detect packs',
    '  /prompt               launch the prompt-builder (edits the instructions file)',
    '  /skill [PATH]         export plain-markdown skill doc',
    '  /skill-claude [PATH]  export Claude Code SKILL.md with frontmatter',
    '  /config               show each setting and where it came from',
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
  return;
}

sub cmd_clear {
  my ($self) = @_;
  my $app = $self->app;
  $app->raider->clear_history;
  my $t = $app->trace_plugin;
  $t->token_stats({ prompt => 0, completion => 0, total => 0, calls => 0 }) if $t;
  $self->output->say_meta('history cleared.');
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
  my $s = $self->app->token_stats;
  return $self->output->say_meta('stats unavailable (trace is off — start without --no-trace).')
    unless $s;
  $self->output->say_meta(sprintf(
    'llm calls: %d | tokens in: %d | out: %d | total: %d',
    $s->{calls}, $s->{prompt}, $s->{completion}, $s->{total},
  ));
  return;
}

sub cmd_reload {
  my ($self) = @_;
  my $app = $self->app;
  my @detected = $app->redetect_packs;
  my $new = $app->reload_mission;
  my $source = $app->mission_source;
  my $file   = $app->instructions->label;
  my $status = $source eq '-M'  ? '-M mission kept, '.$file.' not used'
             : $source eq $file ? 'custom ('.$file.' loaded)'
             :                    'Langertha (default, no '.$file.')';
  $self->output->say_meta('mission reloaded: '.$status.' ('.length($new).' chars)');
  $self->output->say_meta('detected packs: '.join(', ', @detected)) if @detected;
  return;
}

sub cmd_prompt {
  my ($self) = @_;
  $self->prompt_builder_class->new(app => $self->app, output => $self->output, in => $self->in)->run;
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::CLI::Commands - Internal slash commands of the raider REPL

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $commands = Langertha::Raider::CLI::Commands->new(app => $app, output => $out);
    $commands->dispatch('/pack on polite');

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The slash commands of the F<raider> REPL (C</help>, C</clear>, C</metrics>,
C</stats>, C</reload>, C</prompt>, C</skill>, C</skill-claude>, C</config>,
C</model>, C</packs>, C</pack>). Each command C</name> is the method
C<cmd_name> (dashes become underscores) and gets the rest of the line as
its argument. Leaving the REPL (C</quit>) is the REPL's business.

=head2 app

The L<Langertha::Raider::CLI> the commands act on. Required.

=head2 output

The L<Langertha::Raider::CLI::Output> to print to. Required.

=head2 in

Filehandle C</prompt> reads its conversation from. Defaults to C<STDIN>.

=head2 dispatch

    $commands->dispatch('/model list gpt');

Runs one slash command line. Returns false for an unknown command (after
saying so), true otherwise.

=head2 collapse_model_list

    my @rows = $commands->collapse_model_list(\@ids, $current);

Folds dated snapshots (C<gpt-4o-2024-08-06>, C<claude-3-5-sonnet-20241022>
style C<-YYYY> suffixes) under their base model. Returns sorted rows
C<{ id, snaps, current, orphan }>; C<orphan> marks a snapshot family whose
base is not listed itself.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::CLI>

=back

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
