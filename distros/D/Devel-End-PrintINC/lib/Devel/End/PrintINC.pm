package Devel::End::PrintINC;

our $DATE = '2017-07-14'; # DATE
our $VERSION = '0.001'; # VERSION

END {
    print "Contents of \@INC:\n";
    for (@INC) { print "  $_\n" }

    print "Contents of \%INC:\n";
    for (sort keys %INC) {
        print "  $_ ($INC{$_})\n";
    }
}

1;
# ABSTRACT: Print @INC and %INC when program ends

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::End::PrintINC - Print @INC and %INC when program ends

=head1 VERSION

This document describes version 0.001 of Devel::End::PrintINC (from Perl distribution Devel-End-PrintINC), released on 2017-07-14.

=head1 SYNOPSIS

 % perl -MDevel::End::PrintINC -e'...'

=head1 DESCRIPTION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-End-PrintINC>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-End-PrintINC>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-End-PrintINC>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Devel::DieHandler::PrintINCVersion>

Other C<Devel::End::*> modules

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
