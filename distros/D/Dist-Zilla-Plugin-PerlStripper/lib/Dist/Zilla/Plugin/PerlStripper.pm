package Dist::Zilla::Plugin::PerlStripper;

our $DATE = '2015-02-23'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

has maintain_linum => (is=>'rw');
has strip_ws => (is=>'rw');
has strip_comment => (is=>'rw');
has strip_pod => (is=>'rw');
has strip_log => (is=>'rw');
has stripped_log_levels => (is=>'rw');
# XXX exclude/include files

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
    return;
}

sub munge_file {
    my ($self, $file) = @_;

    state $stripper = do {
        require Perl::Stripper;
        my %args;
        if (defined $self->maintain_linum) {
            $args{maintain_linum} = $self->maintain_linum;
        }
        if (defined $self->strip_ws) {
            $args{strip_ws} = $self->strip_ws;
        }
        if (defined $self->strip_comment) {
            $args{strip_comment} = $self->strip_comment;
        }
        if (defined $self->strip_pod) {
            $args{strip_pod} = $self->strip_pod;
        }
        if (defined $self->strip_log) {
            $args{strip_log} = $self->strip_log;
        }
        if (defined $self->stripped_log_levels) {
            $args{stripped_log_levels} = [split /\s*,\s*/,
                                          $self->stripped_log_levels];
        }
        Perl::Stripper->new(%args);
    };

    if ($file->name =~ m/\.pod$/ixms) {
        $self->log_debug('Skipping: "' . $file->name . '" is pod only');
        return;
    }

    my $content = $file->content;
    my $stripped = $stripper->strip($content);
    if ($content ne $stripped) {
        $self->log(['Stripped %s', $file->name]);
        $file->content($stripped);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Strip your modules/scripts with Perl::Stripper

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PerlStripper - Strip your modules/scripts with Perl::Stripper

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::PerlStripper (from Perl distribution Dist-Zilla-Plugin-PerlStripper), released on 2015-02-23.

=head1 SYNOPSIS

In dist.ini:

 [PerlStripper]

=head1 DESCRIPTION

This module lets you strip your modules/scripts with L<Perl::Stripper> during
build.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head2 maintain_linum => bool

=head2 strip_ws => bool

=head2 strip_comment => bool

=head2 strip_pod => bool

=head2 strip_log => bool

=head2 stripped_log_levels => str

Comma-separated string.

=head1 SEE ALSO

L<Dist::Zilla>

L<Perl::Stripper>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PerlStripper>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PerlStripper>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PerlStripper>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
