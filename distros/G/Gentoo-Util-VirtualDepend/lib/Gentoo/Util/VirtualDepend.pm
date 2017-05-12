use 5.006;
use strict;
use warnings;

package Gentoo::Util::VirtualDepend;

our $VERSION = '0.003023';

# ABSTRACT: Hard-coded replacements for perl-core/ dependencies and dependencies with odd names in Gentoo

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use Path::Tiny qw( path );
use File::ShareDir qw( dist_file );

# Note: this should be the version default max_perl is in
use Module::CoreList 5.20151213;










# Note: This should be the latest visible version in portage at time of release
has max_perl => ( is => 'ro', lazy => 1, default => sub { '5.22.1' } );










# Note: This should be the lowest visible version 12 months prior to the time of release
has min_perl => ( is => 'ro', lazy => 1, default => sub { '5.18.2' } );

my %MOD2GENTOO;
my $MOD2GENTOO_LOADED;
my $MOD2GENTOO_FILE = 'module-to-gentoo.csv';

my %DIST2GENTOO;
my $DIST2GENTOO_LOADED;
my $DIST2GENTOO_FILE = 'dist-to-gentoo.csv';

my %GENTOO2DIST;
my %GENTOO2MOD;

my $DIST = q[Gentoo-Util-VirtualDepend];

sub _load_mod2gentoo {
  return if $MOD2GENTOO_LOADED;
  my $fh = path( dist_file( $DIST, $MOD2GENTOO_FILE ) )->openr_raw;
  while ( my $line = <$fh> ) {
    chomp $line;
    my ( $module, $map ) = split /,/, $line;    ## no critic (RegularExpressions)
    $MOD2GENTOO{$module} = $map;
    $GENTOO2MOD{$map} = [] unless exists $GENTOO2MOD{$map};
    push @{ $GENTOO2MOD{$map} }, $module;
  }
  return $MOD2GENTOO_LOADED = 1;
}

sub _load_dist2gentoo {
  return if $DIST2GENTOO_LOADED;
  my $fh = path( dist_file( $DIST, $DIST2GENTOO_FILE ) )->openr_raw;
  while ( my $line = <$fh> ) {
    chomp $line;
    my ( $module, $map ) = split /,/, $line;    ## no critic (RegularExpressions)
    $DIST2GENTOO{$module} = $map;
    $GENTOO2DIST{$map} = [] unless exists $GENTOO2DIST{$map};
    push @{ $GENTOO2DIST{$map} }, $module;
  }
  return $DIST2GENTOO_LOADED = 1;
}

sub has_module_override {
  my ( undef, $module ) = @_;
  _load_mod2gentoo unless $MOD2GENTOO_LOADED;
  return exists $MOD2GENTOO{$module};
}

sub get_module_override {
  my ( undef, $module ) = @_;
  _load_mod2gentoo unless $MOD2GENTOO_LOADED;
  return $MOD2GENTOO{$module};
}

sub has_dist_override {
  my ( undef, $dist ) = @_;
  _load_dist2gentoo unless $DIST2GENTOO_LOADED;
  return exists $DIST2GENTOO{$dist};
}

sub get_dist_override {
  my ( undef, $dist ) = @_;
  _load_mod2gentoo unless $DIST2GENTOO_LOADED;
  return $DIST2GENTOO{$dist};
}

sub has_gentoo_package {
  my ( undef, $package ) = @_;
  _load_dist2gentoo unless $DIST2GENTOO_LOADED;
  return exists $GENTOO2DIST{$package};
}

sub get_dists_in_gentoo_package {
  my ( undef, $package ) = @_;
  _load_dist2gentoo unless $DIST2GENTOO_LOADED;
  return @{ $GENTOO2DIST{$package} || [] };
}

sub get_modules_in_gentoo_package {
  my ( undef, $package ) = @_;
  _load_mod2gentoo unless $MOD2GENTOO_LOADED;
  return @{ $GENTOO2MOD{$package} || [] };
}

sub get_known_gentoo_packages {
  _load_dist2gentoo unless $DIST2GENTOO_LOADED;
  return keys %GENTOO2DIST;
}

sub get_known_dists {
  _load_dist2gentoo unless $DIST2GENTOO_LOADED;
  return keys %DIST2GENTOO;
}

sub get_known_modules {
  _load_mod2gentoo unless $MOD2GENTOO_LOADED;
  return keys %MOD2GENTOO;
}

sub module_is_perl {
  my ( $self, $opts, $module, $mod_version ) = @_;
  if ( not ref $opts ) {
    ( $opts, $module, $mod_version ) = ( {}, $opts, $module );
  }

  # If the module has a virtual, don't even consider
  # CPAN/perl decisions

  return if $self->has_module_override($module);
  require version;

  $opts->{min_perl} ||= $self->min_perl;
  my $min_perl = version->parse( $opts->{min_perl} );
  $opts->{max_perl} ||= $self->max_perl;
  my $max_perl = version->parse( $opts->{max_perl} );

  my $seen;
  ## no critic (Variables::ProhibitPackageVars)
  for my $version ( keys %Module::CoreList::version ) {
    my $perlver = version->parse($version);
    ## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
    next unless $perlver >= $min_perl;
    next unless $perlver <= $max_perl;

    # If any version in the range returns "deprecated", then we should
    # default to CPAN
    return if $Module::CoreList::deprecated{$version}{$module};

    # If any version in the range does not exist, then we should default to CPAN
    #
    return if not exists $Module::CoreList::version{$version}{$module};

    if ( not defined $mod_version ) {
      $seen = 1;
      next;
    }

    # If any version in the range is undef, and a specific version is requested,
    # Default to CPAN, because it means a virtual is not provisioned.
    return if not defined $Module::CoreList::version{$version}{$module};

    my $this_version = version->parse( $Module::CoreList::version{$version}{$module} );

    # If any version in the range is lower than required, default to CPAN
    # because it means a virtual is not provisioned, and a breakage will occur
    # on one of the versions.
    return if $this_version < version->parse($mod_version);

    $seen = 1;
  }
  return $seen;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Util::VirtualDepend - Hard-coded replacements for perl-core/ dependencies and dependencies with odd names in Gentoo

=head1 VERSION

version 0.003023

=head1 SYNOPSIS

  use Gentoo::Util::VirtualDepend;

  my $v = Gentoo::Util::VirtualDepend->new();

  # somewhere in complex dependency resolution

  my $cpan_module = spooky_function();
  my $gentoo_dependency;

  if ( $v->has_module_override( $cpan_module ) ) {
    $gentoo_dependency = $v->get_module_override( $cpan_module );
  } else {
    # do it the hard way.
  }

If you're trying to be defensive and you're going to map the modules to distributions
the hard way ( trust me, the code is really ugly ), then you may instead want

  if ( $v->has_dist_override( $cpan_dist ) ) {
    $gentoo_dependency = $v->get_dist_override( $cpan_dist );
  } else {
    # fallback to using dev-perl/Foo-Bar
  }

Which basically serves as a distribution name translator.

=head2 WHY YOU WANT TO DO THAT

Well ...

     { requires => { Foo => 1.0 }}

     Foo is in Bar

     Foo 1.0 could have been shipped in in Bar-1.0, Bar-0.5, or Bar-2.0 for all you know.

That's the unfortunate reality of C<CPAN> dependencies.

So if you naively map

    Foo-1.0 → >=dev-lang/Bar-1.0

You might get breakage if C<Foo 1.0> didn't ship till C<Bar-2.0>, and the user has C<Bar-1.0> → Shower of sparks.

=head1 DESCRIPTION

This module serves as a low level glue layer for the handful of manual mappings
that are needed in Gentoo due to things not strictly tracking upstream.

C<CPANPLUS::Dist::Gentoo> has similar logic to this, but not as simple ( or for that matter, usable without C<CPANPLUS> )

This module is not intended to be used entirely on its own, but as a short-circuit before calling
complicated C<MetaCPAN> code.

=head1 METHODS

=head2 has_module_override

  $v->has_module_override( $module )

Returns true if there is a known mapping for C<$module> in C<Gentoo> that is unusual and may require translation.

Will return true for anything that is either a C<virtual> or has an unusual
name translation separating it from C<CPAN>.

=head2 get_module_override

  $v->get_module_override( $module )

Returns a C<Gentoo> dependency atom corresponding to C<$module> if there is a known mapping for C<$module>.

For instance,

  $v->get_module_override('ExtUtils::MakeMaker')

Emits:

  virtual/perl-ExtUtilsMakeMaker

If C<ExtUtils::MakeMaker> is one day de-cored (Hah!, dreams are free) then
C<has_module_override> will return false, and that instructs you to go back
to assuming it is in C<dev-perl/>

=head2 has_dist_override

  $v->has_dist_override( $distname )

Similar to C<has_module_override> but closer to the dependency spec.

Will return true for anything that is either a C<virtual> or has an unusual
name translation separating it from C<CPAN>.

=head2 get_dist_override

  $v->get_dist_override( $distname )

Similar to C<get_module_override> but closer to the dependency spec.

For instance:

  $v->get_dist_override('PathTools')

Emits:

  virtual/perl-File-Spec

Because C<Gentoo> is quirky like that.

=head2 has_gentoo_package

  $v->has_gentoo_package( 'virtual/perl-Test-Simple' )

Determines if the data file has entries mapping to C<virtual/perl-Test-Simple>.

This is mostly for internal consistency tests/maintenance.

=head2 get_dists_in_gentoo_package

  my @list = $v->get_dists_in_gentoo_package( 'virtual/perl-Test-Simple' )

Returns a list of C<CPAN> Distributions that map to this dependency.

=head2 get_modules_in_gentoo_package

  my @list = $v->get_modules_in_gentoo_package( 'virtua/perl-Test-Simple' )

Returns a list of modules that map to this dependency.

=head2 get_known_gentoo_packages

  my @list = $v->get_known_gentoo_packages

Returns a list of Gentoo packages for which there are known overrides.

=head2 get_known_dists

  my @list = $v->get_known_dists

Returns a list of C<CPAN> Distributions for which there are known overrides

=head2 get_known_modules

  my @list = $v->get_known_modules

Return a list of C<CPAN> Modules for which there are known overrides

=head2 module_is_perl

This function determines if it is "safe" to assume availability
of a given module ( or a given module and version ) without needing to
stipulate either a virtual or a C<CPAN> dependency.

  ->module_is_perl( $module )
  ->module_is_perl( $module, $min_version )
  ->module_is_perl( \%config, $module, $min_version )

Rules:

=over 4

=item * If the module is present in the override map, then it is deemed B<NOT>
available from C<Perl>, because you should be using the override instead.

=item * If the module is missing on any version in the range specified, then it is
B<NOT> available from C<Perl>, and you must depend on a virtual or some other
dependency you can source.

=item * If the module is marked I<deprecated> on any version in the range specified,
then it is assumed B<NOT> available in C<Perl> ( due to likely deprecation warnings
and imminent need to start adapting )

=item * If a minimum version is specified, and I<any> version of C<Perl> in the range
specified does not satisfy that minimum, then it is assumed B<NOT> available in
C<Perl> ( due to the inherent need to manually solve the issue via a virtual or a
minimum C<Perl> dependency )

=item * If a minimum version is specified, and I<any> version of C<Perl> in the range
specified is an explicit C<undef>, then it is assumed B<NOT> available in C<Perl>,
because clearly, one version of C<Perl> having C<undef> and another having an
explicit version, and needing only one of the two requires a manual dependency
resolution.

=back

Examples:

=over 4

=item * Determine if C<strict> is I<implicitly> available.

  if ( $v->module_is_perl( 'strict' ) ) {

=item * Determine if C<strict> version C<1.09> is available.

  if ( $v->module_is_perl( 'strict' => '1.09' ) ) {

This will of course return C<undef> unless C<min_perl> is at least C<5.21.7>.

Thus, if your support range is 5.18.0 to 5.20, and somebody stipulates that minimum,
you will have to declare a dependency on C<Perl> 5.21.7.

Even if your support range is 5.18.0 to 5.22.0, you will still have to declare a
dependency on 5.21.7 instead of assuming its presence.

=item * Determine if C<strict> version C<1.09> is available on X to Y C<Perls>.

For most code where the support range is fixed, this will be unnecessary,
and changing the defaults via C<< ->new( min_perl => ... , max_perl => ... ) >>
should be sufficient.

However:

  if( $v->module_is_perl( { min_perl => '5.21.7', max_perl => '5.21.9' }, 'strict', '1.09' ) ) {
      # true
  }

=back

=head1 ATTRIBUTES

=head2 max_perl

  ->new( max_perl => '5.20.2' )
  ->max_perl # 5.20.2

Stipulates the default maximum C<Perl> for L<< C<module_is_perl>|/module_is_perl >>.

=head2 min_perl

  ->new( min_perl => '5.20.2' )
  ->min_perl # 5.20.2

Stipulates the default minimum C<Perl> for L<< C<module_is_perl>|/module_is_perl >>.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
