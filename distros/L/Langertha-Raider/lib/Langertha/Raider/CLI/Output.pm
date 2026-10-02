package Langertha::Raider::CLI::Output;
# ABSTRACT: Internal terminal renderer of the raider CLI
our $VERSION = '0.503';
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
  if (my $tools = $report->{tools}) {
    $self->emit($self->c(meta => 'tools:  '), $self->c(meta => '(what a tool can do: information only)'), "\n");
    for my $t (@$tools) {
      my $fx = $t->{effects};
      $self->emit(sprintf("  %s %-10s  %s\n", $self->c(title => sprintf('%-22s', $t->{name})), $t->{source},
        $self->c(meta => !$fx ? 'unknown' : @$fx ? join(', ', @$fx) : 'none')));
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

version 0.503

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
legacy F<.raider.md> beside F<.raider/instructions.md>); each pack with its state, the
kind of place it was found in (C<project>, C<home>, C<shipped>, C<env>)
and why it is on or off; the pack directories that were skipped, and why; the perl tools grant; and
each mounted tool with its source and effect classes (C<unknown> for a tool
the built-in table does not know); and, when F<~/.raider/config.yml> has a
C<project_tools>, each of its selectors (matched or not, and why) and each
tool name with the selectors granting it, the packs requesting it and
whether raider knows it -- information only.

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
