package List::AllUtils::Null;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-01'; # DATE
our $DIST = 'List-AllUtils-Null'; # DIST
our $VERSION = '0.001'; # VERSION

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(max maxstr min minstr sum);

sub sum(@) {
    return undef unless @_;
    my $s = 0;
    for (@_) {
        return undef unless defined;
        $s += $_;
    }
    $s;
}

sub min (@) {
    return undef unless @_;
    my $min = shift;
    return undef unless defined $min;
    for (@_) {
        return undef unless defined;
        $_ < $min and $min = $_;
    }
    $min;
}

sub max (@) {
    return undef unless @_;
    my $max = shift;
    return undef unless defined $max;
    for (@_) {
        return undef unless defined;
        $_ > $max and $max = $_;
    }
    $max;
}

sub minstr (@) {
    return undef unless @_;
    my $min = shift;
    return undef unless defined $min;
    for (@_) {
        return undef unless defined;
        $_ lt $min and $min = $_;
    }
    $min;
}

sub maxstr (@) {
    return undef unless @_;
    my $max = shift;
    return undef unless defined $max;
    for (@_) {
        return undef unless defined;
        $_ gt $max and $max = $_;
    }
    $max;
}

1;
# ABSTRACT: List subroutines that treat undef as contagious unknown, like null in SQL

__END__

=pod

=encoding UTF-8

=head1 NAME

List::AllUtils::Null - List subroutines that treat undef as contagious unknown, like null in SQL

=head1 VERSION

This document describes version 0.001 of List::AllUtils::Null (from Perl distribution List-AllUtils-Null), released on 2021-04-01.

=head1 SYNOPSIS

 use List::AllUtils::Null qw(
     max maxstr min minstr
     sum
 );

 say max(1,2,3,4,5);     # => 5
 say max(1,2,undef,4,5); # => undef

 say min(1,2,3,4,5);     # => 1
 say min(1,2,undef,4,5); # => undef

 say sum(1,2,3,4,5);     # => 15
 say sum(1,2,undef,4,5); # => undef

=head1 DESCRIPTION

=head1 FUNCTIONS

=head2 max

=head2 maxstr

=head2 min

=head2 minstr

=head2 sum

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-AllUtils-Null>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-AllUtils-Null>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-List-AllUtils-Null/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

Your favorite SQL reference.

L<List::Util> and friends (L<List::SomeUtils>, L<List::UtilsBy>,
L<List::MoreUtils>, L<List::AllUtils>).

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
