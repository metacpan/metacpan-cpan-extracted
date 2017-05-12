package Sah::Schema::DefHash;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '1.0.11'; # VERSION

use strict;
use warnings;

our %SCHEMAS;

$SCHEMAS{defhash} = [hash => {
    # tmp
    _prop => {
        v => {},
        defhash_v => {},
        name => {},
        caption => {},
        summary => {},
        description => {},
        tags => {},
        default_lang => {},
        x => {},
    },

    keys => {

        v         => ['float*', default=>1],

        defhash_v => ['int*', default=>1],

        name      => [
            'str*',
            'clset&' => [
                {
                    match             => qr/\A\w+\z/,
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should be a word',
                },
                {
                    max_len             => 32,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
            ],
        ],

        caption   => [
            'str*',
        ],

        summary   => [
            'str',
            'clset&' => [
                {
                    max_len             => 72,
                    'max_len.err_level' => 'warn',
                    'max_len.err_msg'   => 'should be short',
                },
                {
                    'match'           => qr/\n/,
                    'match.op'        => 'not',
                    'match.err_level' => 'warn',
                    'match.err_msg'   => 'should only be a single-line text',
                },
            ],
        ],

        description => [
            'str',
        ],

        tags => [
            'array',
            of => [
                'any*',
                of => [
                    'str*',
                    'hash*', # XXX defhash, but this is circular
                ],
            ],
        ],

        default_lang => [
            'str*', # XXX check format, e.g. 'en' or 'en_US'
        ],

        x => [
            'any',
        ],
    },
    'keys.restrict' => 0,
    'allowed_keys_re' => qr/\A\w+(\.\w+)*\z/,
}];

$SCHEMAS{defhash_v1} = [defhash => {
    keys => {
        defhash_v => ['int*', is=>1],
    },
}];

# XXX check known attributes (.alt, etc)
# XXX check alt.XXX format (e.g. must be alt\.(lang\.\w+|env_lang\.\w+)
# XXX *.alt.*.X should also be of the same type (e.g. description.alt.lang.foo

1;
# ABSTRACT: Sah schemas to validate DefHash

__END__

=pod

=encoding UTF-8

=head1 NAME

Sah::Schema::DefHash - Sah schemas to validate DefHash

=head1 VERSION

This document describes version 1.0.11 of Sah::Schema::DefHash (from Perl distribution DefHash), released on 2015-09-03.

=head1 SYNOPSIS

 # schemas are put in the %SCHEMAS package variable

=head1 DESCRIPTION

This module contains L<Sah> schemas to validate L<DefHash>.

=head1 SCHEMAS

=over

=item * defhash

=item * defhash_v1

=back

=head1 SEE ALSO

L<Sah>, L<Data::Sah>

L<DefHash>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DefHash>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DefHash>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DefHash>

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
