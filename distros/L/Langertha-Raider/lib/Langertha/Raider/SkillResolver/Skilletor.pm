package Langertha::Raider::SkillResolver::Skilletor;
# ABSTRACT: Internal skill resolver over the sources of skilletor.json, read without installing
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Scalar::Util qw( blessed );
use Skilletor;
use Skilletor::Config;


has home => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has project_dir => (
  is  => 'ro',
  isa => 'Maybe[Str]',
);

has fetch => (
  is      => 'ro',
  isa     => 'Str',
  default => 'missing',
);


has skilletor => (
  is         => 'ro',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_skilletor {
  my ( $self ) = @_;
  return $self->skilletor_class->new(
    home  => $self->home,
    fetch => $self->fetch,
    ( defined $self->project_dir ? ( project_dir => $self->project_dir ) : () ),
  );
}


sub skilletor_class { 'Skilletor' }

# Per name: { rec } when it resolved, { reason } (maybe undef) when not.
has _answers => ( is => 'ro', isa => 'HashRef', init_arg => undef, default => sub { {} } );

# An error that broke the whole resolution (config, lock): every name gets it.
has _failure => ( is => 'rw', init_arg => undef );


sub config_files {
  my ( $self ) = @_;
  my @files = ( path($self->home)->child('.claude', 'skilletor.json') );
  push @files, map { path($self->project_dir)->child('.claude', $_) } qw( skilletor.json skilletor.local.json )
    if defined $self->project_dir;
  return map { $_->stringify } grep { -f $_ } @files;
}

sub has_config { scalar( () = $_[0]->config_files ) ? 1 : 0 }


sub resolve {
  my ( $self, $name ) = @_;
  my $answer = $self->_answer($name) or return;
  my $rec = $answer->{rec} or return;
  return { name => $name, dir => $rec->{dir}, file => $rec->{file}, via => 'skilletor:'.$rec->{source} };
}


sub why_unresolved {
  my ( $self, $name ) = @_;
  my $answer = $self->_answer($name) or return;
  return if $answer->{rec};
  return $answer->{reason};
}

sub _answer {
  my ( $self, $name ) = @_;
  return unless defined $name && length $name;
  return unless $self->has_config;
  return $self->_answers->{$name} //= $self->_lookup($name);
}

sub _lookup {
  my ( $self, $name ) = @_;
  return { reason => $self->_failure } if defined $self->_failure;
  my $rec = eval { $self->skilletor->resolve_item( skill => $name ) };
  if ( my $error = $@ ) {
    $self->_failure( 'skilletor: '.$self->_one_line($error) );
    return { reason => $self->_failure };
  }
  if ( $rec ) {
    return { reason => 'skilletor: '.$rec->{name}.'@'.$rec->{source}.' is a template; templates are not supported in Perl' }
      if $rec->{templated};
    return { rec => $rec };
  }
  return { reason => scalar $self->_reason_for($name) };
}

# What the resolution says about a declared name that did not resolve: a
# warning naming the skill, else the trust request or a warning of the source
# that declares it.
sub _reason_for {
  my ( $self, $name ) = @_;
  my $report = $self->_report or return;
  return 'skilletor: '.$report->{error} if defined $report->{error};
  my @scopes = @{ $report->{scopes} // [] };
  my @warnings = map { @{ $_->{warnings} // [] } } @scopes;
  my $lc = lc $name;
  for my $w (@warnings) {
    return 'skilletor: '.$w if $w =~ /\bskill \Q$lc\E(?:\@|\z)/i;
  }
  for my $source ($self->_declaring_sources($name)) {
    for my $t (map { @{ $_->{trustRequests} // [] } } @scopes) {
      return 'skilletor: source "'.$source.'" is not trusted -- run: skilletor trust '.$source
        if $t->{name} eq $source;
    }
    for my $w (@warnings) {
      return 'skilletor: '.$w if index($w, 'source '.$source.': ') == 0;
    }
  }
  return;
}

has _report => ( is => 'ro', init_arg => undef, lazy_build => 1 );

sub _build__report {
  my ( $self ) = @_;
  return scalar eval { $self->skilletor->resolve( scope => 'all' ) };
}

# The sources of the skill entries of that name in the config files.
sub _declaring_sources {
  my ( $self, $name ) = @_;
  my $config = eval {
    Skilletor::Config->load( home => $self->home,
      ( defined $self->project_dir ? ( project_dir => $self->project_dir ) : () ) );
  } or return;
  my %seen;
  return grep { !$seen{$_}++ }
    map { $_->{source} }
    grep { ( $_->{type} // '' ) eq 'skill' && lc( $_->{name} // '' ) eq lc $name }
    map { @{ ( $_ // {} )->{install} // [] } } scalar eval { $config->user }, scalar eval { $config->project };
}

sub _one_line {
  my ( $self, $error ) = @_;
  my $text = blessed $error && $error->can('message') ? $error->message : "$error";
  ( $text ) = split /\n/, $text;
  $text //= '';
  $text =~ s/ at \S+ line \d+\.?\z//;
  return $text;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::SkillResolver::Skilletor - Internal skill resolver over the sources of skilletor.json, read without installing

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $r = Langertha::Raider::SkillResolver::Skilletor->new(
      home        => $context->home,
      project_dir => $context->layout->project_dir->stringify,
    );
    my $skill = $r->resolve('perl-moo');
    # { name => 'perl-moo', dir => '.../cache/<hash>/skills/perl-moo',
    #   file => '.../SKILL.md', via => 'skilletor:shared' }  or undef
    my $why = $r->why_unresolved('perl-moo');   # 'skilletor: ...' or undef

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The second resolver of L<Langertha::Raider::SkillResolver> (ADR 0020
E<sect>6), asked only for the names the skill catalogue does not know: a
skill one of the F<skilletor.json> files declares -- C<~/.claude/skilletor.json>,
the project's F<.claude/skilletor.json> and F<.claude/skilletor.local.json> --
read straight from its source through L<Skilletor/resolve_item>, without
installing it. The directory is the C<local> source's own or the shared
cache (F<~/.claude/skilletor/cache/E<lt>hashE<gt>/...>) the skilletor CLI
fills too.

=over

=item * B<Lazy.> Without any of the three files nothing happens -- no
L<Skilletor> object, no lock, nothing written under the home. The object
is built at the first name the catalogue misses and answers every later
name from the same resolution.

=item * B<Fetching> is L</fetch>, C<missing> by default: a source is
fetched (git, an https tarball) the first time a skill of it is needed and
served from the shared cache afterwards, so a spawn does not touch the
network each time.

=item * B<Never fatal.> A templated skill (C<.njk>, which the Perl port
does not render), a config error, a source that cannot be fetched or is
not trusted yet: the name does not resolve, and L</why_unresolved> says
why, prefixed C<skilletor:>. The briefing's refusal carries that reason.

=back

Skilletor finds its files under C<home>/F<.claude> -- as the skilletor CLI
does, C<$CLAUDE_CONFIG_DIR> is not consulted.

=head2 home

The user's home directory. Required.

=head2 project_dir

The project directory (where F<.claude/> lies), or C<undef> for the user
scope alone.

=head2 fetch

Skilletor's fetch policy: C<missing> (default), C<always> or C<never>.

=head2 skilletor

The L<Skilletor> object, built on first use (L</skilletor_class>).

=head2 skilletor_class

C<Skilletor>.

=head2 config_files

The F<skilletor.json> files that exist, as strings.

=head2 has_config

True when L</config_files> names one: only then is L<Skilletor> asked.

=head2 resolve

    my $skill = $r->resolve('perl-moo');

C<< { name, dir, file, via } >> -- C<via> is C<skilletor:E<lt>sourceE<gt>>
-- of the skill a F<skilletor.json> declares under that name, or C<undef>.

=head2 why_unresolved

    my $reason = $r->why_unresolved('tpl');
    # 'skilletor: tpl@shared is a template; templates are not supported in Perl'

Why a name a F<skilletor.json> declares (or that broke the lookup) does not
resolve, or C<undef> when there is nothing to say -- no config, or a name
nobody declares.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::SkillResolver>

=item * L<Skilletor>

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
