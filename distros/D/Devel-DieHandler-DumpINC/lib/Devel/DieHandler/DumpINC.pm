package Devel::DieHandler::DumpINC;

our $DATE = '2016-05-09'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

my @handler_stack;

sub import {
    my $pkg = shift;
    push @handler_stack, $SIG{__DIE__} if $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        local $SIG{__DIE__};
        print STDERR "Content of %INC: {\n",
            (map { "  '$_' => $INC{$_}\n" } sort keys %INC),
            "}\n";
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
# ABSTRACT: Dump content of %INC when program dies

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::DieHandler::DumpINC - Dump content of %INC when program dies

=head1 VERSION

This document describes version 0.002 of Devel::DieHandler::DumpINC (from Perl distribution Devel-DieHandler-DumpINC), released on 2016-05-09.

=head1 SYNOPSIS

 % perl -MDevel::DieHandler::DumpINC -e'...'

=head1 DESCRIPTION

When imported, this module installs a C<__DIE__> handler which dumps the content
of C<%INC> to STDERR, then calls the previous handler (or die).

Unimporting (via C<no Devel::DieHandler::DumpINC>) after importing restores the
previous handler.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-DieHandler-DumpINC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-DieHandler-DumpINC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-DieHandler-DumpINC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
