package Dist::Zilla::Plugin::SetScriptShebang;

our $DATE = '2014-08-16'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [ ':ExecFiles' ],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    # should not be necessary because we've filtered for ExecFiles in finder
    #unless ($file->name =~ m!^(bin|scripts?)/!) {
    #    $self->log_debug('Skipping ' . $file->name . ': not script');
    #    return;
    #}

    my $content = $file->content;

    unless ($content =~ /\A#!/) {
        $self->log_debug('Skipping ' . $file->name . ': does not contain shebang');
        return;
    }
    if ($content =~ /\A#!perl$/m) {
        $self->log_debug('Skipping ' . $file->name . ': already #!perl');
        return;
    }

    $content =~ s/\A#!.+/#!perl/;
    $self->log('Setting shebang in script '. $file->name . ' to #!perl');

    $file->content($content);
    return;
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Set script shebang to #!perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::SetScriptShebang - Set script shebang to #!perl

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::SetScriptShebang (from Perl distribution Dist-Zilla-Plugin-SetScriptShebang), released on 2014-08-16.

=head1 SYNOPSIS

In C<dist.ini>:

 [SetScriptShebang]

=head1 DESCRIPTION

This plugin sets all script's shebang line to C<#!perl>. Some shebang lines like
C<#!/usr/bin/env perl> are problematic because they do not get converted to the
path of installed perl during installation. This sometimes happens when I
package one of my Perl scripts (which uses C<#!/usr/bin/env perl>) into a Perl
distribution, and forget to update the shebang line.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-SetScriptShebang>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Dist-Zilla-Plugin-SetScriptShebang>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-SetScriptShebang>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
