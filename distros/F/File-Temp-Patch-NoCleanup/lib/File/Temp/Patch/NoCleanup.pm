package File::Temp::Patch::NoCleanup;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-04'; # DATE
our $DIST = 'File-Temp-Patch-NoCleanup'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Module::Patch qw();
use base qw(Module::Patch);

my $wrap_tempdir = sub {
    my $ctx = shift;
    my $orig = $ctx->{orig};

    my ($maybe_template, $args) = File::Temp::_parse_args(@_);
    $args->{CLEANUP} = 0;
    my $dir = $orig->(@$maybe_template, %$args);
    warn "DEBUG: tempdir(...) = $dir\n";
    $dir;
};

sub patch_data {
    return {
        v => 3,
        config => {
        },
        patches => [
            {
                action      => 'wrap',
                mod_version => qr/^0\.*/,
                sub_name    => 'tempdir',
                code        => $wrap_tempdir,
            },
        ],
    };
}

1;
# ABSTRACT: Disable File::Temp::tempdir's automatic cleanup (CLEANUP => 1)

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Temp::Patch::NoCleanup - Disable File::Temp::tempdir's automatic cleanup (CLEANUP => 1)

=head1 VERSION

This document describes version 0.001 of File::Temp::Patch::NoCleanup (from Perl distribution File-Temp-Patch-NoCleanup), released on 2020-08-04.

=head1 SYNOPSIS

From the command-line:

 % PERL5OPT=-MFile::Temp::Patch::NoCleanup yourscript.pl ...

Now you can inspect temporary directory after the script ends.

=head1 DESCRIPTION

This module patches L<File::Temp> to disable automatic cleanup of temporary
directories. In addition, it prints the created temporary directory to stdout.
Useful for debugging.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/File-Temp-Patch-NoCleanup>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-File-Temp-Patch-NoCleanup>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-Temp-Patch-NoCleanup>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Temp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
