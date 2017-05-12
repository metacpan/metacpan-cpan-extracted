#
# This file is part of Dist-Zilla-PluginBundle-Author-Celogeek
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Pod::Weaver::PluginBundle::Celogeek;

use strict;
use warnings;

# ABSTRACT: a bundle that add Bugs section to the Default bundle
our $VERSION = '1.1';    # VERSION

use namespace::autoclean;

use Pod::Weaver::Config::Assembler;

sub _exp {
    my $package = shift;
    return Pod::Weaver::Config::Assembler->expand_package($package);
}

sub mvp_bundle_config {
    return (
        [ '@Default/CorePrep', _exp('@CorePrep'), {} ],
        [ '@Default/Name',     _exp('Name'),      {} ],
        [ '@Default/Version',  _exp('Version'),   {} ],

        [ '@Default/prelude', _exp('Region'),  { region_name => 'prelude' } ],
        [ 'SYNOPSIS',         _exp('Generic'), {} ],
        [ 'DESCRIPTION',      _exp('Generic'), {} ],
        [ 'OVERVIEW',         _exp('Generic'), {} ],

        [ 'ATTRIBUTES', _exp('Collect'), { command => 'attr' } ],
        [ 'METHODS',    _exp('Collect'), { command => 'method' } ],
        [ 'FUNCTIONS',  _exp('Collect'), { command => 'func' } ],

        [ '@Default/Leftovers', _exp('Leftovers'), {} ],

        [   '@Default/postlude', _exp('Region'), { region_name => 'postlude' }
        ],

        [ '@Default/Bugs',    _exp('Bugs'),    {} ],
        [ '@Default/Authors', _exp('Authors'), {} ],
        [ '@Default/Legal',   _exp('Legal'),   {} ],
    );
}

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::Celogeek - a bundle that add Bugs section to the Default bundle

=head1 VERSION

version 1.1

=head1 OVERVIEW

This bundle is equivalent to : (default + Bugs section)

  [@CorePrep]

  [Name]
  [Version]

  [Region  / prelude]

  [Generic / SYNOPSIS]
  [Generic / DESCRIPTION]
  [Generic / OVERVIEW]

  [Collect / ATTRIBUTES]
  command = attr

  [Collect / METHODS]
  command = method

  [Leftovers]

  [Region  / postlude]

  [Bugs]
  [Authors]
  [Legal]

=head1 METHODS

=head2 mvp_bundle_config

Config method for Pod::Weaver

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/dist-zilla-pluginbundle-author-celogeek/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
