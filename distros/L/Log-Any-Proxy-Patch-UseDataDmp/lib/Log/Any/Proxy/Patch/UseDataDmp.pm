package Log::Any::Proxy::Patch::UseDataDmp;

our $DATE = '2015-11-08'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

use Data::Dmp;

our %config;

sub patch_data {
    return {
        v => 3,
        patches => [
            {
                action => 'replace',
                #mod_version => qr/^1\.[01].+/,
                sub_name => '_dump_one_line',
                code => sub {
                    return dmp(shift);
                },
            },
        ],
    };
}

1;
# ABSTRACT: Use Data::Dmp to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::Patch::UseDataDmp - Use Data::Dmp to dump data structures

=head1 VERSION

This document describes version 0.01 of Log::Any::Proxy::Patch::UseDataDmp (from Perl distribution Log-Any-Proxy-Patch-UseDataDmp), released on 2015-11-08.

=head1 SYNOPSIS

 use Log::Any::Proxy::Patch::UseDataDmp;

=head1 DESCRIPTION

This patch replaces the dumping routine in L<Log::Any> from L<Data::Dumper> to
L<Data::Dmp>.

=for Pod::Coverage ^(patch_data)$

=head1 SEE ALSO

L<Data::Dmp>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Proxy-Patch-UseDataDmp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-Proxy-Patch-UseDataDmp>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Proxy-Patch-UseDataDmp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
