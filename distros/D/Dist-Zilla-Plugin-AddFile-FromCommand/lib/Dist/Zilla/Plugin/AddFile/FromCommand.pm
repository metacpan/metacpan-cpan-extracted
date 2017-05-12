package Dist::Zilla::Plugin::AddFile::FromCommand;

our $DATE = '2015-06-28'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

use Capture::Tiny qw(capture);
use Proc::ChildError qw(explain_child_error);

use Moose;
with (
        'Dist::Zilla::Role::FileGatherer',
);

has cmd  => (is => 'rw', required => 1);
has dest => (is => 'rw', required => 1);

use namespace::autoclean;

sub gather_files {
    require Dist::Zilla::File::InMemory;

    my ($self, $arg) = @_;

    $self->log_fatal("Please specify cmd")  unless $self->cmd;
    $self->log_fatal("Please specify dest") unless $self->dest;

    my $file = Dist::Zilla::File::InMemory->new(
        name => $self->dest,
        content => do {
            my ($exit, $os_err);
            my ($stdout, $stderr, undef) = capture {
                system $self->cmd;
                ($exit, $os_err) = ($?, $!);
            };
            $self->log_fatal(["Command '%s' failed: %s", $self->cmd,
                              explain_child_error($exit, $os_err)]) if $exit;
            $stdout;
        });

    $self->log(["Adding file from from command output: %s", $self->dest]);
    $self->add_file($file);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Add file from command's output

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AddFile::FromCommand - Add file from command's output

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::AddFile::FromCommand (from Perl distribution Dist-Zilla-Plugin-AddFile-FromCommand), released on 2015-06-28.

=head1 SYNOPSIS

In F<dist.ini>:

 [AddFile::FromCommand]
 cmd=ls -l /home/ujang/projects/
 dest=share/ls.txt

To add more files:

 [AddFile::FromCommand / 2]
 code=netstat -anp | redact-ips
 dest=share/sample-netstat-output.txt

=head1 DESCRIPTION

This plugin adds a file from output of command specified in F<dist.ini>.

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::AddFile::FromFS>

L<Dist::Zilla::Plugin::AddFile::FromCode>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-AddFile-FromCommand>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-AddFile-FromCommand>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-AddFile-FromCommand>

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
