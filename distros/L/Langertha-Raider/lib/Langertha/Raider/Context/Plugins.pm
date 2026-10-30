package Langertha::Raider::Context::Plugins;
# ABSTRACT: Internal resolver of the installed and enabled Claude Code plugins
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use JSON::MaybeXS ();
use Path::Tiny;
use Langertha::Raider::Home;


has cwd => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has claude_home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub home_class { 'Langertha::Raider::Home' }

sub _build_claude_home {
  my ( $self ) = @_;
  my $dir = $self->home_class->claude_home;
  return defined $dir ? $dir->stringify : undef;
}


has enabled => (
  is       => 'ro',
  isa      => 'HashRef',
  required => 1,
);


has plugins => (
  is         => 'ro',
  isa        => 'ArrayRef',
  init_arg   => undef,
  lazy_build => 1,
);

sub _build_plugins {
  my ( $self ) = @_;
  my $home = $self->claude_home;
  return [] unless defined $home;
  my $index = $self->_load_json(path($home)->child('plugins', 'installed_plugins.json'));
  my $installed = $index->{plugins};
  return [] unless ref $installed eq 'HASH';
  my $enabled = $self->enabled;
  my $cwd = path($self->cwd)->absolute->stringify;

  my @found;
  for my $key (keys %$installed) {
    next unless $enabled->{$key};
    my $entries = $installed->{$key};
    next unless ref $entries eq 'ARRAY';
    for my $e (@$entries) {
      next unless ref $e eq 'HASH';
      my $root = $e->{installPath};
      next unless defined $root && !ref $root;
      my $project = $e->{projectPath};
      if (defined $project && !ref $project && length $project) {
        next unless $self->_within($cwd, $project);
        push @found, [ -length($project), $key, $root, 'project' ];
      }
      else {
        push @found, [ 0, $key, $root, 'user' ];
      }
    }
  }

  # One install per key, as Claude Code loads it: the first in this order.
  my ( @out, %seen );
  for my $f (sort { $a->[0] <=> $b->[0] || $a->[1] cmp $b->[1] || $a->[2] cmp $b->[2] } @found) {
    my ( undef, $key, $root, $scope ) = @$f;
    next if $seen{$key}++;
    my $manifest = $self->_load_json(path($root)->child('.claude-plugin', 'plugin.json'));
    my $name = $manifest->{name};
    $name = ( split /\@/, $key, 2 )[0] unless defined $name && !ref $name;
    push @out, {
      name     => $name,
      key      => $key,
      root     => $root,
      manifest => $manifest,
      scope    => $scope,
    };
  }
  return \@out;
}


sub skill_dirs {
  my ( $self, $plugin ) = @_;
  my $root = $self->_normpath($plugin->{root});
  my $extra = $plugin->{manifest}{skills};
  $extra = [ $extra ] if defined $extra && !ref $extra;
  my @bases = ( $root.'/skills' );
  push @bases, map { $self->_normpath( m{\A/} ? $_ : $root.'/'.$_ ) }
    grep { defined && !ref } @$extra
    if ref $extra eq 'ARRAY';

  my ( @dirs, %seen );
  for my $base (@bases) {
    next unless $self->_within($base, $root);
    my @found;
    if (-f $base.'/SKILL.md') {
      @found = ( $base );
    }
    elsif (-d $base) {
      @found = grep { -f $_.'/SKILL.md' } map { $base.'/'.$_->basename } sort { $a->basename cmp $b->basename } path($base)->children;
    }
    push @dirs, grep { !$seen{$_}++ } @found;
  }
  return @dirs;
}


sub data_dir {
  my ( $self, $plugin ) = @_;
  my $home = $self->claude_home;
  return unless defined $home;
  ( my $id = $plugin->{key} ) =~ s/[^A-Za-z0-9_-]/-/g;
  return path($home)->child('plugins', 'data', $id)->stringify;
}


sub hooks {
  my ( $self, $plugin ) = @_;
  my $root = $self->_normpath($plugin->{root});
  my $label = 'plugin:'.$plugin->{name};
  my ( %groups, @errors, %seen );

  my $add = sub {
    my ( $map ) = @_;
    for my $event (sort keys %$map) {
      my $list = $map->{$event};
      next unless ref $list eq 'ARRAY';
      for my $g (grep { ref $_ eq 'HASH' } @$list) {
        push @{ $groups{$event} }, {
          matcher => defined $g->{matcher} && !ref $g->{matcher} ? $g->{matcher} : undef,
          hooks   => ref $g->{hooks} eq 'ARRAY' ? $g->{hooks} : [],
          source  => $label,
        };
      }
    }
  };
  my $file = sub {
    my ( $rel, $optional ) = @_;
    my $abs = $self->_normpath( $rel =~ m{\A/} ? $rel : $root.'/'.$rel );
    unless ($self->_within($abs, $root)) {
      push @errors, $label.': '.$rel.' is outside the plugin';
      return;
    }
    return if $optional && !-e $abs;
    return if $seen{$abs}++;
    my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode(path($abs)->slurp_raw) };
    if (ref $data eq 'HASH' && ref $data->{hooks} eq 'HASH') {
      $add->($data->{hooks});
    }
    else {
      push @errors, $label.': '.$rel.' has no "hooks" object'.( $@ ? ' (invalid JSON)' : '' );
    }
  };

  $file->('hooks/hooks.json', 1);
  my $declared = $plugin->{manifest}{hooks};
  for my $item (ref $declared eq 'ARRAY' ? @$declared : defined $declared ? ($declared) : ()) {
    if (ref $item eq 'HASH')  { $add->($item) }
    elsif (!ref $item)        { $file->($item, 0) }
  }
  return ( \%groups, \@errors );
}


sub agent_dirs {
  my ( $self, $plugin ) = @_;
  return $self->_md_paths($plugin, 'agents');
}


sub command_dirs {
  my ( $self, $plugin ) = @_;
  return $self->_md_paths($plugin, 'commands');
}

# The default directory $key/ of a plugin, then the manifest's $key paths:
# those that exist inside the plugin root as a directory or an *.md file.
sub _md_paths {
  my ( $self, $plugin, $key ) = @_;
  my $root = $self->_normpath($plugin->{root});
  my $extra = $plugin->{manifest}{$key};
  $extra = [ $extra ] if defined $extra && !ref $extra;
  my @paths = ( $root.'/'.$key );
  push @paths, map { $self->_normpath( m{\A/} ? $_ : $root.'/'.$_ ) }
    grep { defined && !ref } @$extra
    if ref $extra eq 'ARRAY';
  my %seen;
  return grep { !$seen{$_}++ && $self->_within($_, $root) && ( -d $_ || ( -f $_ && /\.md\z/ ) ) } @paths;
}


sub mcp_servers {
  my ( $self, $plugin ) = @_;
  my $root = $self->_normpath($plugin->{root});
  my $label = 'plugin:'.$plugin->{name};
  my ( %servers, @errors, %seen );

  my $add = sub {
    my ( $map, $where ) = @_;
    $servers{$_} = { name => $_, entry => $map->{$_}, source => $label.' ('.$where.')' } for keys %$map;
  };
  my $file = sub {
    my ( $rel, $optional ) = @_;
    my $abs = $self->_normpath( $rel =~ m{\A/} ? $rel : $root.'/'.$rel );
    unless ($self->_within($abs, $root)) {
      push @errors, $label.': '.$rel.' is outside the plugin';
      return;
    }
    unless (-e $abs) {
      push @errors, $label.': '.$rel.' does not exist' unless $optional;
      return;
    }
    return if $seen{$abs}++;
    my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode(path($abs)->slurp_raw) };
    my $where = path($abs)->relative($root)->stringify;
    if (ref $data ne 'HASH') {
      push @errors, $label.': '.$rel.' is not a JSON object'.( $@ ? ' (invalid JSON)' : '' );
    }
    elsif (exists $data->{mcpServers}) {
      if (ref $data->{mcpServers} eq 'HASH') { $add->($data->{mcpServers}, $where) }
      else { push @errors, $label.': '.$rel.' has an "mcpServers" that is not an object' }
    }
    else {
      $add->($data, $where);
    }
  };

  $file->('.mcp.json', 1);
  my $declared = $plugin->{manifest}{mcpServers};
  for my $item (ref $declared eq 'ARRAY' ? @$declared : defined $declared ? ($declared) : ()) {
    if (ref $item eq 'HASH') { $add->($item, 'plugin.json') }
    elsif (!ref $item)       { $file->($item, 0) }
    else                     { push @errors, $label.': plugin.json mcpServers holds neither a path nor an object' }
  }
  return ( [ map { $servers{$_} } sort keys %servers ], \@errors );
}

# A JSON object from a file, {} when it is missing, broken or not an object.
sub _load_json {
  my ( $self, $file ) = @_;
  return {} unless -f $file;
  my $data = eval { JSON::MaybeXS->new( utf8 => 1 )->decode($file->slurp_raw) };
  return ref $data eq 'HASH' ? $data : {};
}

# Lexical path normalisation, as Python's os.path.normpath: absolute against
# the current directory, '.' and empty parts dropped, '..' taken back.
sub _normpath {
  my ( $self, $p ) = @_;
  $p = path($p)->absolute->stringify unless $p =~ m{\A/};
  my @parts;
  for my $part (split m{/+}, $p) {
    next if $part eq '' || $part eq '.';
    if ($part eq '..') { pop @parts; next }
    push @parts, $part;
  }
  return '/'.join('/', @parts);
}

# True when $path is $root or below it, both normalised lexically.
sub _within {
  my ( $self, $path, $root ) = @_;
  $path = $self->_normpath($path);
  $root = $self->_normpath($root);
  return 1 if $path eq $root;
  $root =~ s{/+\z}{};
  return index($path, $root.'/') == 0 ? 1 : 0;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Plugins - Internal resolver of the installed and enabled Claude Code plugins

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $plugins = Langertha::Raider::Context::Plugins->new(
      cwd     => $root,
      enabled => $settings->enabled_plugin_map,
    );
    for my $p (@{ $plugins->plugins }) {
      my @dirs = $plugins->skill_dirs($p);   # each dir holds a SKILL.md
      my @agents = $plugins->agent_dirs($p); # agent dirs and *.md files
      my @commands = $plugins->command_dirs($p);   # command dirs and *.md files
    }

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The Claude Code plugins whose skills raider offers (ADR 0019 §4): every
plugin that is installed B<and> enabled. The logic follows the briefing
hook (C<briefing-preload>: C<claude_plugins>, C<plugin_skill_dirs>), which
mirrors Claude Code:

=over

=item * F<plugins/installed_plugins.json> in L</claude_home> is the index
(version 2: C<< { plugins => { 'name@market' => [ { scope, installPath,
projectPath?, version, ... }, ... ] } } >>), not the cache directory -- the
cache keeps versions that are no longer installed.

=item * A key that L</enabled> does not map to true is skipped: an
installed marketplace plugin is off until C<enabledPlugins> turns it on.

=item * An install with a C<projectPath> counts only when L</cwd> is that
directory or below it. Project installs come first, the deeper
C<projectPath> first; user installs last; ties by key, then install path.

=item * The plugin name is C<name> of F<.claude-plugin/plugin.json> in the
install path, else the key before C<@>.

=back

A missing or invalid F<installed_plugins.json> means no plugins. Paths are
compared lexically (C<..> resolved, symlinks not), as the reference does.

=head2 cwd

The directory raider runs for; compared with each install's
C<projectPath>. Required.

=head2 claude_home

The user's Claude Code directory, by default
L<Langertha::Raider::Home/claude_home>. C<undef> (no home): no plugins.

=head2 enabled

The merged C<enabledPlugins>, C<< { 'name@market' => 0|1 } >> -- usually
L<Langertha::Raider::Context::Settings/enabled_plugin_map>. Required.

=head2 plugins

    for my $p (@{ $plugins->plugins }) {
      say $p->{name}.' ('.$p->{key}.', '.$p->{scope}.') at '.$p->{root};
    }

The installed and enabled plugins in the order described above, each

    {
      name     => 'superpowers',                       # manifest name, else key before '@'
      key      => 'superpowers@claude-plugins-official',
      root     => '/abs/install/path',
      manifest => { ... },                             # .claude-plugin/plugin.json, {} when absent/invalid
      scope    => 'project' | 'user',                  # 'project' when the install has a projectPath
    }

A key installed more than once (user and project) appears once: its first
install in this order (the deepest project install that counts, else the user
install), as Claude Code loads one install per plugin. The others are dropped.

=head2 skill_dirs

    my @dirs = $plugins->skill_dirs($plugin);   # absolute paths as strings

The skill directories Claude Code loads from one entry of L</plugins>: the
default F<skills/E<lt>nameE<gt>/> scan, then each path of the manifest's
C<skills> (a string or a list), resolved against the plugin root. Each
path is either a skill directory itself (it holds F<SKILL.md>) or a
directory of skill directories, scanned sorted by name. A path that leaves
the plugin root is skipped. A directory reached twice is returned once
(the reference yields it twice). Every returned directory holds a
F<SKILL.md>.

=head2 data_dir

    my $dir = $plugins->data_dir($plugin);   # .../plugins/data/briefing-getty

The plugin's persistent data directory, C<${CLAUDE_PLUGIN_DATA}> of its
hooks: F<plugins/data/E<lt>idE<gt>> in L</claude_home>, where the id is the
plugin's key (C<name@market>) with every character other than a letter,
digit, C<_> or C<-> replaced by C<-> -- Claude Code's rule. A string; the
directory is not created here. C<undef> without a L</claude_home>.

=head2 hooks

    my ( $groups, $errors ) = $plugins->hooks($plugin);
    for my $g (@{ $groups->{PreToolUse} // [] }) { ... $g->{matcher}, $g->{hooks}, $g->{source} ... }

The hooks one entry of L</plugins> declares, in the shape of
L<Langertha::Raider::Context::Settings/hooks>, with C<source> set to
C<plugin:E<lt>nameE<gt>>. Claude Code merges two places, in this order:

=over

=item * F<hooks/hooks.json> in the plugin root, the event map under a
top-level C<hooks> key

=item * the manifest's C<hooks>: a path to such a file (relative to the
root), an inline event map, or a list of both

=back

A missing default file is no error. A file that is not valid JSON, has no
C<hooks> object, or a path that leaves the plugin root contributes nothing
(a file named twice counts once)
and is reported in C<$errors> (strings naming the plugin and the file);
never fatal.

=head2 agent_dirs

    my @paths = $plugins->agent_dirs($plugin);   # absolute paths as strings

Where Claude Code finds the agents of one entry of L</plugins> (ADR 0020
E<sect>1): the plugin's F<agents/>, then each path of the manifest's
C<agents> (a string or a list), resolved against the plugin root. Each
returned path exists and is either a directory, to be walked for F<*.md>
(L<Langertha::Raider::Context::Agents>), or one F<*.md> file. A path that
leaves the plugin root is skipped; a path reached twice is returned once.

=head2 command_dirs

    my @paths = $plugins->command_dirs($plugin);   # absolute paths as strings

Where Claude Code finds the commands of one entry of L</plugins> (ADR 0030
E<sect>1), as L</agent_dirs> for agents: the plugin's F<commands/>, then
each path of the manifest's C<commands> (a string or a list; the custom
paths add to F<commands/>, they do not replace it), resolved against the
plugin root. Each returned path exists and is either a directory, searched
recursively for F<*.md> (L<Langertha::Raider::Context::Skills>), or one
F<*.md> file. A path that leaves the plugin root is skipped; a path
reached twice is returned once. A manifest C<commands> of another shape
(an object) adds nothing.

=head2 mcp_servers

    my ( $servers, $errors ) = $plugins->mcp_servers($plugin);
    for my $s (@$servers) { ... $s->{name}, $s->{entry}, $s->{source} ... }

The MCP servers one entry of L</plugins> declares (ADR 0029 E<sect>2), as
Claude Code reads them, in this order:

=over

=item * F<.mcp.json> in the plugin root: the map under C<mcpServers>, or
the whole object when it has no such key

=item * the manifest's C<mcpServers>: a path to such a file (relative to
the root), an inline map, or a list of both

=back

A server named twice: the later declaration wins. C<$servers> is sorted by
name, each C<< { name, entry, source } >> with the entry as written and
C<source> C<plugin:E<lt>nameE<gt> (FILE)> (C<plugin.json> for an inline
map). A missing default file is no error. A file the manifest names that
does not exist or is not a JSON object, a path that leaves the plugin root,
or a C<mcpServers> that is not a map
contributes nothing (a file named twice counts once) and is reported in
C<$errors>; never fatal. Entries are not checked here.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Settings/enabled_plugin_map>

=item * L<Langertha::Raider::Context::Skills>

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
