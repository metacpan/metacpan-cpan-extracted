package Devel::Confess::Patch::UseDataDumpObjectAsString;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'Devel-Confess-Patch-UseDataDumpObjectAsString'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch;
use base qw(Module::Patch);

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
                    require Data::Dump::ObjectAsString;
                    local $SIG{__WARN__} = sub {};
                    local $SIG{__DIE__} = sub {};
                    Data::Dump::ObjectAsString::dump($_[0]);
                },
            },
        ],
   };
}

1;
# ABSTRACT: Use Data::Dump::ObjectAsString to stringify reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Confess::Patch::UseDataDumpObjectAsString - Use Data::Dump::ObjectAsString to stringify reference

=head1 VERSION

This document describes version 0.001 of Devel::Confess::Patch::UseDataDumpObjectAsString (from Perl distribution Devel-Confess-Patch-UseDataDumpObjectAsString), released on 2020-06-19.

=head1 SYNOPSIS

 % PERL5OPT=-MDevel::Confess::Patch::UseDataDumpObjectAsString -MDevel::Confess=dump yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Confess-Patch-UseDataDumpObjectAsString>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Confess-Patch-UseDataDumpObjectAsString>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess-Patch-UseDataDumpObjectAsString>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dump::ObjectAsString>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
