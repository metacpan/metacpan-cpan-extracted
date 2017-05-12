package Pod::Weaver::PluginBundle::Author::MELO;

BEGIN {

  our $VERSION = '0.012'; # VERSION
  our $AUTHORITY = 'cpan:MELO'; # AUTHORITY
}

# ABSTRACT: MELO's Pod::Weaver config

use strict;
use warnings;
use Pod::Weaver 3.101633 ();
use Pod::Weaver::PluginBundle::Default ();
use Pod::Weaver::Plugin::StopWords 1.001005 ();
use Pod::Weaver::Plugin::Transformer ();
## TODO: do we really want this WikiDoc?
use Pod::Weaver::Plugin::WikiDoc 0.093002 ();
use Pod::Weaver::Section::Support 1.001   ();
use Pod::Elemental 0.102360               ();
use Pod::Elemental::Transformer::List ();

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub _plain {
  my ($plug, $arg) = (@_, {});
  (my $name = $plug) =~ s/^\W//;
  return [$name, _exp($plug), {%$arg}];
}

sub _bundle_name {
  my $class = @_ ? ref $_[0] || $_[0] : __PACKAGE__;
  join('', '@', ($class =~ /^.+::PluginBundle::(.+)$/));
}

sub mvp_bundle_config {
  ## ($self, $bundle) = @_; $bundle => {payload => {}, name => '@...'}
  my ($self) = @_;
  my @plugins;

  # NOTE: bundle name gets prepended to each plugin name at the end

  push @plugins, (

    # plugin
    _plain('-Encoding'),
    _plain('-WikiDoc'),

    # default
    _plain('@CorePrep'),

    # sections
    # default
    _plain('Name'),
    _plain('Version'),

    # Any pod inside a =begin/end :prelude will go at the top
    ['Prelude', _exp('Region'), {region_name => 'prelude'}],
  );

  push @plugins, map { $_->[2]{header} = uc($_->[0]); $_ } (

    # default
    ['Synopsis',    _exp('Generic'), {}],
    ['Description', _exp('Generic'), {}],
    ['Overview',    _exp('Generic'), {}],

    # extra
    ['Usage', _exp('Generic'), {}],

    # default
    ['Attributes',   _exp('Collect'), {command => 'attr'}],
    ['Constructors', _exp('Collect'), {command => 'constructor'}],
    ['Methods',      _exp('Collect'), {command => 'method'}],
    ['Functions',    _exp('Collect'), {command => 'func'}],
  );

  # default
  push @plugins, (
    _plain('Leftovers'),

    # see prelude above
    ['Postlude', _exp('Region'), {region_name => 'postlude'}],

    # include Support section with various cpan links and github repo
    [ 'Support',
      _exp('Support'),
      { email => 'melo',

        repository_link    => 'both',

        bugs => 'metadata',
        bugs_content => 'Please report any bugs or feature requests through the web interface at {WEB}. You will be automatically notified of any progress on the request by the system.',

        websites => [qw(metacpan testers testmatrix deps ratings)],
      }
    ],

    ['Acknowledgements', _exp('Generic'), {header => 'ACKNOWLEDGEMENTS'}],

    # default
    _plain('Authors'),
    _plain('Legal'),

    # plugins
    ['List', _exp('-Transformer'), {'transformer' => 'List'}],

    # my dictionary doesn't like that extra 'E' but it looks funny without it
    _plain('-StopWords', {include => 'ACKNOWLEDGEMENTS'}),
  );

  # prepend bundle name to each plugin name
  my $name = $self->_bundle_name;
  @plugins = map { $_->[0] = "$name/$_->[0]"; $_ } @plugins;

  return @plugins;
}

1;

__END__

=pod

=encoding utf-8

=for :stopwords Pedro Melo ACKNOWLEDGEMENTS

=head1 NAME

Pod::Weaver::PluginBundle::Author::MELO - MELO's Pod::Weaver config

=head1 VERSION

version 0.012

=head1 SYNOPSIS

  # weaver.ini
  [@Author::MELO]

or with a F<dist.ini> like so:

  # dist.ini
  [@Author::MELO]

you don't need a F<weaver.ini> at all.

=head1 DESCRIPTION

Another fork of the excellent work by RWSTASUNER.

This PluginBundle is like the @Default
with the following additions:

=over 4

=item *

Inserts a SUPPORT section to the POD just before AUTHOR

=item *

Adds the List Transformer

=item *

Enables WikiDoc formatting

=item *

Generates and collects stopwords

=back

It is roughly equivalent to:

  [Encoding]                ; prepend '=encoding utf-8' automatically
  [WikiDoc]                 ; transform wikidoc sections to POD
  [@CorePrep]               ; [@Default]

  [Name]                    ; [@Default]
  [Version]                 ; [@Default]

  [Region  / prelude]       ; [@Default]

  [Generic / SYNOPSIS]      ; [@Default]
  [Generic / DESCRIPTION]   ; [@Default]
  [Generic / OVERVIEW]      ; [@Default]
  [Generic / USAGE]         ; Put USAGE section near the top

  [Collect / ATTRIBUTES]    ; [@Default]
  command = attr

  [Collect / CONSTRUCTORS]
  command = constructor

  [Collect / METHODS]       ; [@Default]
  command = method

  [Collect / FUNCTIONS]     ; [@Default]
  command = func

  [Leftovers]               ; [@Default]

  [Region  / postlude]      ; [@Default]

  ; custom section
  [Support]                 ; =head1 SUPPORT (bugs, cpants, git...)
  repository_content =
  repository_link = both
  websites = testers, testmatrix, deps, ratings

  [Authors]                 ; [@Default]
  [Legal]                   ; [@Default]

  [-Transformer]            ; enable =for :list
  transformer = List

  [-StopWords]              ; generate some stopwords and gather them together

=encoding utf-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::MELO - MELO's Pod::Weaver config

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
