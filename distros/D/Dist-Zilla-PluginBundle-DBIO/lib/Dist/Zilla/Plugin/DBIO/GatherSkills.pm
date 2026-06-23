package Dist::Zilla::Plugin::DBIO::GatherSkills;
# ABSTRACT: Ship a distribution's own agent skills as a sharedir (share/skills/)
use Moose;
use Path::Tiny;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';


has skill => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  lazy    => 1,
  default => sub { [] },
);

sub mvp_multivalue_args { qw(skill) }


has from => (
  is      => 'ro',
  isa     => 'Str',
  default => '.claude/skills',
);

sub _owned {
  my ($self) = @_;
  return @{ $self->skill } if @{ $self->skill };

  # Fallback: skills named after the distribution (e.g. DBIO-DB2 -> dbio-db2*).
  my $slug = lc $self->zilla->name;
  my $base = path($self->from);
  return unless $base->is_dir;

  my @owned;
  for my $child (grep { $_->is_dir } $base->children) {
    my $name = $child->basename;
    push @owned, $name if $name eq $slug or index($name, "$slug-") == 0;
  }
  return sort @owned;
}

sub gather_files {
  my ($self) = @_;
  my $base = path($self->from);

  for my $name ($self->_owned) {
    my $dir = $base->child($name);
    unless ($dir->is_dir) {
      $self->log("owned skill '$name' not found under @{[$self->from]} -- skipping");
      next;
    }

    my $iter = $dir->iterator({ recurse => 1 });
    while (my $file = $iter->()) {
      next unless $file->is_file;
      my $rel = $file->relative($base);          # e.g. dbio-db2/SKILL.md
      $self->add_file(Dist::Zilla::File::InMemory->new(
        name    => "share/skills/$rel",
        content => $file->slurp_utf8,
      ));
      $self->log_debug("gathered share/skills/$rel");
    }
  }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::GatherSkills - Ship a distribution's own agent skills as a sharedir (share/skills/)

=head1 VERSION

version 0.900002

=head1 DESCRIPTION

Gathers the agent skills a distribution B<owns> (is the source of truth for)
from C<.claude/skills/> into the build as C<share/skills/E<lt>nameE<gt>/...>, so
that C<[ShareDir]> installs them into the distribution's sharedir. This is how
DBIO exposes its skills at runtime (see L<DBIO::Skills>) without keeping a
second copy in the repository: the skill is authored once under C<.claude/> and
copied into the sharedir at build time.

Only owned skills are gathered — the linked-in family/shared skills belong to,
and are shipped by, their own home distribution.

=head1 ATTRIBUTES

=head2 skill

The names of the owned skills to ship (repeatable). These are declared
explicitly in F<dist.ini> so the set is deterministic and independent of any
hardlink/symlink state in the checkout:

  [DBIO::GatherSkills]
  skill = dbio-db2
  skill = dbio-db2-database

If no C<skill> is given, the set is derived from the distribution name as a
fallback: skills named after the dist (C<DBIO-DB2> → C<dbio-db2>,
C<dbio-db2-*>).

=head2 from

Directory the skills are read from. Default: C<.claude/skills>.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
