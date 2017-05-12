package Pod::Weaver::PluginBundle::CHIM;

# ABSTRACT: CHIM's default Pod::Weaver configuration

use strict;
use warnings;

our $VERSION = '0.052005'; # VERSION
our $AUTHORITY = 'cpan:CHIM'; # AUTHORITY

use namespace::autoclean;

use Pod::Weaver 4;
use Pod::Weaver::Config::Assembler;
use Pod::Weaver::Section::SeeAlso;



sub _exp {
    my ( $package ) = @_;
    return Pod::Weaver::Config::Assembler->expand_package( $package );
}


sub mvp_bundle_config {
    return (
        [ '@CHIM/SingleEncoding',   _exp('-SingleEncoding'), {} ],
        [ '@CHIM/CorePrep',         _exp('@CorePrep'), {} ],
        [ '@CHIM/Name',             _exp('Name'),      {} ],
        [ '@CHIM/Version',          _exp('Version'),   {} ],

        [ '@CHIM/prelude',          _exp('Region'),  { region_name => 'prelude' } ],

        [ 'SYNOPSIS',               _exp('Generic'), {} ],
        [ 'DESCRIPTION',            _exp('Generic'), {} ],
        [ 'OVERVIEW',               _exp('Generic'), {} ],

        [ 'TYPES',                  _exp('Collect'), { command => 'type' } ],
        [ 'ATTRIBUTES',             _exp('Collect'), { command => 'attr' } ],
        [ 'METHODS',                _exp('Collect'), { command => 'method' } ],
        [ 'FUNCTIONS',              _exp('Collect'), { command => 'func' } ],

        [ '@CHIM/Leftovers',        _exp('Leftovers'), {} ],

        [ '@CHIM/postlude',         _exp('Region'), { region_name => 'postlude' } ],

        [ '@CHIM/SeeAlso',          _exp('SeeAlso'), {} ],
        [ '@CHIM/Bugs',             _exp('Bugs'),    {} ],
        [ '@CHIM/Authors',          _exp('Authors'), {} ],
        [ '@CHIM/Legal',            _exp('Legal'),   {} ],
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::CHIM - CHIM's default Pod::Weaver configuration

=head1 VERSION

version 0.052005

=head1 SYNOPSIS

In C<weaver.ini>

    [@CHIM]

or in C<dist.ini>

    [PodWeaver]
    config_plugin = @CHIM

=head1 DESCRIPTION

This is config for L<Pod::Weaver> I use to build documentation for my modules.

=head1 OVERVIEW

This plugin bundle is equivalent to the following C<weaver.ini> config:

    [-SingleEnconding]

    [@CorePrep]

    [Name]
    [Version]

    [Region / prelude]

    [Generic / SYNOPSIS]
    [Generic / DESCRIPTION]
    [Generic / OVERVIEW]

    [Collect / TYPES]
    command = type

    [Collect / ATTRIBUTES]
    command = attr

    [Collect / METHODS]
    command = method

    [Collect / FUNCTIONS]
    command = func

    [Leftovers]

    [Region / postlude]

    [SeeAlso]
    [Bugs]
    [Author]
    [Legal]

=for Pod::Coverage _exp

=for Pod::Coverage mvp_bundle_config

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::Author::CHIM|Dist::Zilla::PluginBundle::Author::CHIM>

=item *

L<Pod::Weaver|Pod::Weaver>

=item *

L<Dist::Zilla::Plugin::PodWeaver|Dist::Zilla::Plugin::PodWeaver>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/Wu-Wu/Dist-Zilla-PluginBundle-Author-CHIM/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Anton Gerasimov <chim@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Anton Gerasimov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
