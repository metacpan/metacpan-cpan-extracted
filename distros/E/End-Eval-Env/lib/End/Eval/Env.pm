package End::Eval::Env;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-08-06'; # DATE
our $DIST = 'End-Eval-Env'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

my @envs;
sub import {
    my $class = shift;
    push @envs, @_;
}

END {
    push @envs, 'PERL_END_EVAL_ENV' unless @envs;
    for my $env (@envs) {
        next unless defined $ENV{$env};
        print "DEBUG: eval-ing ENV{$env}: $ENV{$env} ...\n" if $ENV{DEBUG};
        eval "no strict; no warnings; $ENV{$env};";
        die if $@;
    }
}

1;
# ABSTRACT: Take code from environment variable(s), then eval them in END block

__END__

=pod

=encoding UTF-8

=head1 NAME

End::Eval::Env - Take code from environment variable(s), then eval them in END block

=head1 VERSION

This document describes version 0.002 of End::Eval::Env (from Perl distribution End-Eval-Env), released on 2021-08-06.

=head1 SYNOPSIS

On the command-line:

 % PERL_END_EVAL_ENV='use Data::Dump; dd \%INC' perl -MEnd::Eval::Env `which some-perl-script.pl` ...
 % PERL_END_EVAL_ENV='use Data::Dump; dd \%INC' PERL5OPT=-MEnd::Eval::Env some-perl-script.pl ...

Customize the environment variables:

 % perl -MEnd::Eval::Env=ENVNAME1,ENVNAME2 `which some-perl-script.pl` ...
 % PERL5OPT=-MEnd::Eval::Env=ENVNAME1,ENVNAME2 some-perl-script.pl ...

=head1 DESCRIPTION

This module allows you to specify code(s) in environment variable(s), basically
for convenience in one-liners. If name(s) of environment variables are not
specified, C<PERL_END_EVAL_ENV> is the default.

=head1 ENVIRONMENT

=head2 DEBUG

Bool. Can be turned on to print the code to STDOUT before eval-ing it.

=head2 PERL_END_EVAL_END

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/End-Eval-Env>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-End-Eval-Env>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=End-Eval-Env>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Other C<End::Eval::*> (like L<End::Eval> and L<End::Eval::FirstArg>) and
C<End::*> modules.

Other C<Devel::End::*> modules (but this namespace is deprecated in favor of
C<End>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
