package Pod::Weaver::PluginBundle::Author::HAYOBAAN;
use strict;
use warnings;

# ABSTRACT: HAYOBAAN's Pod::Weaver configuration
our $VERSION = '0.014'; # VERSION

#pod =head1 DESCRIPTION
#pod
#pod This is a L<Pod::Weaver> PluginBundle, set up according to HAYOBAAN's
#pod preferences.
#pod
#pod It's main features are:
#pod
#pod =begin :list
#pod
#pod * Specific sequence of headings
#pod
#pod * Region collectors for:
#pod
#pod =for :list
#pod * requires (Requirements)
#pod * var (Variables)
#pod * func (Functions)
#pod * c_attr (Class Attributes)
#pod * attr (Attributes)
#pod * construct (Constructors)
#pod * c_method (Class Methods)
#pod * method (Methods)
#pod
#pod * Replacing the original pod statements with comments, allowing line
#pod   numbers to stay the same between development and build versions.
#pod
#pod =end :list
#pod
#pod It is roughly equivalent to the following weaver.ini:
#pod
#pod   [@CorePrep]
#pod
#pod   [-SingleEncoding]
#pod   [-Transformer]
#pod   transformer = List
#pod
#pod   [Name]
#pod   [Version]
#pod
#pod   [Region / prelude]
#pod
#pod   [Generic / SYNOPSIS]
#pod   [Generic / DESCRIPTION]
#pod   [Generic / OVERVIEW]
#pod   [Generic / USAGE]
#pod   [Generic / OPTIONS]
#pod
#pod   [Collect / REQUIREMENTS]
#pod   command = requires
#pod
#pod   [Collect / VARIABLES]
#pod   command = var
#pod
#pod   [Collect / FUNCTIONS]
#pod   command = func
#pod
#pod   [Collect / CLASS ATTRIBUTES]
#pod   command = c_attr
#pod
#pod   [Collect / ATTRIBUTES]
#pod   command = attr
#pod
#pod   [Collect / CONSTRUCTORS]
#pod   command = construct
#pod
#pod   [Collect / CLASS METHODS]
#pod   command = c_method
#pod
#pod   [Collect / METHODS]
#pod   command = method
#pod
#pod   [Leftovers]
#pod
#pod   [Region /postlude]
#pod
#pod   [Bugs]
#pod   [Generic / STABILITY]
#pod   [Generic / COMPATIBILITY]
#pod   [Generic / SEE ALSO]
#pod   [Generic / CREDITS]
#pod   [Authors]
#pod   [Legal]
#pod
#pod =head1 USAGE
#pod
#pod Add the following line to your F<weaver.ini>:
#pod
#pod   [@Author::HAYOBAAN]
#pod
#pod or, these lines to your F<dist.ini> file:
#pod
#pod   [PodWeaver]
#pod   config_plugin = @Author::HAYOBAAN
#pod
#pod Alternatively you can also add the following line to your F<dist.ini>
#pod (this will also enable HAYOBAAN's L<Dist::Zilla> setup):
#pod
#pod   [@Author::HAYOBAAN]
#pod
#pod
#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Pod::Weaver>
#pod * L<Pod::Elemental::Transformer::List>
#pod * L<Pod::Elemental::PerlMunger>
#pod * L<Pod::Weaver::Section::Autor::HAYOBAAN::Bugs>
#pod * L<Dist::Zilla::Plugin::PodWeaver>
#pod
#pod =for Pod::Coverage mvp_bundle_config
#pod
#pod =cut

use Pod::Weaver::Config::Assembler;
sub _exp { return Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

# Required non-core Pod Weaver modules
use Pod::Elemental::Transformer::List ();
use Pod::Elemental::PerlMunger ();

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        [ '@HAYOBAAN/CorePrep',       _exp('@CorePrep'),       {} ],

        [ '@HAYOBAAN/SingleEncoding', _exp('-SingleEncoding'), {} ],
        [ '@HAYOBAAN/List',           _exp('-Transformer'),    { 'transformer' => 'List' } ],

        [ '@HAYOBAAN/Name',           _exp('Name'),            {} ],
        [ '@HAYOBAAN/Version',        _exp('Version'),         {} ],

        [ '@HAYOBAAN/Prelude',        _exp('Region'),          { region_name => 'prelude' } ],

        [ '@HAYOBAAN/Synopsis',       _exp('Generic'),         { header      => 'SYNOPSIS' } ],
        [ '@HAYOBAAN/Description',    _exp('Generic'),         { header      => 'DESCRIPTION' } ],
        [ '@HAYOBAAN/Overview',       _exp('Generic'),         { header      => 'OVERVIEW' } ],
        [ '@HAYOBAAN/Usage',          _exp('Generic'),         { header      => 'USAGE' } ],
        [ '@HAYOBAAN/Options',        _exp('Generic'),         { header      => 'OPTIONS' } ],
    );

    for my $plugin (
        [ 'Requirements',     _exp('Collect'), { command => 'requires' } ],
        [ 'Variables',        _exp('Collect'), { command => 'var' } ],
        [ 'Functions',        _exp('Collect'), { command => 'func' } ],
        [ 'Class Attributes', _exp('Collect'), { command => 'c_attr' } ],
        [ 'Attributes',       _exp('Collect'), { command => 'attr' } ],
        [ 'Constructors',     _exp('Collect'), { command => 'construct' } ],
        [ 'Class Methods',    _exp('Collect'), { command => 'c_method' } ],
        [ 'Methods',          _exp('Collect'), { command => 'method' } ],
    ) {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins, (
        [ '@HAYOBAAN/Leftovers',     _exp('Leftovers'),              {} ],

        [ '@HAYOBAAN/postlude',      _exp('Region'),                 { region_name => 'postlude' } ],

        [ '@HAYOBAAN/Bugs',          _exp('Author::HAYOBAAN::Bugs'), {} ],

        [ '@HAYOBAAN/Stability',     _exp('Generic'),                { header      => 'STABILITY' } ],
        [ '@HAYOBAAN/Compatibility', _exp('Generic'),                { header      => 'COMPATIBILITY' } ],

        [ '@HAYOBAAN/SeeAlso',       _exp('Generic'),                { header      => 'SEE ALSO' } ],
        [ '@HAYOBAAN/Credits',       _exp('Generic'),                { header      => 'CREDITS' } ],

        [ '@HAYOBAAN/Authors',       _exp('Authors'),                {} ],
        [ '@HAYOBAAN/Legal',         _exp('Legal'),                  {} ],
      );

    return @plugins;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::HAYOBAAN - HAYOBAAN's Pod::Weaver configuration

=head1 VERSION

version 0.014

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle, set up according to HAYOBAAN's
preferences.

It's main features are:

=over 4

=item *

Specific sequence of headings

=item *

Region collectors for:

=over 4

=item *

requires (Requirements)

=item *

var (Variables)

=item *

func (Functions)

=item *

c_attr (Class Attributes)

=item *

attr (Attributes)

=item *

construct (Constructors)

=item *

c_method (Class Methods)

=item *

method (Methods)

=back

=item *

Replacing the original pod statements with comments, allowing line numbers to stay the same between development and build versions.

=back

It is roughly equivalent to the following weaver.ini:

  [@CorePrep]

  [-SingleEncoding]
  [-Transformer]
  transformer = List

  [Name]
  [Version]

  [Region / prelude]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]
  [Generic / USAGE]
  [Generic / OPTIONS]

  [Collect / REQUIREMENTS]
  command = requires

  [Collect / VARIABLES]
  command = var

  [Collect / FUNCTIONS]
  command = func

  [Collect / CLASS ATTRIBUTES]
  command = c_attr

  [Collect / ATTRIBUTES]
  command = attr

  [Collect / CONSTRUCTORS]
  command = construct

  [Collect / CLASS METHODS]
  command = c_method

  [Collect / METHODS]
  command = method

  [Leftovers]

  [Region /postlude]

  [Bugs]
  [Generic / STABILITY]
  [Generic / COMPATIBILITY]
  [Generic / SEE ALSO]
  [Generic / CREDITS]
  [Authors]
  [Legal]

=head1 USAGE

Add the following line to your F<weaver.ini>:

  [@Author::HAYOBAAN]

or, these lines to your F<dist.ini> file:

  [PodWeaver]
  config_plugin = @Author::HAYOBAAN

Alternatively you can also add the following line to your F<dist.ini>
(this will also enable HAYOBAAN's L<Dist::Zilla> setup):

  [@Author::HAYOBAAN]

=for Pod::Coverage mvp_bundle_config

=head1 BUGS

Please report any bugs or feature requests on the bugtracker
L<website|https://github.com/HayoBaan/Dist-Zilla-PluginBundle-Author-HAYOBAAN/issues>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Elemental::Transformer::List>

=item *

L<Pod::Elemental::PerlMunger>

=item *

L<Pod::Weaver::Section::Autor::HAYOBAAN::Bugs>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=back

=head1 AUTHOR

Hayo Baan <info@hayobaan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Hayo Baan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
