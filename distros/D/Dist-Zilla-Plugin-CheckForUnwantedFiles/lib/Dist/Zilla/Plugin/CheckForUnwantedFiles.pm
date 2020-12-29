use 5.14.0;
use strict;
use warnings;

package Dist::Zilla::Plugin::CheckForUnwantedFiles;

# ABSTRACT: Check for unwanted files
our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.0100';

use Moose;
use namespace::autoclean;
use Path::Tiny;
use Types::Standard qw/ArrayRef/;

with qw/
    Dist::Zilla::Role::AfterBuild
/;

has unwanted_file => (
    is => 'ro',
    isa => ArrayRef,
    default => sub { [] },
);

sub mvp_multivalue_args { qw/unwanted_file/ }

sub after_build {
    my $self = shift;
    my $root_path = path('.');

    my @existing_unwanted_paths = ();
    for my $unwanted (@{ $self->unwanted_file }) {
        push @existing_unwanted_paths => $unwanted if $root_path->child($unwanted)->exists;
    }

    if (scalar @existing_unwanted_paths) {
        $self->log('The following unwanted files exist:');
        for my $unwanted (@existing_unwanted_paths) {
            $self->log("* $unwanted");
        }
        $self->log_fatal('Build aborted.');
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::CheckForUnwantedFiles - Check for unwanted files



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.14+-blue.svg" alt="Requires Perl 5.14+" />
<img src="https://img.shields.io/badge/coverage-93.6%25-yellow.svg" alt="coverage 93.6%" />
<a href="https://github.com/Csson/p5-Dist-Zilla-Plugin-CheckForUnwantedFiles/actions?query=workflow%3Amakefile-test"><img src="https://img.shields.io/github/workflow/status/Csson/p5-Dist-Zilla-Plugin-CheckForUnwantedFiles/makefile-test" alt="Build status at Github" /></a>
</p>

=end html

=head1 VERSION

Version 0.0100, released 2020-12-29.

=head1 SYNOPSIS

In C<dist.ini> (though it is more useful in a C<PluginBundle>):

    [CheckForUnwantedFiles]
    unwanted_file = .travis.yml
    unwanted_file = .github/

=head1 DESCRIPTION

This plugin checks the development directory (not the build directory) for unwanted files. This is useful when, for instance, switching CI providers, and you don't
want to have the previous provider's configuration files lingering around B<and> you are too forgetful to remember to check for them
when doing a new release after the switch.

It is run at the C<AfterBuild> stage, and takes one (repeatable) argument: C<unwanted_file>. It is a fatal error if any unwanted file is found.
And, despite its name, it works just as well with unwanted directories.

So:

=over 4

=item 1

Remove the plugin that generates the file from the bundle

=item 2

Add this plugin to the bundle

=item 3

Add the path to the file gets generated as an C<unwanted_file>

=item 4

You must delete the unwanted file before the distribution can be built

=back

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Zilla-Plugin-CheckForUnwantedFiles>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Zilla-Plugin-CheckForUnwantedFiles>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
