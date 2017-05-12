package Dist::Zilla::Plugin::Git::Describe;
# git description: 0.006-1-g35a750b

# ABSTRACT: add the results of `git describe` (roughly) to your main module
$Dist::Zilla::Plugin::Git::Describe::VERSION = '0.007';
use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::PPI',
);

use Git::Wrapper;
use Try::Tiny;
use List::Util 1.33 'all';

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod in dist.ini
#pod
#pod   [Git::Describe]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin will add the long-form git commit description for the current repo
#pod to the dist's main module as a comment.  It may change, in the future, to put
#pod things in a package variable, or to provide an option.
#pod
#pod It inserts this in the same place that PkgVersion would insert a version.
#pod
#pod =attr on_package_line
#pod
#pod If true, then the comment is added to the same line as the package declaration.
#pod Otherwise, it is added on its own line, with an additional blank line following it.
#pod Defaults to false.
#pod
#pod =cut

has on_package_line => (
  is  => 'ro',
  isa => 'Bool',
  default => 0,
);

sub munge_files {
  my ($self) = @_;

  my $file = $self->zilla->main_module;

  require PPI::Document;
  my $document = $self->ppi_document_for_file($file);

  return unless my $package_stmts = $document->find('PPI::Statement::Package');

  my $git  = Git::Wrapper->new( $self->zilla->root );
  my @lines = $git->describe({ long => 1, always => 1 });

  my $desc = $lines[0];

  my %seen_pkg;

  for my $stmt (@$package_stmts) {
    my $package = $stmt->namespace;

    if ($seen_pkg{ $package }++) {
      $self->log([ 'skipping package re-declaration for %s', $package ]);
      next;
    }

    if ($stmt->content =~ /package\s*(?:#.*)?\n\s*\Q$package/) {
      $self->log([ 'skipping private package %s in %s', $package, $file->name ]);
      next;
    }

    my $perl = $self->on_package_line
             ? " # git description: $desc"
             : "\n# git description: $desc\n";

    my $version_doc = PPI::Document->new(\$perl);
    my @children = $version_doc->children;

    $self->log_debug([
      'adding git description comment to %s in %s',
      $package,
      $file->name,
    ]);

    Carp::carp("error inserting git description in " . $file->name)
      unless all { $stmt->insert_after($_->clone) } reverse @children;
  }

  $self->save_ppi_document_to_file($document, $file);
}

__PACKAGE__->meta->make_immutable;
1;

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Git::Describe - add the results of `git describe` (roughly) to your main module

=head1 VERSION

version 0.007

=head1 SYNOPSIS

in dist.ini

  [Git::Describe]

=head1 DESCRIPTION

This plugin will add the long-form git commit description for the current repo
to the dist's main module as a comment.  It may change, in the future, to put
things in a package variable, or to provide an option.

It inserts this in the same place that PkgVersion would insert a version.

=head1 ATTRIBUTES

=head2 on_package_line

If true, then the comment is added to the same line as the package declaration.
Otherwise, it is added on its own line, with an additional blank line following it.
Defaults to false.

=head1 SEE ALSO

L<PodVersion|Dist::Zilla::Plugin::PkgVersion>

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 CONTRIBUTOR

=for stopwords Karen Etheridge

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#pod =head1 SEE ALSO
#pod
#pod L<PodVersion|Dist::Zilla::Plugin::PkgVersion>
#pod
#pod =cut
