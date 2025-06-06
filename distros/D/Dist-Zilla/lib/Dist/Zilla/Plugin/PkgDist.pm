package Dist::Zilla::Plugin::PkgDist 6.033;
# ABSTRACT: add a $DIST to your packages

use Moose;
with(
  'Dist::Zilla::Role::FileMunger',
  'Dist::Zilla::Role::FileFinderUser' => {
    default_finders => [ ':InstallModules', ':ExecFiles' ],
  },
  'Dist::Zilla::Role::PPI',
);

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin will add a line like the following to each package in each Perl
#pod module or program (more or less) within the distribution:
#pod
#pod   { our $DIST = 'My-CPAN-Dist'; } # where 'My-CPAN-Dist' is your dist name
#pod
#pod It will skip any package declaration that includes a newline between the
#pod C<package> keyword and the package name, like:
#pod
#pod   package
#pod     Foo::Bar;
#pod
#pod This sort of declaration is also ignored by the CPAN toolchain, and is
#pod typically used when doing monkey patching or other tricky things.
#pod
#pod =cut

sub munge_files {
  my ($self) = @_;

  $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
  my ($self, $file) = @_;

  # XXX: for test purposes, for now! evil! -- rjbs, 2010-03-17
  return                          if $file->name    =~ /^corpus\//;

  return                          if $file->name    =~ /\.t$/i;
  return $self->munge_perl($file) if $file->name    =~ /\.(?:pm|pl)$/i;
  return $self->munge_perl($file) if $file->content =~ /^#!(?:.*)perl(?:$|\s)/;
  return;
}

sub munge_perl {
  my ($self, $file) = @_;

  my $dist_name = $self->zilla->name;

  my $document = $self->ppi_document_for_file($file);

  return unless my $package_stmts = $document->find('PPI::Statement::Package');

  if ($self->document_assigns_to_variable($document, '$DIST')) {
    $self->log([ 'skipping %s: assigns to $DIST', $file->name ]);
    return;
  }

  my %seen_pkg;

  for my $stmt (@$package_stmts) {
    my $package = $stmt->namespace;

    if ($seen_pkg{ $package }++) {
      $self->log([ 'skipping package re-declaration for %s', $package ]);
      next;
    }

    if ($stmt->content =~ /package\s*\n\s*\Q$package/) {
      $self->log([ 'skipping private package %s', $package ]);
      next;
    }

    # the \x20 hack is here so that when we scan *this* document we don't find
    # an assignment to version; it shouldn't be needed, but it's been annoying
    # enough in the past that I'm keeping it here until tests are better
    my $perl = "{\n  \$$package\::DIST\x20=\x20'$dist_name';\n}\n";

    my $dist_doc = PPI::Document->new(\$perl);
    my @children = $dist_doc->schildren;

    $self->log_debug([
      'adding $DIST assignment to %s in %s',
      $package,
      $file->name,
    ]);

    # the extra whitespace element ensures we don't swallow up any blanks
    # lines after 'package ...' in the source file that PkgVersion warns about
    # if it's missing.
    Carp::carp('error inserting $DIST in ' . $file->name)
      unless $stmt->add_element( PPI::Token::Whitespace->new("\n") )
      and    $stmt->insert_after($children[0]->clone)
      and    $stmt->insert_after( PPI::Token::Whitespace->new("\n") );
  }

  # the document is no longer correct; it must be reparsed before it can be used again
  $file->content($document->serialize);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PkgDist - add a $DIST to your packages

=head1 VERSION

version 6.033

=head1 DESCRIPTION

This plugin will add a line like the following to each package in each Perl
module or program (more or less) within the distribution:

  { our $DIST = 'My-CPAN-Dist'; } # where 'My-CPAN-Dist' is your dist name

It will skip any package declaration that includes a newline between the
C<package> keyword and the package name, like:

  package
    Foo::Bar;

This sort of declaration is also ignored by the CPAN toolchain, and is
typically used when doing monkey patching or other tricky things.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
