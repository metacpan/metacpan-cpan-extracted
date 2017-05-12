use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::KENTNL::Lite;

our $VERSION = '2.001001';

# ABSTRACT: (DEPRECATED) A Minimal Build-Only replacement for @Author::KENTNL for contributors.

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( with );
use Module::Runtime qw( );
use Try::Tiny qw( try );

with 'Dist::Zilla::Role::PluginBundle';

use namespace::autoclean -also => [qw( _expand _maybe )];

sub _expand {
  my ( undef, $suffix, $conf ) = @_;
  ## no critic ( RequireInterpolationOfMetachars )
  if ( ref $suffix ) {
    my ( $corename, $rename ) = @{$suffix};
    if ( exists $conf->{-name} ) {
      $rename = delete $conf->{-name};
    }
    return [ q{@Author::KENTNL::Lite/} . $corename . q{/} . $rename, 'Dist::Zilla::Plugin::' . $corename, $conf ];
  }
  if ( exists $conf->{-name} ) {
    my $rename;
    $rename = sprintf q{%s/%s}, $suffix, ( delete $conf->{-name} );
    return [ q{@Author::KENTNL::Lite/} . $rename, 'Dist::Zilla::Plugin::' . $suffix, $conf ];

  }

  return [ q{@Author::KENTNL::Lite/} . $suffix, 'Dist::Zilla::Plugin::' . $suffix, $conf ];
}







sub _maybe {
  my ( $module, @passthrough ) = @_;
  my $modname = Module::Runtime::compose_module_name( 'Dist::Zilla::Plugin', $module );
  if ( try { Module::Runtime::require_module($modname); 1 } ) {
    return @passthrough;
  }
  require Carp;
  Carp::carp( q{[} . q[@] . q{Author::KENTNL::Lite] Skipping _maybe dep } . $module );
  return ();
}










sub mvp_multivalue_args { return qw( auto_prereqs_skip ) }

sub _only_fiveten {
  my ( $arg, @payload ) = @_;
  return () if exists $ENV{'KENTNL_NOFIVETEN'};
  return @payload unless defined $arg;
  return @payload unless 'HASH' eq ref $arg;
  return @payload unless exists $arg->{'no_fiveten'};
  return ();
}

sub bundle_config_inner {
  my ( undef, $arg ) = @_;
  if ( not exists $arg->{git_versions} ) {
    require Carp;
    Carp::croak('Sorry, Git based versions are now mandatory');
  }
  if ( not defined $arg->{authority} ) {
    $arg->{authority} = 'cpan:KENTNL';
  }
  if ( not defined $arg->{auto_prereqs_skip} ) {
    $arg->{auto_prereqs_skip} = [];
  }
  if ( not 'ARRAY' eq ref $arg->{auto_prereqs_skip} ) {
    require Carp;
    Carp::carp('[Author::KENTNL::Lite] auto_prereqs_skip is expected to be an array ref');
  }

  my (@version) = (
    [
      'Git::NextVersion' => {
        version_regexp => '^(.*)-source$',
        first_version  => '0.1.0',
      },
    ],
  );

  ## no critic (ProhibitPunctuationVars)
  my (@metadata) = (
    [ 'MetaConfig' => {} ],
    _maybe( 'GithubMeta',            [ 'GithubMeta'            => {} ] ),
    _maybe( 'MetaProvides::Package', [ 'MetaProvides::Package' => {} ] ),
    _maybe(
      'MetaData::BuiltWith',
      [
        'MetaData::BuiltWith' =>
          { 'linux' eq $^O ? ( show_uname => 1, uname_args => q{ -s -o -r -m -i } ) : (), show_config => 1 },
      ],
    ),
  );

  my (@sharedir) = ();

  my (@gatherfiles) = (
    [ 'GatherDir'        => { include_dotfiles => 1 } ],
    [ 'License'          => {} ],
    [ 'MetaJSON'         => {} ],
    [ 'MetaYAML'         => {} ],
    [ 'Manifest'         => {} ],
    [ 'MetaTests'        => {} ],
    [ 'PodCoverageTests' => {} ],
    [ 'PodSyntaxTests'   => {} ],
    _maybe( 'ReportVersions::Tiny', [ 'ReportVersions::Tiny' => {} ], ),
    _maybe( 'Test::Kwalitee',       [ 'Test::Kwalitee'       => {} ] ),
    [ 'EOLTests' => { trailing_whitespace => 1, } ],
    _maybe( 'Test::MinimumVersion', [ 'Test::MinimumVersion' => {} ], ),
    [ 'Test::Compile' => {} ],
    _maybe( 'Test::Perl::Critic', [ 'Test::Perl::Critic' => {} ] ),

  );

  my (@prunefiles) = ( [ 'PruneCruft' => { except => '^.perltidyrc' } ], [ 'ManifestSkip' => {} ], );

  my (@regprereqs) = (
    [ 'AutoPrereqs' => { skip => $arg->{auto_prereqs_skip} } ],
    [
      'Prereqs' => {
        -name                                             => 'BundleDevelNeeds',
        -phase                                            => 'develop',
        -type                                             => 'requires',
        'Dist::Zilla::PluginBundle::Author::KENTNL::Lite' => 0,
      },
    ],
    [
      'Prereqs' => {
        -name                                             => 'BundleDevelRecommends',
        -phase                                            => 'develop',
        -type                                             => 'recommends',
        'Dist::Zilla::PluginBundle::Author::KENTNL::Lite' => __PACKAGE__->VERSION || '1.3.0',
      },
    ],
    [
      'Prereqs' => {
        -name                                       => 'BundleDevelSuggests',
        -phase                                      => 'develop',
        -type                                       => 'suggests',
        'Dist::Zilla::PluginBundle::Author::KENTNL' => '1.2.0',
      },
    ],
    _maybe( 'Author::KENTNL::MinimumPerl', [ 'Author::KENTNL::MinimumPerl' => { _only_fiveten( $arg, fiveten => 1 ) } ] ),
    _maybe( 'Author::KENTNL::Prereqs::Latest::Selective', [ 'Author::KENTNL::Prereqs::Latest::Selective' => {} ] ),
  );

  my (@mungers) = (
    [ 'PkgVersion'  => {} ],
    [ 'PodWeaver'   => {} ],
    [ 'NextRelease' => { time_zone => 'UTC', format => q[%v %{yyyy-MM-dd'T'HH:mm:ss}dZ] } ],

  );

  return (
    @version,
    @metadata,
    @sharedir,
    @gatherfiles,
    @prunefiles,
    @mungers,
    @regprereqs,
    _maybe( 'Authority', [ 'Authority' => { authority => $arg->{authority}, do_metadata => 1 } ] ),
    [ 'ModuleBuild' => {} ],
    _maybe( 'ReadmeFromPod', [ 'ReadmeFromPod' => {} ], ),
    _maybe(
      'ReadmeAnyFromPod',
      [
        'ReadmeAnyFromPod' => {
          type     => 'markdown',
          filename => 'README.mkdn',
          location => 'root',
        },
      ],
    ),
    _maybe( 'Test::CPAN::Changes', [ 'Test::CPAN::Changes' => {} ] ),
    _maybe( 'CheckExtraTests' => [ 'CheckExtraTests' => {} ], ),
    [ 'TestRelease' => {} ],
    [ 'FakeRelease' => {} ],
  );
}

sub bundle_config {
  my ( $self, $section ) = @_;
  my $class = ( ref $self ) || $self;

  # NO RELEASING. KTHX.
  ## no critic ( Variables::RequireLocalizedPunctuationVars )
  $ENV{DZIL_FAKERELEASE_FAIL} = 1;

  my $arg = $section->{payload};

  my @config = map { _expand( $class, $_->[0], $_->[1] ) } $class->bundle_config_inner($arg);

  return @config;
}
__PACKAGE__->meta->make_immutable;
no Moose;

## no critic (RequireEndWithOne)
'Thankyou for flying with KENTNL Lite!';

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::KENTNL::Lite - (DEPRECATED) A Minimal Build-Only replacement for @Author::KENTNL for contributors.

=head1 VERSION

version 2.001001

=head1 SYNOPSIS

    -[@Author::KENTNL]
    +[@Author::KENTNL::Lite]

    dzil build
    dzil test
    dzil release # BANG.

=head1 DEPRECATED

I'm no longer really keeping this up-to-date with my main bundle, and I've migrated to some other strategy.

Any of my distributions that ship a <dist.ini.meta> are now flattened out into C<dist.ini> so that no bundles are
implicated, and you can simply delete plugins that are inconveniencing you.

=head1 NAMING SCHEME

Please read my rant in L<Dist::Zilla::PluginBundle::Author::KENTNL/NAMING SCHEME> about the Author:: convention.

=head1 DESCRIPTION

This is an attempt at one way of solving a common problem when contributing to things built with
L<< C<Dist::Zilla>|Dist::Zilla >>.

This is done by assuming that the code base that its targeting will B<NEVER> be released in its built form,
but close enough to the normal build method that it's suitable for testing and contributing.

=over 4

=item * Less install time dependencies

=item * More phases in the C<PluginBundle> generation are 'optional'

=item * Less points of failure

=back

Good examples of things I've experienced in this category are the 2 following ( But awesome ) plug-ins that I use everywhere.

=head2 L<< The C<::Git> Plug-ins|Dist::Zilla::Plugin::Git >>

These plug-ins are great, don't get me wrong, but they pose a barrier for people on Win32, and in fact, anyone without a copy of
Git installed, ( Its hard enough getting a copy of the pre-release source without Git, but that's available in C<tar.gz> and
C<.zip> on C<github> ).

Working Copies of Git plug-ins are also nonessential if you're not building releases.

=head2 L<< The C<::Twitter> Plug-in|Dist::Zilla::Plugin::Twitter >>

Also, a handy plug-in to have, but you're not going to be needing it unless you're tweeting a release, and usually,
that means you're me.

Some of its dependencies have been known to fail tests on Windows platforms, and thus block automatic installation, so seeing
you don't have any use for this, its sensible to leave it out.

=head1 METHODS

=head2 bundle_config

See L<< the C<PluginBundle> role|Dist::Zilla::Role::PluginBundle >> for what this is for, it is a method to satisfy that role.

=for Pod::Coverage     mvp_multivalue_args
    bundle_config_inner

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
