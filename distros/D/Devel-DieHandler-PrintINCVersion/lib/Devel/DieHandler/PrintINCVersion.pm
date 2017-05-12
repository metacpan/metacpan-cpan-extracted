package Devel::DieHandler::PrintINCVersion;

our $DATE = '2017-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use ExtUtils::MakeMaker;

my @handler_stack;

sub import {
    my $pkg = shift;
    push @handler_stack, $SIG{__DIE__} if $SIG{__DIE__};
    $SIG{__DIE__} = sub {
        local $SIG{__DIE__};
        print "Versions of files in %INC:\n";
        for my $k (sort keys %INC) {
            my $path = $INC{$k};
            print "  $k ($path): ";
            if (-f $path) {
                my $v = MM->parse_version($path);
                print $v if defined $v;
            }
            print "\n";
        }
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
# ABSTRACT: Print versions of files (modules) listed in %INC

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::DieHandler::PrintINCVersion - Print versions of files (modules) listed in %INC

=head1 VERSION

This document describes version 0.001 of Devel::DieHandler::PrintINCVersion (from Perl distribution Devel-DieHandler-PrintINCVersion), released on 2017-04-16.

=head1 SYNOPSIS

 % perl -MDevel::DieHandler::PrintINCVersion -e'...'

=head1 DESCRIPTION

When imported, this module installs a C<__DIE__> handler which, upon the program
dying, will print the versions of files (modules) listed in C<%INC> to STDOUT.
The versions will be extracted using L<ExtUtils::MakeMaker>'s C<parse_version>.

Unimporting (via C<no Devel::DieHandler::PrintINCVersion>) after importing
restores the previous handler.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-DieHandler-PrintINCVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-DieHandler-PrintINCVersion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-DieHandler-PrintINCVersion>

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
