package Dist::Zilla::Plugin::AddFile::FromCode;

our $DATE = '2015-06-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Capture::Tiny qw(capture);

use Moose;
with (
        'Dist::Zilla::Role::FileGatherer',
);

has code => (is => 'rw', required => 1);
has dest => (is => 'rw', required => 1);

use namespace::autoclean;

sub gather_files {
    require Dist::Zilla::File::InMemory;

    my ($self, $arg) = @_;

    $self->log_fatal("Please specify code") unless $self->code;
    $self->log_fatal("Please specify dest") unless $self->dest;

    my $file = Dist::Zilla::File::InMemory->new(
        name => $self->dest,
        content => do {
            my $err;
            my ($stdout, $stderr, $exit) = capture {
                eval $self->code;
                $err = $@;
            };
            $self->log_fatal(["Code dies: %s", $err]) if $err;
            $stdout;
        });

    $self->log(["Adding file from from code: %s", $self->dest]);
    $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add file from code's output

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AddFile::FromCode - Add file from code's output

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::AddFile::FromCode (from Perl distribution Dist-Zilla-Plugin-AddFile-FromCode), released on 2015-06-28.

=head1 SYNOPSIS

In F<dist.ini>:

 [AddFile::FromCode]
 code=print "hello\n" for 1..10;
 dest=share/somefile.txt

To add more files:

 [AddFile::FromCode / 2]
 code=print "world\n" for 1..20;
 dest=share/anotherfile.txt

=head1 DESCRIPTION

This plugin adds a file from output of code specified in F<dist.ini>.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::AddFile::FromFS>

L<Dist::Zilla::Plugin::AddFile::FromCommand>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-AddFile-FromCode>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-AddFile-FromCode>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AddFile-FromCode>

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
