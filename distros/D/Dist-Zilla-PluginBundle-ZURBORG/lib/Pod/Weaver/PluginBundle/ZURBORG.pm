use strictures 2;

package Pod::Weaver::PluginBundle::ZURBORG;

# ABSTRACT: a bundle that add Bugs section to the Default bundle

our $VERSION = '0.007'; # VERSION

use namespace::autoclean;

use Pod::Weaver::Config::Assembler;


sub mvp_bundle_config {
    return map {
        $_->[1] = Pod::Weaver::Config::Assembler->expand_package( $_->[1] );
        $_;
      } (
        [ '@Default/CorePrep', '@CorePrep', {} ],
        [ '@Default/Name',     'Name',      {} ],
        [ '@Default/Version',  'Version',   {} ],
        [
            '@Default/prelude',
            'Region',
            {
                region_name => 'prelude'
            }
        ],
        [ 'SYNOPSIS',    'Generic', {} ],
        [ 'DESCRIPTION', 'Generic', {} ],
        [ 'OVERVIEW',    'Generic', {} ],
        [
            'ATTRIBUTES',
            'Collect',
            {
                command => 'attr'
            }
        ],
        [
            'METHODS',
            'Collect',
            {
                command => 'method'
            }
        ],
        [
            'FUNCTIONS',
            'Collect',
            {
                command => 'func'
            }
        ],
        [ '@Default/Leftovers', 'Leftovers', {} ],
        [
            '@Default/postlude',
            'Region',
            {
                region_name => 'postlude'
            }
        ],
        [ '@Default/Bugs',    'Bugs',    {} ],
        [ '@Default/Authors', 'Authors', {} ],
        [ '@Default/Legal',   'Legal',   {} ],
      );
}

1;

__END__

=pod

=head1 NAME

Pod::Weaver::PluginBundle::ZURBORG - a bundle that add Bugs section to the Default bundle

=head1 VERSION

version 0.007

=head1 METHODS

=head2 mvp_bundle_config

Config method for Pod::Weaver

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/zurborg/libdist-zilla-pluginbundle-zurborg-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by David Zurborg <zurborg@cpan.org>.

This is free software, licensed under:

  The ISC License

=cut
