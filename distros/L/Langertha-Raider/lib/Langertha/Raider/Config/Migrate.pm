package Langertha::Raider::Config::Migrate;
# ABSTRACT: Internal converter of the legacy project files to .raider/ (raider config migrate)
our $VERSION = '0.503';
use Moose;
use namespace::autoclean;
use Carp qw( croak );
use Path::Tiny;
use Langertha::Raider::Config;
use Langertha::Raider::Home;
use Langertha::Raider::Instructions;
use Langertha::Raider::SessionStore;


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

sub config_class        { 'Langertha::Raider::Config' }
sub home_class          { 'Langertha::Raider::Home' }
sub instructions_class  { 'Langertha::Raider::Instructions' }
sub session_store_class { 'Langertha::Raider::SessionStore' }


has config => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build_config { $_[0]->config_class->new(root => $_[0]->root) }

has instructions => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build_instructions { $_[0]->instructions_class->new(root => $_[0]->root) }


sub backup_suffix { '.bak' }


sub plan {
  my ( $self ) = @_;
  my $root = path($self->root)->absolute;
  my ( @steps, @refused );
  my $config = $self->config;
  if (-f $config->legacy_file) {
    my $m = $config->migration_content;
    my $bytes = $m->{text};
    utf8::encode($bytes);
    push @steps, $self->_step(config => $config->legacy_file, $config->native_file, $bytes,
      changed       => ( $m->{rewritten} || @{ $m->{removed_lines} } ) ? 1 : 0,
      api_keys      => $m->{api_keys},
      removed_lines => $m->{removed_lines},
      rewritten     => $m->{rewritten},
    );
  }
  my $instructions = $self->instructions;
  if (-f $instructions->legacy_file) {
    push @steps, $self->_step(instructions => $instructions->legacy_file, $instructions->native_file,
      $instructions->legacy_file->slurp_raw, changed => 0, api_keys => [], removed_lines => [], rewritten => 0);
  }

  my $base = $self->home_class->project_base($root);
  if (@steps) {
    my $home = $self->home_class->home_dir;
    push @refused, $root.' is the home directory: there .raider/config.yml is the home config of every'
      .' project, not this one\'s; move ~/.raider.yml and ~/.raider.md by hand if that is what you want'
      if defined $home && -d $home && -d $root && path($home)->realpath eq $root->realpath;
    push @refused, '.raider exists and is not a directory' if -e $base && !-d $base;
  }
  for my $step (@steps) {
    push @refused, $step->{to_label}.' already exists next to '.$step->{from_label}.': nothing is merged;'
      .' move what you need into '.$step->{to_label}.' by hand and remove '.$step->{from_label}
      .' (raider config explain shows which file is read)'
      if -e $step->{to};
    push @refused, $step->{backup_label}.' already exists: move it away first, '
      .$step->{from_label}.' is kept as '.$step->{backup_label}
      if -e $step->{backup};
  }
  return {
    root      => $root->stringify,
    steps     => \@steps,
    refused   => \@refused,
    gitignore => ( @steps && !-e $base->child('.gitignore') ) ? 1 : 0,
  };
}

sub _step {
  my ( $self, $kind, $from, $to, $bytes, %info ) = @_;
  my $root = path($self->root)->absolute;
  my $backup = path($from.$self->backup_suffix);
  return {
    kind         => $kind,
    from         => $from,
    to           => $to,
    backup       => $backup,
    from_label   => $from->relative($root)->stringify,
    to_label     => $to->relative($root)->stringify,
    backup_label => $backup->relative($root)->stringify,
    bytes        => $bytes,
    lines        => scalar( () = $bytes =~ /\n/g ) + ( length $bytes && $bytes !~ /\n\z/ ? 1 : 0 ),
    %info,
  };
}


sub apply {
  my ( $self, $plan ) = @_;
  croak __PACKAGE__.'->apply: the migration was refused: '.join('; ', @{ $plan->{refused} })
    if @{ $plan->{refused} };
  my @steps = @{ $plan->{steps} };
  return unless @steps;
  my @results;
  unless (eval { $self->session_store_class->new(root => $self->root)->prepare_base; 1 }) {
    my $error = $@;
    return ( { step => shift(@steps), error => $error }, map { { step => $_, skipped => 1 } } @steps );
  }
  while (my $step = shift @steps) {
    if (eval { $self->_apply_step($step); 1 }) {
      push @results, { step => $step };
      next;
    }
    push @results, { step => $step, error => $@ }, map { { step => $_, skipped => 1 } } @steps;
    last;
  }
  return @results;
}

# One step: the new file through a temporary file next to it, then the
# legacy file renamed to its backup. When that rename fails, the new file
# goes again, so the legacy file stays the one in use.
sub _apply_step {
  my ( $self, $step ) = @_;
  # Checked again: a rename would replace a file that appeared since plan.
  croak $step->{to_label}.' already exists' if -e $step->{to};
  croak $step->{backup_label}.' already exists' if -e $step->{backup};
  my $tmp = $step->{to}->parent->tempfile('.'.$step->{to}->basename.'.XXXXXX');
  $tmp->spew_raw($step->{bytes});
  chmod( (stat $step->{from})[2] & 07777, $tmp );
  $self->_move($tmp, $step->{to});
  unless (eval { $self->_move($step->{from}, $step->{backup}); 1 }) {
    my $error = $@;
    $step->{to}->remove;
    croak $error;
  }
  return;
}

sub _move {
  my ( $self, $from, $to ) = @_;
  $from->move($to);
  return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Config::Migrate - Internal converter of the legacy project files to .raider/ (raider config migrate)

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $migrate = Langertha::Raider::Config::Migrate->new(root => $root);
    my $plan = $migrate->plan;            # croaks when .raider.yml does not parse
    die join "\n", @{ $plan->{refused} } if @{ $plan->{refused} };
    for my $result ($migrate->apply($plan)) {
      warn $result->{step}{from_label}.': '.$result->{error} if $result->{error};
    }

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

What C<raider config migrate> does (ADR 0011): the legacy project files of
L</root> move to the F<.raider/> layout,

=over

=item F<.raider.yml> to F<.raider/config.yml>, without any C<api_key>
(L<Langertha::Raider::Config/migration_content>): that file is meant to be
shared, and a project must not choose a secret;

=item F<.raider.md> to F<.raider/instructions.md>, byte for byte.

=back

Each legacy file that exists is one step. A step writes the new file
atomically (a temporary file next to it, renamed into place, with the
legacy file's permissions), then renames the legacy file to its backup
(F<.raider.yml.bak>, F<.raider.md.bak>), so afterwards only the new file
is read and the effective config is the same (minus the C<api_key>). A
step that fails leaves its legacy file in use and no new file behind.
F<.raider/> is created through
L<Langertha::Raider::SessionStore/prepare_base>, which also writes its
F<.gitignore>.

Nothing is merged: L</plan> refuses the whole migration, before anything
is written, when a new file or a backup already exists, when F<.raider>
is not a directory, or when L</root> is the home directory (there
F<.raider/config.yml> would be the home config of every project).

=head2 root

The project directory. Required.

=head2 config

The L<Langertha::Raider::Config> of L</root>.

=head2 instructions

The L<Langertha::Raider::Instructions> of L</root>.

=head2 backup_suffix

C<.bak>: the backup of F<.raider.yml> is F<.raider.yml.bak>.

=head2 plan

    my $plan = $migrate->plan;
    # { root      => '/abs/project',
    #   steps     => [ { kind => 'config', from => $path, to => $path, backup => $path,
    #                    from_label => '.raider.yml', to_label => '.raider/config.yml',
    #                    backup_label => '.raider.yml.bak', bytes => '...', lines => 12,
    #                    changed => 1, api_keys => ['top'], removed_lines => [3],
    #                    rewritten => 0 },
    #                  { kind => 'instructions', ... } ],
    #   refused   => [ 'reason', ... ],
    #   gitignore => 1 }

What a migration of L</root> would do, without touching the disk:
C<steps> in order (the config first), C<refused> the reasons it cannot be
done (then nothing may be written), C<gitignore> whether
F<.raider/.gitignore> would be created. C<changed> is false when the new
file is the legacy file byte for byte. Croaks like
L<Langertha::Raider::Config/data> when F<.raider.yml> does not parse.

=head2 apply

    my @results = $migrate->apply($plan);
    # ( { step => $step }, { step => $step, error => '...' }, { step => $step, skipped => 1 } )

Carries out a L</plan>: creates F<.raider/> and its F<.gitignore>, then
the steps in order. Stops at the first step that fails; that step's
result carries C<error> (its legacy file is still in use, its new file is
not there), the steps after it C<skipped>. Croaks, writing nothing, when
the plan was refused.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Config>

=item * L<Langertha::Raider::Instructions>

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
