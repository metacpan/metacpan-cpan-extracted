package Devel::DieHandler::Pwd;

our $DATE = '2017-01-13'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;
use Cwd;

my @handler_stack;

sub import {
    my $pkg = shift;
    push @handler_stack, $SIG{__DIE__} if $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        local $SIG{__DIE__};
        print STDERR "Current directory: ", getcwd(), "\n";
        if (@handler_stack) {
            goto &{$handler_stack[-1]};
        } else {
            die @_;
        }
    };
}

sub unimport {
    my $pkg = shift;
    if (@handler_stack) {
        $SIG{__DIE__} = pop(@handler_stack);
    }
}

1;
# ABSTRACT: Print working directory when program dies

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::DieHandler::Pwd - Print working directory when program dies

=head1 VERSION

This document describes version 0.001 of Devel::DieHandler::Pwd (from Perl distribution Devel-DieHandler-Pwd), released on 2017-01-13.

=head1 SYNOPSIS

 % perl -MDevel::DieHandler::Pwd -e'...'

=head1 DESCRIPTION

When imported, this module installs a C<__DIE__> handler which prints working
directory to STDERR, then calls the previous handler (or die).

Unimporting (via C<no Devel::DieHandler::Pwd>) after importing restores the
previous handler.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-DieHandler-Pwd>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-DieHandler-Pwd>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-DieHandler-Pwd>

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
