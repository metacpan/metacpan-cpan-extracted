package Getopt::Long::EvenLess::Patch::DumpAndExit;

our $DATE = '2017-08-10'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
no warnings;

use Data::Dmp;
use Module::Patch 0.26 qw();
use base qw(Module::Patch);

our %config;

sub _dump {
    print "# BEGIN DUMP $config{-tag}\n";
    local $Data::Dmp::OPT_DEPARSE = 0;
    print dmp($_[0]), "\n";
    print "# END DUMP $config{-tag}\n";
}

sub _GetOptions {
    if (ref($_[0]) eq 'HASH') {
        my $h = shift;
        _dump({ map {$_ => sub{}} @_ });
    } else {
        _dump({@_});
    }
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub _GetOptionsFromArray {
    # discard array
    shift;
    if (ref($_[0]) eq 'HASH') {
        my $h = shift;
        _dump({ map {$_ => sub{}} @_ });
    } else {
        _dump({@_});
    }
    $config{-exit_method} eq 'exit' ? exit(0) : die;
}

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                sub_name    => 'GetOptions',
                code        => \&_GetOptions,
            },
            {
                action      => 'replace',
                sub_name    => 'GetOptionsFromArray',
                code        => \&_GetOptionsFromArray,
            },
        ],
        config => {
            -tag => {
                schema  => 'str*',
                default => 'TAG',
            },
            -exit_method => {
                schema  => 'str*',
                default => 'exit',
            },
        },
   };
}

1;
# ABSTRACT: Patch Getopt::Long::EvenLess to dump option spec and exit

__END__

=pod

=encoding UTF-8

=head1 NAME

Getopt::Long::EvenLess::Patch::DumpAndExit - Patch Getopt::Long::EvenLess to dump option spec and exit

=head1 VERSION

This document describes version 0.001 of Getopt::Long::EvenLess::Patch::DumpAndExit (from Perl distribution Getopt-Long-EvenLess-Dump), released on 2017-08-10.

=head1 DESCRIPTION

This patch can be used to extract Getopt::Long options specification from a
script by running the script but exiting early after getting the specification.

=for Pod::Coverage ^(patch_data)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Getopt-Long-EvenLess-Dump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Getopt-Long-EvenLess-Dump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Getopt-Long-EvenLess-Dump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
