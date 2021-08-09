package End::Eval::FirstArg;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'End-Eval-FirstArg'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my $code;
sub import {
    my $class = shift;
    $code = shift @ARGV;
}

END {
    $code = '' unless defined $code;
    eval "no strict; no warnings; $code;";
    die if $@;
}

1;
# ABSTRACT: Take code from first command-line argument, then eval it in END block

__END__

=pod

=encoding UTF-8

=head1 NAME

End::Eval::FirstArg - Take code from first command-line argument, then eval it in END block

=head1 VERSION

This document describes version 0.001 of End::Eval::FirstArg (from Perl distribution End-Eval-FirstArg), released on 2021-08-06.

=head1 SYNOPSIS

On the command-line:

 % perl -MEnd::Eval::FirstArg `which some-perl-script.pl` 'use Data::Dump; dd \%INC' ...
 % PERL5OPT=-MEnd::Eval::FirstArg some-perl-script.pl 'use Data::Dump; dd \%INC' ...

=head1 DESCRIPTION

This module allows you to specify a code in the first command-line argument,
basically for convenience in one-liners.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/End-Eval-FirstArg>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-End-Eval-FirstArg>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=End-Eval-FirstArg>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<End::Eval::*> (like L<End::Eval> and L<End::Eval>) and C<End::*>
modules.

Other C<Devel::End::*> modules (but this namespace is deprecated in favor of
C<End>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
