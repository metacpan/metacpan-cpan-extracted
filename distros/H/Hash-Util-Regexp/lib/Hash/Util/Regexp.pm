package Hash::Util::Regexp;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-25'; # DATE
our $DIST = 'Hash-Util-Regexp'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       has_key_matching
                       keys_matching
                       first_key_matching

                       has_key_not_matching
                       keys_not_matching
                       first_key_not_matching
               );

sub _keys {
    my ($hash, $sort) = @_;

    my @keys = keys %$hash;
    if ($sort) {
        if (ref $sort eq 'CODE') {
            @keys = sort $sort @keys;
        } else {
            @keys = sort @keys;
        }
    }
    \@keys;
}

sub has_key_matching {
    my ($hash, $re) = @_;
    for my $key (keys %$hash) {
        return 1 if $key =~ $re;
    }
    0;
}

sub keys_matching {
    my ($hash, $re, $sort) = @_;

    my @res;
    for my $key (@{ _keys($hash, $sort) }) {
        next unless $key =~ $re;
        push @res, $key;
    }
    @res;
}

sub first_key_matching {
    my ($hash, $re, $sort) = @_;

    my @res;
    for my $key (@{ _keys($hash, $sort) }) {
        return $key if $key =~ $re;
    }
    return;
}

sub has_key_not_matching {
    my ($hash, $re) = @_;
    for my $key (keys %$hash) {
        return 1 unless $key =~ $re;
    }
    0;
}

sub keys_not_matching {
    my ($hash, $re, $sort) = @_;

    my @res;
    for my $key (@{ _keys($hash, $sort) }) {
        next if $key =~ $re;
        push @res, $key;
    }
    @res;
}

sub first_key_not_matching {
    my ($hash, $re, $sort) = @_;

    my @res;
    for my $key (@{ _keys($hash, $sort) }) {
        return $key unless $key =~ $re;
    }
    return;
}

1;
# ABSTRACT: Hash utility routines related to regular expression

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Util::Regexp - Hash utility routines related to regular expression

=head1 VERSION

This document describes version 0.001 of Hash::Util::Regexp (from Perl distribution Hash-Util-Regexp), released on 2022-07-25.

=head1 DESCRIPTION

=head1 FUNCTIONS

All the functions are exportable but not exported by default.

=head2 has_key_matching

Usage:

 my $bool = has_key_matching(\%hash, qr/some_regex/);

This is a shortcut/alias for something like:

 my $bool = any { /some_regex/ } keys %hash;

=head2 first_key_matching

Usage:

 my $key = first_key_matching(\%hash, qr/some_regex/ [ , $sort ]);

This is a shortcut/alias for something like:

 my $key = first { /some_regex/ } keys %hash;

The optional C<$sort> argument can be set to true (e.g. 1) or a coderef to sort
the keys first.

=head2 keys_matching

Usage:

 my @keys = keys_matching(\%hash, qr/some_regex/ [ , $sort ]);

This is a shortcut/alias for something like:

 my @keys = grep { /some_regex/ } keys %hash;

The optional C<$sort> argument can be set to true (e.g. 1) or a coderef to sort
the keys first.

=head2 has_key_not_matching

The counterpart for L</has_key_matching>.

=head2 first_key_not_matching

The counterpart for L</first_key_matching>.

=head2 keys_not_matching

The counterpart for L</keys_matching>.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Hash-Util-Regexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Hash-Util-Regexp>.

=head1 SEE ALSO

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Hash-Util-Regexp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
