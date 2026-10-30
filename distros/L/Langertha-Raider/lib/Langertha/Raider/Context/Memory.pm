package Langertha::Raider::Context::Memory;
# ABSTRACT: Internal reader of the Claude Code memory files (CLAUDE.md hierarchy)
our $VERSION = '0.504';
use Moose;
use namespace::autoclean;
use Path::Tiny;
use Langertha::Raider::Home;


has root => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

sub home_class { 'Langertha::Raider::Home' }


has home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_home { $_[0]->home_class->home_dir }


has claude_home => (
  is         => 'ro',
  isa        => 'Maybe[Str]',
  lazy_build => 1,
);

sub _build_claude_home {
  my ( $self ) = @_;
  return unless defined $self->home || length( $ENV{CLAUDE_CONFIG_DIR} // '' );
  my $dir = $self->home_class->claude_home($self->home);
  return defined $dir ? $dir->stringify : undef;
}


has walk_dirs => (
  is       => 'ro',
  isa      => 'ArrayRef',
  required => 1,
);


has max_import_depth => (
  is      => 'ro',
  isa     => 'Int',
  default => 5,
);

has _real_root => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__real_root { $_[0]->_real($_[0]->root) }

has _real_home => (
  is         => 'ro',
  lazy_build => 1,
);

sub _build__real_home {
  my ( $self ) = @_;
  my $home = $self->home;
  return defined $home ? $self->_real($home) : undef;
}

# Real paths of the nested CLAUDE.md files already handed out.
has _delivered => (
  is      => 'ro',
  default => sub { {} },
);


has items => (
  is         => 'ro',
  isa        => 'ArrayRef',
  lazy_build => 1,
);

sub _build_items {
  my ( $self ) = @_;
  my $root = $self->_real_root;
  my ( @items, %seen );
  my $add = sub {
    my ( $file, $scope, $kind ) = @_;
    my $item = $self->_item($file, $scope, $kind) or return;
    push @items, $item unless $seen{ $item->{file} }++;
    return 1;
  };
  $add->(path($self->claude_home)->child('CLAUDE.md'), 'user', 'CLAUDE.md')
    if defined $self->claude_home;
  for my $d (@{ $self->walk_dirs }) {
    my $dir   = $self->_real($d);
    my $scope = $dir->stringify eq $root->stringify ? 'project' : 'ancestor';
    $add->($dir->child('CLAUDE.md'), $scope, 'CLAUDE.md')
      or $add->($dir->child('AGENTS.md'), $scope, 'AGENTS.md');
    $add->($dir->child('CLAUDE.local.md'), 'local', 'CLAUDE.local.md');
  }
  return \@items;
}


sub prompt_text {
  my ( $self ) = @_;
  return $self->nested_text(@{ $self->items });
}


sub nested_for {
  my ( $self, $path ) = @_;
  return unless defined $path && length $path;
  my $root   = $self->_real_root;
  my $target = $self->_real(path($path)->absolute($root));
  my $dir    = -d $target ? $target : $target->parent;
  return unless $root->subsumes($dir) && $dir->stringify ne $root->stringify;
  my @dirs;
  while ($dir->stringify ne $root->stringify) {
    unshift @dirs, $dir;
    $dir = $dir->parent;
  }
  my @items;
  for my $d (@dirs) {
    my $file = $d->child('CLAUDE.md');
    next unless -f $file;
    my $key = $self->_real($file)->stringify;
    next if $self->_delivered->{$key}++;
    my $item = $self->_item($file, 'nested', 'CLAUDE.md') or next;
    push @items, $item;
  }
  return @items;
}


sub nested_text {
  my ( $self, @items ) = @_;
  return unless @items;
  return join "\n\n", map {
    my $text = $_->{text};
    $text =~ s/\s+\z//;
    'Contents of '.$_->{file}.' ('.$self->_description($_)."):\n\n".$text;
  } @items;
}

sub _description {
  my ( $self, $item ) = @_;
  return $item->{kind} eq 'AGENTS.md' ? 'project instructions (AGENTS.md)'
    : $item->{scope} eq 'user'  ? "user's private global instructions for all projects"
    : $item->{scope} eq 'local' ? "user's private project instructions, not checked in"
    : 'project instructions, checked into the codebase';
}

sub _item {
  my ( $self, $file, $scope, $kind ) = @_;
  return unless -f $file;
  my $real = $self->_real($file);
  my $raw  = $self->_slurp($real);
  return unless defined $raw && $raw =~ /\S/;
  my @imports;
  my $text = $self->_expand($raw, $real, 0, { $real->stringify => 1 }, \@imports);
  return {
    file    => $real->stringify,
    label   => $self->_label($real),
    scope   => $scope,
    kind    => $kind,
    text    => $text,
    imports => \@imports,
  };
}

sub _label {
  my ( $self, $file ) = @_;
  my $root = $self->_real_root;
  return $file->relative($root)->stringify if $root->subsumes($file);
  my $home = $self->_real_home;
  return '~/'.$file->relative($home)->stringify if defined $home && $home->subsumes($file);
  return $file->stringify;
}

# Expand the @path imports of $text, the content of $file at import depth
# $depth. $seen holds the real paths already imported (or being imported)
# for this item, $imports collects them in import order.
sub _expand {
  my ( $self, $text, $file, $depth, $seen, $imports ) = @_;
  my ( @out, $fence );
  for my $line (split /^/, $text) {
    if (defined $fence) {
      undef $fence if $line =~ $fence;
      push @out, $line;
      next;
    }
    if ($line =~ /^ {0,3}(`{3,}|~{3,})/) {
      my ( $char, $len ) = ( quotemeta substr($1, 0, 1), length $1 );
      $fence = qr/^ {0,3}(?:$char){$len,}\s*$/;
      push @out, $line;
      next;
    }
    my @spans = $self->_code_spans($line);
    $line =~ s{(?:^|(?<=\s))\@(\S+)}{
      my ( $token, $ref, $at ) = ( $&, $1, $-[0] );
      ( grep { $at >= $_->[0] && $at < $_->[1] } @spans )
        ? $token
        : $self->_import($ref, $file, $depth, $seen, $imports) // $token;
    }ge;
    push @out, $line;
  }
  return join '', @out;
}

sub _import {
  my ( $self, $ref, $from, $depth, $seen, $imports ) = @_;
  return if $depth >= $self->max_import_depth;
  my $target;
  if ($ref =~ m{^~/(.*)\z}s) {
    my $home = $self->_real_home or return;
    $target = $home->child($1);
  }
  elsif ($ref =~ m{^~}) {
    return;
  }
  else {
    $target = path($ref)->absolute($from->parent);
  }
  return unless -f $target;
  my $real = $self->_real($target);
  return if $seen->{ $real->stringify }++;
  my $raw = $self->_slurp($real);
  return unless defined $raw;
  push @$imports, $real->stringify;
  my $text = $self->_expand($raw, $real, $depth + 1, $seen, $imports);
  $text =~ s/\n+\z//;
  return $text;
}

# [start, end) offsets of the inline code spans of one line.
sub _code_spans {
  my ( $self, $line ) = @_;
  my @spans;
  while ($line =~ /(`+)/g) {
    my ( $tick, $start, $after ) = ( $1, $-[0], pos $line );
    if ($line =~ /\G.*?(?<!`)\Q$tick\E(?!`)/gc) {
      push @spans, [ $start, pos $line ];
    }
    else {
      pos($line) = $after;
    }
  }
  return @spans;
}

sub _slurp {
  my ( $self, $file ) = @_;
  return eval { $file->slurp_utf8 };
}

# The real path of $p; for a path that does not exist (yet), the real path
# of its nearest existing ancestor with the rest appended.
sub _real {
  my ( $self, $p ) = @_;
  my $path = path($p)->absolute;
  my @rest;
  until (-e $path || $path->is_rootdir) {
    unshift @rest, $path->basename;
    $path = $path->parent;
  }
  my $real = eval { $path->realpath } // $path;
  return @rest ? $real->child(@rest) : $real;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Context::Memory - Internal reader of the Claude Code memory files (CLAUDE.md hierarchy)

=head1 VERSION

version 0.504

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $memory = Langertha::Raider::Context::Memory->new(
      root      => $root,
      walk_dirs => [ $layout->walk_dirs ],
    );
    for my $item (@{ $memory->items }) {
      say $item->{label}.' ('.$item->{scope}.')';
    }
    my $prompt = $memory->prompt_text;            # undef without any file

    # later, when a file tool touches lib/Foo/Bar.pm:
    my @nested = $memory->nested_for('lib/Foo/Bar.pm');
    my $append = $memory->nested_text(@nested);   # undef when nothing new

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

Reads the Claude Code memory files as ADR 0019 E<sect>2 describes, each as
its own context item with source and scope (ADR 0004):

=over

=item 1. F<< <claude_home>/CLAUDE.md >> -- scope C<user>.

=item 2. For every directory of L</walk_dirs>, top down: F<CLAUDE.md> (or,
when that level has none, its F<AGENTS.md>) -- scope C<project> in
L</root>, C<ancestor> above it; then F<CLAUDE.local.md> -- scope C<local>.

=back

C<@path> imports in these files are expanded in place, as Claude Code does:
a token C<@some/path> at the start of a line or after whitespace (the path
runs to the next whitespace) is replaced by the content of that file,
resolved relative to the importing file, from L</home> for C<@~/...>, as
given when absolute. Imports are never expanded inside inline code spans or
fenced code blocks, at most L</max_import_depth> levels deep, never twice
for one file (so cycles end), and a missing or unreadable target is left as
written. Because the C<@> must follow whitespace or start the line, an
address like C<a@b.c> is never an import.

F<CLAUDE.md> files below L</root> are not read up front; L</nested_for>
hands them out once each when a path in their subtree is touched (Claude
Code's nested memory).

Empty and unreadable files are skipped. Paths are compared by their real
path where the filesystem has one; every C<file> is such an absolute path.

=head2 root

The project directory. Required.

=head2 home

The user's home directory, for C<@~/> imports and C<~/> labels. Defaults to
L<Langertha::Raider::Home/home_dir>.

=head2 claude_home

The Claude Code configuration directory holding the user memory: like
L<Langertha::Raider::Context::Layout/claude_home>,
C<$ENV{CLAUDE_CONFIG_DIR}> when set and not empty, else
F<< <home>/.claude >>.

=head2 walk_dirs

    walk_dirs => [ $layout->walk_dirs ],

Required. The directories of the memory walk, top down and ending at
L</root> (strings or L<Path::Tiny>), as
L<Langertha::Raider::Context::Layout/walk_dirs> returns them.

=head2 max_import_depth

How many levels of C<@path> imports are expanded. Defaults to C<5>; an
import deeper than that is left as written.

=head2 items

    for my $item (@{ $memory->items }) { ... }

The memory files in load order (see L</DESCRIPTION>), computed once, as an
ArrayRef of HashRefs:

=over

=item * C<file> -- absolute path.

=item * C<label> -- the path relative to L</root> when inside it,
C<~/...> when under L</home>, else absolute.

=item * C<scope> -- C<user>, C<ancestor>, C<project> or C<local>.

=item * C<kind> -- C<CLAUDE.md>, C<CLAUDE.local.md> or C<AGENTS.md>.

=item * C<text> -- the content with its imports expanded.

=item * C<imports> -- ArrayRef of the absolute paths actually imported,
nested imports included.

=back

=head2 prompt_text

    my $text = $memory->prompt_text;

L</items> formatted as Claude Code puts them into the prompt, one block per
item, separated by blank lines:

    Contents of /abs/CLAUDE.md (project instructions, checked into the codebase):

    <text>

The description is C<user's private global instructions for all projects>
(scope C<user>), C<project instructions, checked into the codebase>
(C<project>, C<ancestor>, nested), C<user's private project instructions,
not checked in> (C<local>) or C<project instructions (AGENTS.md)> (kind
C<AGENTS.md>). Returns C<undef> when there are no items.

=head2 nested_for

    my @items = $memory->nested_for($path);

The F<CLAUDE.md> files of the directories strictly below L</root> down to
the directory of C<$path> (C<$path> itself when it is a directory), top
down, that this object has not handed out before. C<$path> is absolute or
relative to L</root>; a path outside L</root> yields nothing. Every file is
returned at most once per object. Items have the shape of L</items>, scope
C<nested>, kind C<CLAUDE.md>.

=head2 nested_text

    my $text = $memory->nested_text(@items);

The given items formatted like L</prompt_text>; C<undef> for none.

=head1 SEE ALSO

=over

=item * L<Langertha::Raider::Context::Layout>

=item * L<Langertha::Raider::Instructions>

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
