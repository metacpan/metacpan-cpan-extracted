use strict;
use warnings;
package Pod::Weaver::PluginBundle::NoAuthor;
# ABSTRACT: the Default plugin bundle, with the Authors section removed
$Pod::Weaver::PluginBundle::NoAuthor::VERSION = '0.005';
#pod =head1 OVERVIEW
#pod
#pod This is a slight modification of Pod::Weaver::PluginBundle::Default, with the
#pod AUTHORS section removed.
#pod
#pod =cut

use namespace::autoclean;

use Pod::Weaver::Config::Assembler;
sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
  return (
    [ '@Default/CorePrep',        _exp('@CorePrep'), {} ],
    [ '@Default/SingleEncoding',  _exp('-SingleEncoding'), {} ],
    [ '@Default/Name',            _exp('Name'),      {} ],
    [ '@Default/Version',         _exp('Version'),   {} ],

    [ '@Default/prelude',   _exp('Region'),    { region_name => 'prelude'  } ],
    [ 'SYNOPSIS',           _exp('Generic'),   {} ],
    [ 'DESCRIPTION',        _exp('Generic'),   {} ],
    [ 'OVERVIEW',           _exp('Generic'),   {} ],

    [ 'ATTRIBUTES',         _exp('Collect'),   { command => 'attr'   } ],
    [ 'METHODS',            _exp('Collect'),   { command => 'method' } ],
    [ 'FUNCTIONS',          _exp('Collect'),   { command => 'func'   } ],

    [ '@Default/Leftovers', _exp('Leftovers'), {} ],

    [ '@Default/postlude',  _exp('Region'),    { region_name => 'postlude' } ],

    [ '@Default/Legal',     _exp('Legal'),     {} ],
  )
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::NoAuthor - the Default plugin bundle, with the Authors section removed

=head1 VERSION

version 0.005

=head1 AUTHOR

Andreas K. Huettel <dilfridge@gentoo.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Andreas K. Huettel.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
