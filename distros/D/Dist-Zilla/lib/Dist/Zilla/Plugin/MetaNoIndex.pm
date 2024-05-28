package Dist::Zilla::Plugin::MetaNoIndex 6.032;
# ABSTRACT: Stop CPAN from indexing stuff

use Moose;
with 'Dist::Zilla::Role::MetaProvider';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =encoding utf8
#pod
#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [MetaNoIndex]
#pod
#pod   directory = t/author
#pod   directory = examples
#pod
#pod   file = lib/Foo.pm
#pod
#pod   package = My::Module
#pod
#pod   namespace = My::Module
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin allows you to prevent PAUSE/CPAN from indexing files you don't
#pod want indexed. This is useful if you build test classes or example classes
#pod that are used for those purposes only, and are not part of the distribution.
#pod It does this by adding a C<no_index> block to your F<META.json> (or
#pod F<META.yml>) file in your distribution.
#pod
#pod =for Pod::Coverage mvp_aliases mvp_multivalue_args
#pod
#pod =cut

my %ATTR_ALIAS = (
  directories => [ qw(directory dir folder) ],
  files       => [ qw(file) ],
  packages    => [ qw(package class module) ],
  namespaces  => [ qw(namespace) ],
);

sub mvp_aliases {
  my %alias_for;

  for my $key (keys %ATTR_ALIAS) {
    $alias_for{ $_ } = $key for @{ $ATTR_ALIAS{$key} };
  }

  return \%alias_for;
}

sub mvp_multivalue_args { return keys %ATTR_ALIAS }

#pod =attr directories
#pod
#pod Exclude folders and everything in them, for example: F<author.t>
#pod
#pod Aliases: C<folder>, C<dir>, C<directory>
#pod
#pod =attr files
#pod
#pod Exclude a specific file, for example: F<lib/Foo.pm>
#pod
#pod Alias: C<file>
#pod
#pod =attr packages
#pod
#pod Exclude by package name, for example: C<My::Package>
#pod
#pod Aliases: C<class>, C<module>, C<package>
#pod
#pod =attr namespaces
#pod
#pod Exclude everything under a specific namespace, for example: C<My::Package>
#pod
#pod Alias: C<namespace>
#pod
#pod B<NOTE:> This will not exclude the package C<My::Package>, only everything
#pod under it like C<My::Package::Foo>.
#pod
#pod =cut

for my $attr (keys %ATTR_ALIAS) {
  has $attr => (
    is        => 'ro',
    isa       => 'ArrayRef[Str]',
    init_arg  => $attr,
    predicate => "_has_$attr",
  );
}

#pod =method metadata
#pod
#pod Returns a reference to a hash containing the distribution's no_index metadata.
#pod
#pod =cut

sub metadata {
  my $self = shift;
  return {
    no_index => {
      map  {; my $reader = $_->[0];  ($_->[1] => [ sort @{ $self->$reader } ]) }
      grep {; my $pred   = "_has_$_->[0]"; $self->$pred }
      map  {; [ $_ => $ATTR_ALIAS{$_}[0] ] }
      keys %ATTR_ALIAS
    }
  };
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::MetaNoIndex - Stop CPAN from indexing stuff

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [MetaNoIndex]

  directory = t/author
  directory = examples

  file = lib/Foo.pm

  package = My::Module

  namespace = My::Module

=head1 DESCRIPTION

This plugin allows you to prevent PAUSE/CPAN from indexing files you don't
want indexed. This is useful if you build test classes or example classes
that are used for those purposes only, and are not part of the distribution.
It does this by adding a C<no_index> block to your F<META.json> (or
F<META.yml>) file in your distribution.

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

=head1 ATTRIBUTES

=head2 directories

Exclude folders and everything in them, for example: F<author.t>

Aliases: C<folder>, C<dir>, C<directory>

=head2 files

Exclude a specific file, for example: F<lib/Foo.pm>

Alias: C<file>

=head2 packages

Exclude by package name, for example: C<My::Package>

Aliases: C<class>, C<module>, C<package>

=head2 namespaces

Exclude everything under a specific namespace, for example: C<My::Package>

Alias: C<namespace>

B<NOTE:> This will not exclude the package C<My::Package>, only everything
under it like C<My::Package::Foo>.

=head1 METHODS

=head2 metadata

Returns a reference to a hash containing the distribution's no_index metadata.

=for Pod::Coverage mvp_aliases mvp_multivalue_args

=head1 SEE ALSO

Dist::Zilla roles: L<MetaProvider|Dist::Zilla::Role::MetaProvider>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
