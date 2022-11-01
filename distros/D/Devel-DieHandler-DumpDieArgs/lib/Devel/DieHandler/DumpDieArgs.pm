package Devel::DieHandler::DumpDieArgs;

use strict;
use warnings;

use Data::Dmp ();

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-27'; # DATE
our $DIST = 'Devel-DieHandler-DumpDieArgs'; # DIST
our $VERSION = '0.001'; # VERSION

my @handler_stack;

sub import {
    my $pkg = shift;
    push @handler_stack, $SIG{__DIE__} if $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        local $SIG{__DIE__};
        print STDERR "Content of \@_: ", Data::Dmp::dmp(\@_), "\n";
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
# ABSTRACT: Dump content of die arguments

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::DieHandler::DumpDieArgs - Dump content of die arguments

=head1 VERSION

This document describes version 0.001 of Devel::DieHandler::DumpDieArgs (from Perl distribution Devel-DieHandler-DumpDieArgs), released on 2022-10-27.

=head1 SYNOPSIS

 % perl -MDevel::DieHandler::DumpDieArgs -e'...'

=head1 DESCRIPTION

When imported, this module installs a C<__DIE__> handler which dumps the content
of C<@_> to STDERR, then calls the previous handler (or die). Useful if your
code (accidentally?) throws an unhandled a data structure or object exception,
which normally just prints C<HASH(0x55e20e0fd5e8)> or
C<Foo=ARRAY(0x5566580705e8)>.

Unimporting (via C<no Devel::DieHandler::DumpDieArgs>) after importing restores
the previous handler.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-DieHandler-DumpDieArgs>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-DieHandler-DumpDieArgs>.

=head1 SEE ALSO

Other C<Devel::DieHandler::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-DieHandler-DumpDieArgs>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
