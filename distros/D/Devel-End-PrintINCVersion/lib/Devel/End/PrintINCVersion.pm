package Devel::End::PrintINCVersion;

our $DATE = '2017-04-16'; # DATE
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use ExtUtils::MakeMaker;

END {
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
}

1;
# ABSTRACT: Print versions of files (modules) listed in %INC

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::End::PrintINCVersion - Print versions of files (modules) listed in %INC

=head1 VERSION

This document describes version 0.001 of Devel::End::PrintINCVersion (from Perl distribution Devel-End-PrintINCVersion), released on 2017-04-16.

=head1 SYNOPSIS

 % perl -MDevel::End::PrintINCVersion -e'...'

=head1 DESCRIPTION

After loading this module, when program ends, versions of files (modules) listed
in C<%INC> will be printed to STDOUT. The versions are extracted using
L<ExtUtils::MakeMaker>'s C<parse_version>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-End-PrintINCVersion>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-End-PrintINCVersion>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-End-PrintINCVersion>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Devel::EndHandler::PrintINCVersion>

Other C<Devel::End::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
