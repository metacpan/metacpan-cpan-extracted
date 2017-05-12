#ABSTRACT: Pod::Weaver configuration for AJGB
use strict;
use warnings;
package Pod::Weaver::PluginBundle::AJGB;
our $AUTHORITY = 'cpan:AJGB';
$Pod::Weaver::PluginBundle::AJGB::VERSION = '2.04';
use Pod::Weaver::Config::Assembler;


sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub mvp_bundle_config {
    return (
        [ '@AJGB/CorePrep',     _exp('@CorePrep'),  {} ],

        [ '@AJGB/Encoding',     _exp('-SingleEncoding'),  {} ],

        [ '@AJGB/Name',         _exp('Name'),       {} ],
        [ '@AJGB/Version',      _exp('Version'),    {} ],


        [ '@AJGB/Prelude',      _exp('Region'),     { region_name   => 'prelude'        } ],

        [ '@AJGB/Synopsis',     _exp('Generic'),    { header        => 'SYNOPSIS'       } ],
        [ '@AJGB/Description',  _exp('Generic'),    { header        => 'DESCRIPTION'    } ],
        [ '@AJGB/Overview',     _exp('Generic'),    { header        => 'OVERVIEW'       } ],


        [ 'ATTRIBUTES',         _exp('Collect'),    { command       => 'attr'           } ],
        [ 'METHODS',            _exp('Collect'),    { command       => 'method'         } ],
        [ 'FUNCTIONS',          _exp('Collect'),    { command       => 'func'           } ],
        [ 'TYPES',              _exp('Collect'),    { command       => 'type'           } ],

        [ '@AJGB/Leftovers',    _exp('Leftovers'),  {} ],

        [ '@AJGB/Postlude',     _exp('Region'),     { region_name   => 'postlude'       } ],

        [ '@AJGB/Authors',      _exp('Authors'),    {} ],
        [ '@AJGB/Legal',        _exp('Legal'),      {} ],
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::AJGB - Pod::Weaver configuration for AJGB

=head1 VERSION

version 2.04

=head1 DESCRIPTION

Pod::Weaver configuration used by L<Dist::Zilla::PluginBundle::AJGB>.

=for Pod::Coverage mvp_bundle_config

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
