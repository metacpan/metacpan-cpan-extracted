use strict;
use warnings;

package Pod::Weaver::PluginBundle::NGLENN;

our $VERSION = '0.07';

use Pod::Weaver 4; # he played knick-knack on my door
use Pod::Weaver::Config::Assembler;

# Dependencies
use Pod::Weaver::Plugin::WikiDoc ();
use Pod::Elemental::Transformer::List 0.102000 ();
use Pod::Elemental::PerlMunger 0.200001        (); # replace with comment support
use Pod::Weaver::Section::Support 1.001        ();
use Pod::Weaver::Section::Contributors 0.008   ();

sub _exp { Pod::Weaver::Config::Assembler->expand_package( $_[0] ) }

my $repo_intro = <<'END';
This is open source software.  The code repository is available for
public review and contribution under the terms of the license.
END

my $bugtracker_content = <<'END';
Please report any bugs or feature requests through the issue tracker
at {WEB}.
You will be notified automatically of any progress on your issue.
END

sub mvp_bundle_config {
    my @plugins;
    push @plugins, (
        [ '@NGLENN/SingleEncoding', _exp('-SingleEncoding'), {} ],
        [ '@NGLENN/WikiDoc',        _exp('-WikiDoc'),        {} ],
        [ '@NGLENN/CorePrep',       _exp('@CorePrep'),       {} ],
        [ '@NGLENN/Name',           _exp('Name'),            {} ],
        [ '@NGLENN/Version',        _exp('Version'),         {} ],

        [ '@NGLENN/Prelude',     _exp('Region'),  { region_name => 'prelude' } ],
        [ '@NGLENN/Synopsis',    _exp('Generic'), { header      => 'SYNOPSIS' } ],
        [ '@NGLENN/Description', _exp('Generic'), { header      => 'DESCRIPTION' } ],
        [ '@NGLENN/Usage',       _exp('Generic'), { header      => 'USAGE' } ],
        [ '@NGLENN/Overview',    _exp('Generic'), { header      => 'OVERVIEW' } ],
        [ '@NGLENN/Stability',   _exp('Generic'), { header      => 'STABILITY' } ],
    );

    for my $plugin (
        [ 'Requirements', _exp('Collect'), { command => 'requires' } ],
        [ 'Attributes',   _exp('Collect'), { command => 'attr' } ],
        [ 'Constructors', _exp('Collect'), { command => 'construct' } ],
        [ 'Methods',      _exp('Collect'), { command => 'method' } ],
        [ 'Functions',    _exp('Collect'), { command => 'func' } ],
      )
    {
        $plugin->[2]{header} = uc $plugin->[0];
        push @plugins, $plugin;
    }

    push @plugins,
      (
        [ '@NGLENN/Leftovers', _exp('Leftovers'), {} ],
        [ '@NGLENN/postlude', _exp('Region'), { region_name => 'postlude' } ],
        [
            '@NGLENN/Support',
            _exp('Support'),
            {
                perldoc            => 0,
                websites           => 'none',
                bugs               => 'metadata',
                bugs_content       => $bugtracker_content,
                repository_link    => 'both',
                repository_content => $repo_intro
            }
        ],
        [ '@NGLENN/Authors',      _exp('Authors'),      {} ],
        [ '@NGLENN/Contributors', _exp('Contributors'), {} ],
        [ '@NGLENN/Legal',        _exp('Legal'),        {} ],
        [ '@NGLENN/List', _exp('-Transformer'), { 'transformer' => 'List' } ],
      );

    return @plugins;
}

# ABSTRACT: NGLENN's default Pod::Weaver config
#
# This file is part of Dist-Zilla-PluginBundle-NGLENN
#
# This software is Copyright (c) 2017 by Nathan Glenn.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::NGLENN - NGLENN's default Pod::Weaver config

=head1 VERSION

version 0.07

=head1 DESCRIPTION

This is a L<Pod::Weaver> PluginBundle.  It is roughly equivalent to the
following weaver.ini:

  [-WikiDoc]

  [@Default]

  [Support]
  perldoc = 0
  websites = none
  bugs = metadata
  bugs_content = ... stuff (web only, email omitted) ...
  repository_link = both
  repository_content = ... stuff ...

  [Contributors]

  [-Transformer]
  transformer = List

=head1 USAGE

This PluginBundle is used automatically with the C<@NGLENN> L<Dist::Zilla>
plugin bundle.

It also has region collectors for:

=over 4

=item *

requires

=item *

construct

=item *

attr

=item *

method

=item *

func

=back

=for Pod::Coverage mvp_bundle_config

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::Plugin::WikiDoc>

=item *

L<Pod::Elemental::Transformer::List>

=item *

L<Pod::Weaver::Section::Contributors>

=item *

L<Pod::Weaver::Section::Support>

=item *

L<Dist::Zilla::Plugin::PodWeaver>

=back

=head1 AUTHOR

Nate Glenn <nglenn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Nathan Glenn.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
