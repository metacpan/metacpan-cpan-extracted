use 5.006;
use strict;
use warnings;

package Dist::Zilla::App::Command::self;

our $VERSION = '0.001003';

# ABSTRACT: Build a distribution with a bootstrapped version of itself.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Dist::Zilla::App '-command';

## no critic (NamingConventions::ProhibitAmbiguousNames)
sub abstract { return 'Build a distribution with a boostrapped version of itself' }
## use critic

sub opt_spec { }

sub execute {
  my ( $self, undef, $arg ) = @_;

  my ( $target, undef ) = $self->zilla->ensure_built_in_tmpdir;
  my $root = $self->zilla->root;

  require Path::Tiny;
  require File::pushd;
  require Config;
  require Carp;

  {
    my $wd       = File::pushd::pushd($target);                       ## no critic (Variables::ProhibitUnusedVarsStricter)
    my @builders = @{ $self->zilla->plugins_with('-BuildRunner') };
    Carp::croak 'no BuildRunner plugins specified' unless @builders;
    $_->build for @builders;
  }

  my $sep = $Config::Config{path_sep};                                ## no critic (Variables::ProhibitPackageVars)

  my @lib = split $sep, $ENV{PERL5LIB} || q[];
  push @lib, Path::Tiny::path($target)->child('blib/lib');
  push @lib, Path::Tiny::path($target)->child('blib/arch');

  local $ENV{PERL5LIB} = join $sep, @lib;

  my $wd = File::pushd::pushd( Path::Tiny::path($root)->absolute );    ## no critic (Variables::ProhibitUnusedVarsStricter)
  return system 'dzil', @{$arg};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::self - Build a distribution with a bootstrapped version of itself.

=head1 VERSION

version 0.001003

=head1 SYNOPSIS

This is a different approach to using C<[Bootstrap::lib]> that absolves a distribution from needing to forcibly embed bootstrapping logic in C<dist.ini>

  dzil self build

This is largely similar to using

  [Bootstrap::lib]
  try_built = 1

and doing

  dzil build && dzil build

And similar again to:

  dzil run bash -c "cd ../; dzil -I$BUILDDIR/lib dzil build"

Or whatever the magic is that @ETHER uses.

This also means that:

  dzil self release

Is something you can do.

=head1 CAVEATS

The nature of this implies that your distribution will probably need an older generation of itself for the initial bootstrap.

That is to say:

  dzil build

Must work, and use C<Generation.Previous> to build C<Generation.Build>

  dzil self foo

Will call C<dzil build> for you, to build C<Generation.Build>, and then invoke

  dzil foo

To use C<Generation.Build> to build C<Generation.Next>

=over 4

=item C<1. Generation.Previous>

A previously installed incarnation of your dist.

=item C<2. Generation.Build>

The iteration of building the distribution itself from source using C<Generation.Previous>

=item C<3. Generation.Next>

The iteration of building the distribution itself from source using C<Generation.Build>

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
