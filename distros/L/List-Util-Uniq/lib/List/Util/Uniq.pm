package List::Util::Uniq;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-31'; # DATE
our $DIST = 'List-Util-Uniq'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                           uniq_adj
                           uniq_adj_ci
                           uniq_ci
                           is_uniq
                           is_uniq_ci
                           is_monovalued
                           is_monovalued_ci
               );

sub uniq_adj {
    my @res;

    return () unless @_;
    my $last = shift;
    push @res, $last;
    for (@_) {
        next if !defined($_) && !defined($last);
        # XXX $_ becomes stringified
        next if defined($_) && defined($last) && $_ eq $last;
        push @res, $_;
        $last = $_;
    }
    @res;
}

sub uniq_adj_ci {
    my @res;

    return () unless @_;
    my $last = shift;
    push @res, $last;
    for (@_) {
        next if !defined($_) && !defined($last);
        # XXX $_ becomes stringified
        next if defined($_) && defined($last) && lc($_) eq lc($last);
        push @res, $_;
        $last = $_;
    }
    @res;
}

sub uniq_ci {
    my @res;

    my %mem;
    my $undef_added;
    for (@_) {
        if (defined) {
            push @res, $_ unless $mem{lc $_}++;
        } else {
            push @res, $_ unless $undef_added++;
        }
    }
    @res;
}

sub is_uniq {
    my %vals;
    for (@_) {
        return 0 if $vals{$_}++;
    }
    1;
}

sub is_uniq_ci {
    my %vals;
    for (@_) {
        return 0 if $vals{lc $_}++;
    }
    1;
}

sub is_monovalued {
    my %vals;
    for (@_) {
        $vals{$_} = 1;
        return 0 if keys(%vals) > 1;
    }
    1;
}

sub is_monovalued_ci {
    my %vals;
    for (@_) {
        $vals{lc $_} = 1;
        return 0 if keys(%vals) > 1;
    }
    1;
}

1;
# ABSTRACT: List utilities related to finding unique items

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::Uniq - List utilities related to finding unique items

=head1 VERSION

This document describes version 0.004 of List::Util::Uniq (from Perl distribution List-Util-Uniq), released on 2021-07-31.

=head1 SYNOPSIS

 use List::Util::Uniq qw(
     is_monovalued
     is_monovalued_ci
     is_uniq
     is_uniq_ci
     uniq_adj
     uniq_adj_ci
     uniq_ci
 );

 $res = is_monovalued(qw/a a a/); # 1
 $res = is_monovalued(qw/a b a/); # 0

 $res = is_monovalued_ci(qw/a a A/); # 1
 $res = is_monovalued_ci(qw/a b A/); # 0

 $res = is_uniq(qw/a b a/); # 0
 $res = is_uniq(qw/a b c/); # 1

 $res = is_uniq_ci(qw/a b A/); # 0
 $res = is_uniq_ci(qw/a b c/); # 1

 @res = uniq_adj(1, 4, 4, 3, 1, 1, 2); # 1, 4, 3, 1, 2

 @res = uniq_adj_ci("a", "b", "B", "c", "a"); # "a", "b", "c", "a"

 @res = uniq_ci("a", "b", "B", "c", "a"); # "a", "b", "c"

=head1 FUNCTIONS

None exported by default but exportable.

=head2 uniq_adj

Usage:

 my @uniq = uniq_adj(@list);

Remove I<adjacent> duplicates from list, i.e. behave more like Unix utility's
B<uniq> instead of L<List::MoreUtils>'s C<uniq> function. Uses string equality
test.

=head2 uniq_adj_ci

Like L</uniq_adj> except case-insensitive.

=head2 uniq_ci

Like C<List::MoreUtils>' C<uniq> (C<uniqstr>) except case-insensitive.

=head2 is_uniq

Usage:

 my $is_uniq = is_uniq(@list);

Return true when the values in C<@list> is unique (compared string-wise).
Knowing whether a list has unique values is faster using this function compared
to doing:

 my @uniq = uniq(@list);
 @uniq == @list;

because of short-circuiting.

=head2 is_uniq_ci

Like L</is_uniq> except case-insensitive.

=head2 is_monovalued

Usage:

 my $is_monovalued = is_monovalued(@list);

Examples:

 is_monovalued(qw/a b c/); # => 0
 is_monovalued(qw/a a a/); # => 1

Return true if C<@list> contains only a single value. Returns true for empty
list. Undef is coerced to empty string, so C<< is_monovalued(undef) >> and C<<
is_monovalued(undef, undef) >> return true.

=head2 is_monovalued_ci

Like L</is_monovalued> except case-insensitive.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-Uniq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-Uniq>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-Uniq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<List::Util>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
