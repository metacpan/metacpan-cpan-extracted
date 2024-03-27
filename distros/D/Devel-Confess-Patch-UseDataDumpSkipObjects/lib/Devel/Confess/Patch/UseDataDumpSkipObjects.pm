package Devel::Confess::Patch::UseDataDumpSkipObjects;

use 5.010001;
use strict;
no warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-13'; # DATE
our $DIST = 'Devel-Confess-Patch-UseDataDumpSkipObjects'; # DIST
our $VERSION = '0.001'; # VERSION

use Module::Patch;
use base qw(Module::Patch);

our %config;

sub patch_data {
    return {
        v => 3,
        config => {
            -class_pattern => {
                schema => 're*',
            },
        },
        patches => [
            {
                action      => 'replace',
                #mod_version => qr/^/,
                sub_name    => '_ref_formatter',
                code        => sub {
                    require Data::Dump::SkipObjects;
                    $Data::Dump::SkipObjects::CLASS_PATTERN = qr/$config{-class_pattern}/ if defined $config{-class_pattern};

                    #local $SIG{__WARN__} = sub {};
                    #local $SIG{__DIE__} = sub {};
                    Data::Dump::SkipObjects::dump($_[0]);
                },
            },
        ],
   };
}

1;
# ABSTRACT: Use Data::Dump::SkipObjects to stringify some objects

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Confess::Patch::UseDataDumpSkipObjects - Use Data::Dump::SkipObjects to stringify some objects

=head1 VERSION

This document describes version 0.001 of Devel::Confess::Patch::UseDataDumpSkipObjects (from Perl distribution Devel-Confess-Patch-UseDataDumpSkipObjects), released on 2024-02-13.

=head1 SYNOPSIS

 % PERL5OPT=-MDevel::Confess::Patch::UseDataDumpSkipObjects=-class_pattern,'^Dist::Zilla::'  -MDevel::Confess=dump yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Confess-Patch-UseDataDumpSkipObjects>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Confess-Patch-UseDataDumpSkipObjects>.

=head1 SEE ALSO

L<Data::Dump::SkipObjects>

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess-Patch-UseDataDumpSkipObjects>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
