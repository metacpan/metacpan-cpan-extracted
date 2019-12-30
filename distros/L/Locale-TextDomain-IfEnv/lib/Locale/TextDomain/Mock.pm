package Locale::TextDomain::Mock;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-26'; # DATE
our $DIST = 'Locale-TextDomain-IfEnv'; # DIST
our $VERSION = '0.002'; # VERSION

#use strict 'subs', 'vars';
#use warnings;

sub __expand($@) {
    my ($translation, %args) = @_;
    my $re = join '|', map { quotemeta $_ } keys %args;
    $translation =~ s/\{($re)\}/defined $args{$1} ? $args{$1} : "{$1}"/ge;
    $translation;
}

# plain string
sub __($) {
    $_[0];
}

# interpolation
sub __x($@) {
    goto &__expand;
}

# plural
sub __n($$$) {
    my ($msgid, $msgid_plural, $count) = @_;
    $count > 1 ? $msgid_plural : $msgid;
}

# plural + interpolation
sub __nx($$$@) {
    my ($msgid, $msgid_plural, $count, %args) = @_;
    __expand($count > 1 ? $msgid_plural : $msgid, %args);
}

# alias for __nx
sub __xn($$$@) {
    goto &__nx;
}

# context
sub __p($$) {
    $_[1];
}

# context + interpolation
sub __px($$@) {
    my $context = shift;
    goto &__x;
}

# context + plural
sub __np($$$$) {
    my $context = shift;
    goto &__n;
}

# context + plural + interpolation
sub __npx($$$$@) {
    my $context = shift;
    goto &__nx;
}

# Dummy functions for string marking.
sub N__($) {
    return shift;
}

sub N__n($$$) {
    return @_;
}

sub N__p($$) {
    return @_;
}

sub N__np($$$$) {
    return @_;
}

sub import {
    my $class = shift;

    my $caller = caller;
    for (qw(__ __x __n __nx __xn __p __px __np __npx
            N__ N__n N__p N__np)) {
        *{"$caller\::$_"} = \&{$_};
    }
}

1;
# ABSTRACT: Mock Locale::TextDomain functions

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::TextDomain::Mock - Mock Locale::TextDomain functions

=head1 VERSION

This document describes version 0.002 of Locale::TextDomain::Mock (from Perl distribution Locale-TextDomain-IfEnv), released on 2019-12-26.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-TextDomain-IfEnv>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Locale-TextDomain-IfEnv>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-TextDomain-IfEnv>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
