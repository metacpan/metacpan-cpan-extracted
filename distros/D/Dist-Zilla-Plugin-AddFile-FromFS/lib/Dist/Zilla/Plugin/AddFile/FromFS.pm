package Dist::Zilla::Plugin::AddFile::FromFS;

our $DATE = '2015-07-01'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use strict;
use warnings;

use Moose;
with (
    'Dist::Zilla::Role::FileGatherer',
);

has src  => (is => 'rw', required => 1);
has dest => (is => 'rw', required => 1);

use namespace::autoclean;

sub gather_files {
    require Dist::Zilla::File::OnDisk;

    my ($self, $arg) = @_;

    $self->log_fatal("Please specify src")  unless $self->src;
    $self->log_fatal("Please specify dest") unless $self->dest;

    my @stat = stat $self->src
        or $self->log_fatal(["%s does not exist", $self->src]);

    my $fileobj = Dist::Zilla::File::OnDisk->new({
        name => $self->src,
        mode => $stat[2] & 0755, # kill world-writability
    });
    $fileobj->name($self->dest);

    $self->log(["Adding file from %s to %s", $self->src, $self->dest]);
    $self->add_file($fileobj);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add file from filesystem

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AddFile::FromFS - Add file from filesystem

=head1 VERSION

This document describes version 0.04 of Dist::Zilla::Plugin::AddFile::FromFS (from Perl distribution Dist-Zilla-Plugin-AddFile-FromFS), released on 2015-07-01.

=head1 SYNOPSIS

In F<dist.ini>:

 [AddFile::FromFS]
 src=/home/ujang/doc/tips.txt
 dest=share/tips.txt

To add more files:

 [AddFile::FromFS / OtherTips]
 src=/home/ujang/doc/othertips.txt
 dest=share/othertips.txt

=head1 DESCRIPTION

This plugin lets you add single file(s) from local filesystem to your build.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::GatherDir> is the standard way to add files to your
build, but this plugin currently does not offer a way to include single files.
Wishlist ticket already created:
L<https://rt.cpan.org/Ticket/Display.html?id=105583>

L<Dist::Zilla::Plugin::GenerateFile>

L<Dist::Zilla::Plugin::AddFile::FromCode>

L<Dist::Zilla::Plugin::AddFile::FromCommand>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-AddFile-FromFS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-AddFile-FromFS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AddFile-FromFS>

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
