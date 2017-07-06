package Dist::Zilla::Plugin::PodnameFromFilename;

our $DATE = '2017-07-04'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':ExecFiles'],
    },
);

sub munge_files {
    my $self = shift;
    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    unless ($content =~ m{^#[ \t]*PODNAME:[ \t]*([^\n]*)[ \t]*$}m) {
        $self->log_debug(["skipping %s: no # PODNAME directive found", $file->name]);
        return;
    }

    my $podname = $1;
    if ($podname =~ /\S/) {
        $self->log_debug(["skipping %s: # PODNAME already filled (%s)", $file->name, $podname]);
        return;
    }

    ($podname = $file->name) =~ s!.+/!!;

    $content =~ s{^#\s*PODNAME:.*}{# PODNAME: $podname}m
        or die "Can't insert podname for " . $file->name;
    $self->log(["inserting podname for %s (%s)", $file->name, $podname]);
    $file->content($content);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Fill out # PODNAME from filename

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PodnameFromFilename - Fill out # PODNAME from filename

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::PodnameFromFilename (from Perl distribution Dist-Zilla-Plugin-PodnameFromFilename), released on 2017-07-04.

=head1 SYNOPSIS

In C<dist.ini>:

 [PodnameFromFilename]

In your module/script:

 # PODNAME:

During build, PODNAME will be filled from filename. If PODNAME is already
filled, will leave it alone.

=head1 DESCRIPTION

It's yet another DRY plugin. It's annoying that in scripts like
C<bin/some-progname> you have to specify:

 # PODNAME: some-progname

With this plugin, the value of PODNAME directive will be filled from filename
(unless it has been set explicitly).

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PodnameFromFilename>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PodnameFromFilename>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PodnameFromFilename>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<https://github.com/rjbs/Pod-Weaver/issues/29>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2014 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
