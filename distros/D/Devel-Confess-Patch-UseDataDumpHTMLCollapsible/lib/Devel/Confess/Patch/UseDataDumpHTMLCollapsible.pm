package Devel::Confess::Patch::UseDataDumpHTMLCollapsible;

use 5.010001;
use strict;
no warnings;

use Module::Patch;
use base qw(Module::Patch);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-03-12'; # DATE
our $DIST = 'Devel-Confess-Patch-UseDataDumpHTMLCollapsible'; # DIST
our $VERSION = '0.001'; # VERSION

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action      => 'replace',
                #mod_version => qr/^/,
                sub_name    => '_ref_formatter',
                code        => sub {
                    require Data::Dump::HTML::Collapsible;
                    local $SIG{__WARN__} = sub {};
                    local $SIG{__DIE__} = sub {};
                    no warnings 'once';
                    local $Data::Dump::HTML::Collapsible::OPT_REMOVE_PRAGMAS = 1;
                    Data::Dump::HTML::Collapsible::dump($_[0]);
                },
            },
        ],
   };
}

1;
# ABSTRACT: Use Data::Dump::HTML::Collapsible to stringify reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Confess::Patch::UseDataDumpHTMLCollapsible - Use Data::Dump::HTML::Collapsible to stringify reference

=head1 VERSION

This document describes version 0.001 of Devel::Confess::Patch::UseDataDumpHTMLCollapsible (from Perl distribution Devel-Confess-Patch-UseDataDumpHTMLCollapsible), released on 2024-03-12.

=head1 SYNOPSIS

 % PERL5OPT=-MDevel::Confess::Patch::UseDataDumpHTMLCollapsible -MDevel::Confess=dump yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Confess-Patch-UseDataDumpHTMLCollapsible>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Confess-Patch-UseDataDumpHTMLCollapsible>.

=head1 SEE ALSO

L<Data::Dump::HTML::Collapsible>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess-Patch-UseDataDumpHTMLCollapsible>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
