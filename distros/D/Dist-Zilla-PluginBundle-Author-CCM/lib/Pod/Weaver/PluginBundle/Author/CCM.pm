package Pod::Weaver::PluginBundle::Author::CCM;
# ABSTRACT: A plugin bundle for pod woven by CCM


use 5.008;
use warnings;
use strict;

our $VERSION = '0.008001'; # VERSION

use Pod::Weaver::Config::Assembler;
use namespace::autoclean;


sub configure {
    return (
        ['-EnsurePod5'],
        ['-H1Nester'],
        ['-SingleEncoding'],

        ['-Transformer' => List     => {transformer => 'List'}],
        ['-Transformer' => Verbatim => {transformer => 'Verbatim'}],

        ['Region' => 'header'],

        'Name',
        # ['Badges' => {badge => [qw(perl travis coverage)], formats => 'html, markdown'}],

        'Version',

        ['Region' => 'prelude'],

        ['Generic' => 'SYNOPSIS'],
        ['Generic' => 'DESCRIPTION'],
        ['Generic' => 'OVERVIEW'],
        ['Collect' => 'ATTRIBUTES' => {command => 'attr'}],
        ['Collect' => 'METHODS'    => {command => 'method'}],
        ['Collect' => 'FUNCTIONS'  => {command => 'func'}],

        'Leftovers',

        ['Region' => 'postlude'],

        'Bugs',
        'Authors',
        'Contributors',
        'Legal',

        ['Region' => 'footer'],
    );
}


sub mvp_bundle_config {
    my $self = shift || __PACKAGE__;

    return map { $self->_expand_config($_) } $self->configure;
}

sub _exp { Pod::Weaver::Config::Assembler->expand_package($_[0]) }

sub _expand_config {
    my $self = shift;
    my $spec = shift;

    my ($name, $package, $payload);

    if (!ref $spec) {
        ($name, $package, $payload) = ($spec, $spec, {});
    }
    elsif (@$spec == 1) {
        ($name, $package, $payload) = (@$spec[0,0], {});
    }
    elsif (@$spec == 2) {
        ($name, $package, $payload) = ref $spec->[1] ? @$spec[0,0,1] : (@$spec[1,0], {});
    }
    else {
        ($package, $name, $payload) = @$spec;
    }

    $name =~ s/^[@=-]//;
    $package = _exp($package);

    if ($package eq _exp('Region')) {
        $name = $spec->[1];
        $payload = {region_name => $spec->[1], %$payload};
    }

    $name = '@Author::CCM/' . $name if $package ne _exp('Generic') && $package ne _exp('Collect');

    return [$name => $package => $payload];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::Author::CCM - A plugin bundle for pod woven by CCM

=head1 VERSION

version 0.008001

=head1 SYNOPSIS

    # In your weaver.ini file:
    [@Author::CCM]

    # In your dist.ini file:
    [PodWeaver]
    config_plugin = @Author::CCM

=head1 DESCRIPTION

You probably don't want to use this.

=head1 METHODS

=head2 configure

Returns the configuration in a form similar to what one might use with
L<Dist::Zilla::Role::PluginBundle::Easy/add_plugins>.

=head2 mvp_bundle_config

Required in order to be a plugin bundle.

=head1 SEE ALSO

=over 4

=item *

L<Pod::Weaver>

=item *

L<Pod::Weaver::PluginBundle::Author::ETHER>

=back

=head1 CREDITS

This module was heavily inspired by Karen Etheridge's config.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/Dist-Zilla-PluginBundle-Author-CCM/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <chazmcgarvey@brokenzipper.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
