package Log::Any::Proxy::Patch::UseDataDump;

our $DATE = '2016-01-08'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
no warnings;

use Module::Patch 0.12 qw();
use base qw(Module::Patch);

use Data::Dump ();

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
                    return Data::Dump::dump(shift);
                },
            },
        ],
    };
}

1;
# ABSTRACT: Use Data::Dump to dump data structures

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Proxy::Patch::UseDataDump - Use Data::Dump to dump data structures

=head1 VERSION

This document describes version 0.01 of Log::Any::Proxy::Patch::UseDataDump (from Perl distribution Log-Any-Proxy-Patch-UseDataDump), released on 2016-01-08.

=head1 SYNOPSIS

 use Log::Any::Proxy::Patch::UseDataDump;

=head1 DESCRIPTION

This patch replaces the dumping routine in L<Log::Any> from L<Data::Dumper> to
L<Data::Dump>.

=for Pod::Coverage ^(patch_data)$

=head1 SEE ALSO

L<Data::Dump>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Any-Proxy-Patch-UseDataDump>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Any-Proxy-Patch-UseDataDump>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Any-Proxy-Patch-UseDataDump>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
