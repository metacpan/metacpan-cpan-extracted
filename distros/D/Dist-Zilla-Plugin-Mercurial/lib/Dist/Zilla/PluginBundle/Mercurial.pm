package Dist::Zilla::PluginBundle::Mercurial;
$Dist::Zilla::PluginBundle::Mercurial::VERSION = '0.08';
use strict;
use warnings;

use Moose;

with 'Dist::Zilla::Role::PluginBundle';

my @names   = qw{ Check Tag Push };

sub bundle_config {
    my $self = shift;
    my $section = shift;

    my @config;

    for my $name (@names) {
        my $class = "Dist::Zilla::Plugin::Mercurial::$name";

        push @config, [ "$section->{name}/$name" => $class => {} ];
    }

    return @config;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Bundles the Mercurial Check, Tag, and Push plugins

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Mercurial - Bundles the Mercurial Check, Tag, and Push plugins

=head1 VERSION

version 0.08

=head1 SYNOPSIS

In your F<dist.ini>:

  [@Mercurial]

=head1 DESCRIPTION

This is a plugin bundle to load all git plugins. It is equivalent to:

  [Mercurial::Check]
  [Mercurial::Tag]
  [Mercurial::Push]

=for Pod::Coverage bundle_config

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
