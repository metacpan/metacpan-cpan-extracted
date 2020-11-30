package Devel::Confess::Patch::UseDataDmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'Devel-Confess-Patch-UseDataDmp'; # DIST
our $VERSION = '0.030'; # VERSION

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
                    require Data::Dmp;
                    local $SIG{__WARN__} = sub {};
                    local $SIG{__DIE__} = sub {};
                    no warnings 'once';
                    local $Data::Dmp::OPT_REMOVE_PRAGMAS = 1;
                    Data::Dmp::dmp($_[0]);
                },
            },
        ],
   };
}

1;
# ABSTRACT: Use Data::Dmp to stringify reference

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Confess::Patch::UseDataDmp - Use Data::Dmp to stringify reference

=head1 VERSION

This document describes version 0.030 of Devel::Confess::Patch::UseDataDmp (from Perl distribution Devel-Confess-Patch-UseDataDmp), released on 2020-06-19.

=head1 SYNOPSIS

 % PERL5OPT=-MDevel::Confess::Patch::UseDataDmp -MDevel::Confess=dump yourscript.pl

=head1 DESCRIPTION

=for Pod::Coverage ^()$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Devel-Confess-Patch-UseDataDmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Devel-Confess-Patch-UseDataDmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Confess-Patch-UseDataDmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Data::Dmp>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
