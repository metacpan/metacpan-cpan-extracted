package Dist::Zilla::Plugin::PodVersion 6.017;
# ABSTRACT: add a VERSION head1 to each Perl document

use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
);

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin adds a C<=head1 VERSION> section to most perl files in the
#pod distribution, indicating the version of the dist being built.  This section is
#pod added after C<=head1 NAME>.  If there is no such section, the version section
#pod will not be added.
#pod
#pod Note that this plugin is not useful if you are using the
#pod L<[PodWeaver]|Dist::Zilla::Plugin::PodWeaver> plugin, as it also adds a
#pod C<=head1 VERSION> section (via the L<[Version]|Pod::Weaver::Section::Version>
#pod section).
#pod
#pod =cut

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  return $self->munge_pod($file);
}

sub munge_pod {
  my ($self, $file) = @_;

  my @content = split /\n/, $file->content;

  require List::Util;
  List::Util->VERSION('1.33');
  if (List::Util::any(sub { $_ =~ /^=head1 VERSION\b/ }, @content)) {
    $self->log($file->name . ' already has a VERSION section in POD');
    return;
  }

  for (0 .. $#content) {
    next until $content[$_] =~ /^=head1 NAME/;

    $_++; # move past the =head1 line itself
    $_++ while $content[$_] =~ /^\s*$/;

    $_++ while $content[$_] !~ /^\s*$/; # move past the abstract
    $_++ while $content[$_] =~ /^\s*$/;

    splice @content, $_ - 1, 0, (
      q{},
      "=head1 VERSION",
      q{},
      "version " . $self->zilla->version . q{},
    );

    $self->log_debug([ 'adding VERSION Pod section to %s', $file->name ]);

    my $content = join "\n", @content;
    $content .= "\n" if length $content;
    $file->content($content);
    return;
  }

  $self->log([
    "couldn't find '=head1 NAME' in %s, not adding '=head1 VERSION'",
    $file->name,
  ]);
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins:
#pod L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
#pod L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
#pod L<NextRelease|Dist::Zilla::Plugin::NextRelease>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PodVersion - add a VERSION head1 to each Perl document

=head1 VERSION

version 6.017

=head1 DESCRIPTION

This plugin adds a C<=head1 VERSION> section to most perl files in the
distribution, indicating the version of the dist being built.  This section is
added after C<=head1 NAME>.  If there is no such section, the version section
will not be added.

Note that this plugin is not useful if you are using the
L<[PodWeaver]|Dist::Zilla::Plugin::PodWeaver> plugin, as it also adds a
C<=head1 VERSION> section (via the L<[Version]|Pod::Weaver::Section::Version>
section).

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<PkgVersion|Dist::Zilla::Plugin::PkgVersion>,
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion>,
L<NextRelease|Dist::Zilla::Plugin::NextRelease>.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
