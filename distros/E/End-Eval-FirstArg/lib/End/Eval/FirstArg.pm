# minimalist
## no critic: TestingAndDebugging::RequireUseStrict
package End::Eval::FirstArg;

##BEGIN ifunbuilt
use strict;
use warnings;
##END ifunbuilt

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-05'; # DATE
our $DIST = 'End-Eval-FirstArg'; # DIST
our $VERSION = '0.003'; # VERSION

my $code;
sub import {
    my $class = shift;
    $code = shift @ARGV;
}

END {
    $code = '' unless defined $code;
    print "DEBUG: eval-ing $code ...\n" if $ENV{DEBUG};
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

This document describes version 0.003 of End::Eval::FirstArg (from Perl distribution End-Eval-FirstArg), released on 2022-02-05.

=head1 SYNOPSIS

On the command-line:

 % perl -MEnd::Eval::FirstArg `which some-perl-script.pl` 'use Data::Dump; dd \%INC' ...
 % PERL5OPT=-MEnd::Eval::FirstArg some-perl-script.pl 'use Data::Dump; dd \%INC' ...

=head1 DESCRIPTION

This module allows you to evaluate Perl code specified in the first command-line
argument in the END block, basically for convenience in one-liners.

=for BEGIN_BLOCK: description

The purpose of Begin::Eval::* and End::Eval::* modules is to allow you to
evaluate some extra Perl code in addition to running your application,
respectively at the beginning and at the end. The code can be supplied via one
of these means: first command-line argument, environment variable(s). Previously
there are Begin::Eval and End::Eval modules that accept code from import
arguments, but the limited syntax provided by perl's C<-M> switch diminishes the
usefulness of the modules. Thus the modules are removed from CPAN.

Use cases include:

=over

=item * printing \%INC at the start of your program run

 % perl -MBegin::Eval::FirstArg /path/to/your-script.pl 'print "$_\n" for sort keys %INC' script-arg1 ...
 % PERL_BEGIN_EVAL_END='print "$_\n" for sort keys %INC' perl -MBegin::Eval::Env /path/to/your-script.pl script-arg1 ...

To know which modules are loaded before your program runs.

=item * printing \%INC at the beginning of your program run

To know all the modules that are loaded during your program run.

=item * loading a module at the beginning of your program, with some initialization

=back

Alternatives to using these modules include using "do":

 % perl -E 'your-extra-code-before-running-program; do "/path/to/your/script.pl"; your-extra-code-after-running-program'

=for END_BLOCK: description

=head1 FAQ

=head1 ENVIRONMENT

=head2 DEBUG

Bool. Can be turned on to print the code to STDOUT before eval-ing it.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/End-Eval-FirstArg>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-End-Eval-FirstArg>.

=head1 SEE ALSO

Other C<End::Eval::*> modules, like L<End::Eval::Env>.

Other C<End::*> modules.

Other C<Begin::Eval::*> modules.

Other C<Devel::End::*> modules (but this namespace is deprecated in favor of
C<End>).

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=End-Eval-FirstArg>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
