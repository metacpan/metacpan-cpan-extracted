package End::Eval;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'End-Eval'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

my $code;
sub import {
    my $class = shift;
    $code = join " ", @_;
}

END {
    print "DEBUG:Eval-ing $code ...\n" if $ENV{DEBUG};
    $code = '' unless defined $code;
    eval "no strict; no warnings; $code;";
    die if $@;
}

1;
# ABSTRACT: Take code from import arguments, then eval it in END block

__END__

=pod

=encoding UTF-8

=head1 NAME

End::Eval - Take code from import arguments, then eval it in END block

=head1 VERSION

This document describes version 0.001 of End::Eval (from Perl distribution End-Eval), released on 2021-08-06.

=head1 SYNOPSIS

On the command-line:

 % perl -MEnd::Eval='use Data::Dump; dd \%INC' `which some-perl-script.pl` ...
 % PERL5OPT='-mData::Dump -MEnd::Eval=Data::Dump::dd\%INC' some-perl-script.pl ...

=head1 DESCRIPTION

This module allows you to specify a code in import arguments, basically for
convenience in one-liners.

Caveat: specifying in PERL5OPT is tricky because of the limited syntax.

=head1 FAQ

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/End-Eval>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-End-Eval>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=End-Eval>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<End::Eval::*> (like L<End::Eval::FirstArg>) and C<End::*> modules.

Other C<Devel::End::*> modules (but this namespace is deprecated in favor of
C<End>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
