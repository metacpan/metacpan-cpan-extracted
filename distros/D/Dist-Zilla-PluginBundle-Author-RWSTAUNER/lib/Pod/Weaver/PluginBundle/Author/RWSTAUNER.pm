# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Zilla-PluginBundle-Author-RWSTAUNER
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Pod::Weaver::PluginBundle::Author::RWSTAUNER;
our $AUTHORITY = 'cpan:RWSTAUNER';
$Pod::Weaver::PluginBundle::Author::RWSTAUNER::VERSION = '6.001';
# ABSTRACT: RWSTAUNER's Pod::Weaver config

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub _plain {
  my ($plug, $arg) = (@_, {});
  (my $name = $plug) =~ s/^\W//;
  return [ $name, _exp($plug), { %$arg } ];
}

sub _bundle_name {
  my $class = @_ ? ref $_[0] || $_[0] : __PACKAGE__;
  join('', '@', ($class =~ /^.+::PluginBundle::(.+)$/));
}

sub _for {
  my ($region) = @_;
  [ $region, _exp('Region'),  { region_name => $region, allow_nonpod => 1, flatten => 0 } ],
}

sub mvp_bundle_config {
  ## ($self, $bundle) = @_; $bundle => {payload => {}, name => '@...'}
  my ($self) = @_;
  my @plugins;

  # NOTE: bundle name gets prepended to each plugin name at the end

  push @plugins, (
    # plugin
    _plain('-SingleEncoding'),
    _plain('-WikiDoc'),
    # default
    _plain('@CorePrep'),

    # sections
    # default
    _plain('Name'),
    _plain('Version'),

    # Any pod inside a =begin/end :prelude will go at the top
    [ 'Prelude',     _exp('Region'),  { region_name => 'prelude' } ],

    # Before Synopsis.
    _for('test_synopsis'),
  );

  for my $plugin (

    # default
    [ 'Synopsis',    _exp('Generic'), {} ],
    [ 'Description', _exp('Generic'), {} ],
    [ 'Overview',    _exp('Generic'), {} ],
    # extra
    [ 'Usage',       _exp('Generic'), {} ],

    ['Class Methods',_exp('Collect'), { command => 'class_method' } ], # header => 'CLASS METHODS',
    # default
    [ 'Attributes',  _exp('Collect'), { command => 'attr'   } ],
    [ 'Methods',     _exp('Collect'), { command => 'method' } ],
    [ 'Functions',   _exp('Collect'), { command => 'func'   } ],
  ) {
    $plugin->[2]{header} = uc $plugin->[0];
    push @plugins, $plugin;
  }

  # default
  push @plugins, (
    _plain('Leftovers'),
    # see prelude above
    [ 'Postlude',    _exp('Region'),    { region_name => 'postlude' } ],

    # TODO: consider SeeAlso if it ever allows comments with the links

    # extra
    # include Support section with various cpan links and github repo
    [ 'Support',     _exp('Support'),
      {
        ':version' => '1.005', # metacpan
        repository_content => '',
        repository_link => 'both',
        # metacpan links to everything else
        websites => [ qw(metacpan) ],
      }
    ],

    [ 'Acknowledgements', _exp('Generic'), {header => 'ACKNOWLEDGEMENTS'} ],

    _plain('Authors'),
    _plain('Contributors'),

    _plain('Legal'),

    # plugins
    [ 'List',        _exp('-Transformer'), { 'transformer' => 'List' } ],

    _plain('-StopWords', {
      ':version' => '1.005', # after =encoding
      # my dictionary doesn't like that extra 'E' but it looks funny without it
      include => 'ACKNOWLEDGEMENTS'
    }),
  );

  # prepend bundle name to each plugin name
  my $name = $self->_bundle_name;
  @plugins = map { $_->[0] = "$name/$_->[0]"; $_ } @plugins;

  return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS RWSTAUNER's PluginBundle

=head1 NAME

Pod::Weaver::PluginBundle::Author::RWSTAUNER - RWSTAUNER's Pod::Weaver config

=head1 VERSION

version 6.001

=head1 SYNOPSIS

  ; weaver.ini

  [@Author::RWSTAUNER]

or with a F<dist.ini> like so:

  ; dist.ini

  [@Author::RWSTAUNER]

you don't need a F<weaver.ini> at all.

=for Pod::Coverage mvp_bundle_config

=head1 ROUGHLY EQUIVALENT

This bundle is roughly equivalent to:

  [-SingleEncoding]
  [-WikiDoc]
  [@CorePrep]
  [Name]
  [Version]

  [Region / Prelude]
  region_name = prelude

  [Region / test_synopsis]
  allow_nonpod = 1
  flatten      = 0
  region_name  = test_synopsis

  [Generic / Synopsis]
  header = SYNOPSIS

  [Generic / Description]
  header = DESCRIPTION

  [Generic / Overview]
  header = OVERVIEW

  [Generic / Usage]
  header = USAGE

  [Collect / Class Methods]
  command = class_method
  header  = CLASS METHODS

  [Collect / Attributes]
  command = attr
  header  = ATTRIBUTES

  [Collect / Methods]
  command = method
  header  = METHODS

  [Collect / Functions]
  command = func
  header  = FUNCTIONS

  [Leftovers]

  [Region / Postlude]
  region_name = postlude

  [Support]
  :version           = 1.005
  repository_content =
  repository_link    = both
  websites           = metacpan

  [Generic / Acknowledgements]
  header = ACKNOWLEDGEMENTS

  [Authors]
  [Contributors]
  [Legal]

  [-Transformer / List]
  transformer = List

  [-StopWords]
  :version = 1.005
  include  = ACKNOWLEDGEMENTS

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
