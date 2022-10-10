package Dist::Zilla::Plugin::DROLSKY::BundleAuthordep;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '1.22';

use Path::Tiny qw( path );

use Moose;

with 'Dist::Zilla::Role::BeforeBuild';

# These files need to actually exist on disk for the Pod::Weaver plugin to see
# them, so we can't simply add them as InMemory files via file injection.
sub before_build {
    my $self = shift;

    my $dist_ini = path('dist.ini');
    my $content  = $dist_ini->slurp_utf8;
    my ($v)
        = $content
        =~ /; authordep Dist::Zilla::PluginBundle::DROLSKY = ([0-9]+\.[0-9]+)/;

    return if $v && $v == $VERSION;

    if ($v) {
        $content
            =~ s/(; authordep Dist::Zilla::PluginBundle::DROLSKY = )\Q$v\E/$1$VERSION/;
    }
    else {
        $content
            =~ s/(\[\@DROLSKY\])/; authordep Dist::Zilla::PluginBundle::DROLSKY = $VERSION\n$1/;
    }

    $dist_ini->spew_utf8($content);

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Sets an authordep on this bundle in the dist.ini

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DROLSKY::BundleAuthordep - Sets an authordep on this bundle in the dist.ini

=head1 VERSION

version 1.22

=for Pod::Coverage .*

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY/issues>.

=head1 SOURCE

The source code repository for Dist-Zilla-PluginBundle-DROLSKY can be found at L<https://github.com/autarch/Dist-Zilla-PluginBundle-DROLSKY>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2022 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
