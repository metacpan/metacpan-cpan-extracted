package Locale::TextDomain::IfEnv;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Locale-TextDomain-IfEnv'; # DIST
our $VERSION = '0.002'; # VERSION

#use strict 'subs', 'vars';
#use warnings;

sub import {
    my $class = shift;
    local $Locale::TextDomain::IfEnv::textdomain = shift;
    local @Locale::TextDomain::IfEnv::search_dirs = @_;

    my $caller = caller;

    if ($ENV{PERL_LOCALE_TEXTDOMAIN_IFENV}) {
        require Locale::TextDomain;
        eval "package $caller; use Locale::TextDomain \$Locale::TextDomain::IfEnv::textdomain, \@Locale::TextDomain::IfEnv::search_dirs;";
        die if $@;
    } else {
        require Locale::TextDomain::Mock;
        eval "package $caller; use Locale::TextDomain::Mock;";
    }
}

1;
# ABSTRACT: Enable translation only when environment variable flag is true

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::TextDomain::IfEnv - Enable translation only when environment variable flag is true

=head1 VERSION

This document describes version 0.002 of Locale::TextDomain::IfEnv (from Perl distribution Locale-TextDomain-IfEnv), released on 2019-12-26.

=head1 SYNOPSIS

Use like you would use L<Locale::TextDomain> (but see L</Caveats>):

 use Locale::TextDomain::IfEnv 'Some-TextDomain';

 print __ "Hello, world!\n";

=head1 DESCRIPTION

When imported, Locale::TextDomain::IfEnv will check the
C<PERL_LOCALE_TEXTDOMAIN_IFENV> environment variable. If the environment
variable has a true value, the module will load L<Locale::TextDomain> and pass
the import arguments to it. If the environment variable is false, the module
will install a mock version of C<__>, et al. Thus, all strings will translate to
themselves.

This module can be used to avoid the startup (and runtime) cost of translation
unless when you want to enable translation.

=head2 Caveats

For simplicity, currently the tied hash (C<%__>) and its hashref (C<$__>) are
not provided. Contact me if you use and need this.

=for Pod::Coverage ^(.+)$

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-TextDomain-IfEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Locale-TextDomain-IfEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-TextDomain-IfEnv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::TextDomain>

L<Locale::TextDomain::UTF8::IfEnv>

L<Bencher::Scenarios::LocaleTextDomainIfEnv>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
