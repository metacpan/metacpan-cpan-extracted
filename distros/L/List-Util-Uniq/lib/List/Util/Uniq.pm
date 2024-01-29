package List::Util::Uniq;

use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-01-19'; # DATE
our $DIST = 'List-Util-Uniq'; # DIST
our $VERSION = '0.008'; # VERSION

our @EXPORT_OK = qw(
                       uniq
                       uniqint
                       uniqnum
                       uniqstr

                       uniq_adj
                       uniq_adj_ci
                       uniq_ci
                       is_uniq
                       is_uniq_ci
                       is_monovalued
                       is_monovalued_ci

                       dupe
                       dupeint
                       dupenum
                       dupestr

                       dupe_ci

                       pushuniq
                       pushuniqint
                       pushuniqnum
                       pushuniqstr
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

sub uniqint {
    my (@uniqs, %vals);
    for (@_) {
        no warnings 'numeric';
        ++$vals{int $_} == 1 and push @uniqs, $_;
    }
    @uniqs;
}

sub uniqnum {
    my (@uniqs, %vals);
    for (@_) {
        no warnings 'numeric';
        ++$vals{$_+0} == 1 and push @uniqs, $_;
    }
    @uniqs;
}

sub uniqstr {
    my (@uniqs, %vals);
    for (@_) {
        ++$vals{$_} == 1 and push @uniqs, $_;
    }
    @uniqs;
}

sub uniq { goto \&uniqstr }

sub dupeint {
    my (@dupes, %vals);
    for (@_) {
        no warnings 'numeric';
        ++$vals{int $_} > 1 and push @dupes, $_;
    }
    @dupes;
}

sub dupenum {
    my (@dupes, %vals);
    for (@_) {
        no warnings 'numeric';
        ++$vals{$_+0} > 1 and push @dupes, $_;
    }
    @dupes;
}

sub dupestr {
    my (@dupes, %vals);
    for (@_) {
        ++$vals{$_} > 1 and push @dupes, $_;
    }
    @dupes;
}

sub dupe { goto \&dupestr }

sub dupe_ci {
    my @res;

    my %mem;
    my $undef_added;
    for (@_) {
        if (defined) {
            push @res, $_ if $mem{lc $_}++;
        } else {
            push @res, $_ if $undef_added++;
        }
    }
    @res;
}

sub pushuniqstr(\@@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $ary = shift;

    my %vals;
    for (@$ary) { $vals{$_}++ }

    for my $item (@_) {
        next if $vals{$item}++;
        push @$ary, $item;
    }
}

sub pushuniqnum(\@@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $ary = shift;

    my %vals;
    for (@$ary) { $vals{$_+0}++ }

    for my $item (@_) {
        next if $vals{$item+0}++;
        push @$ary, $item;
    }
}

sub pushuniqint(\@@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $ary = shift;

    my %vals;
    for (@$ary) { $vals{int $_}++ }

    for my $item (@_) {
        next if $vals{int $item}++;
        push @$ary, $item;
    }
}

sub pushuniq(\@@) { goto \&pushuniqstr } ## no critic: Subroutines::ProhibitSubroutinePrototypes

1;
# ABSTRACT: List utilities related to finding unique items

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::Uniq - List utilities related to finding unique items

=head1 VERSION

This document describes version 0.008 of List::Util::Uniq (from Perl distribution List-Util-Uniq), released on 2024-01-19.

=head1 SYNOPSIS

 use List::Util::Uniq qw(
     uniq
     uniqint
     uniqnum
     uniqstr

     is_monovalued
     is_monovalued_ci
     is_uniq
     is_uniq_ci
     uniq_adj
     uniq_adj_ci
     uniq_ci

     dupe
     dupeint
     dupenum
     dupestr
     dupe_ci

     pushuniq
     pushuniqint
     pushuniqnum
     pushuniqstr
 );

 $res = is_monovalued(qw/a a a/); # => 1
 $res = is_monovalued(qw/a b a/); # => 0

 $res = is_monovalued_ci(qw/a a A/); # => 1
 $res = is_monovalued_ci(qw/a b A/); # => 0

 $res = is_uniq(qw/a b a/); # => 0
 $res = is_uniq(qw/a b c/); # => 1

 $res = is_uniq_ci(qw/a b A/); # => 0
 $res = is_uniq_ci(qw/a b c/); # => 1

 @res = uniq_adj(1, 4, 4, 3, 1, 1, 2); # => (1, 4, 3, 1, 2)

 @res = uniq_adj_ci("a", "b", "B", "c", "a"); # => ("a", "b", "c", "a")

 @res = uniq_ci("a", "b", "B", "c", "a"); #  => ("a", "b", "c")

 @res = dupe("a","b","a","a","b","c"); #  => ("a","a","b")
 @res = dupeint(1,1.2,1.3,2); #  => (1.2,1.3)
 @res = dupenum(1,2,1,1,2,3); #  => (1,1,2)
 @res = dupenum("a",0,0.0,1); #  => (0,0.0), because "a" becomes 0 numerically
 @res = dupestr("a","b","a","a","b","c"); # => ("a","a","b")

 @res = dupe_ci("a", "b", "B", "c", "a"); #  => ("B", "a")

 my @ary = (1,"a",2,1,"a","b"); pushuniqstr @ary, 1,"a","c","c";   # @ary is now (1,"a",2,1,"a","b","c")
 my @ary = (1,"1.0",1.1,2); pushuniqnum @ary, 2,"1.00",1.2,"1.000",3,3;   # @ary is now (1,"1.0",1.1,2,1.2,3)
 my @ary = (1,"1.0",1.1,2); pushuniqint @ary, 2,"1.00",1.2,"1.000",3,3;   # @ary is now (1,"1.0",1.1,2,3)

=head1 DESCRIPTION

This module supplements L<List::Util> with functions related to list item's
uniqueness.

=for Pod::Coverage ^(uniq|uniqint|uniqnum|uniqstr)+

=head1 FUNCTIONS

None exported by default but exportable.

=head2 uniq

See L</uniqstr>.

=head2 uniqnum

Usage:

 my @uniq = uniqnum(@list);

Like L<List::Util>'s C<uniqnum>. This module provides a pure-Perl implementation
for convenience and so we do not need to depend on List::Util.

=head2 uniqint

Usage:

 my @uniq = uniqint(@list);

Like L<List::Util>'s C<uniqint>. This module provides a pure-Perl implementation
for convenience and so we do not need to depend on List::Util.

=head2 uniqstr

Usage:

 my @uniq = uniqstr(@list);

Like L<List::Util>'s C<uniqstr>. This module provides a pure-Perl implementation
for convenience and so we do not need to depend on List::Util.

=head2 uniq_adj

Usage:

 my @uniq = uniq_adj(@list);

Remove I<adjacent> duplicates from list, i.e. behave more like Unix utility's
B<uniq> instead of L<List::Util>'s C<uniq> function. Uses string equality
test (the C<eq> operator).

=head2 uniq_adj_ci

Like L</uniq_adj> except case-insensitive.

=head2 uniq_ci

Like C<List::Util>' C<uniq> (C<uniqstr>) except case-insensitive.

=head2 is_uniq

Usage:

 my $is_uniq = is_uniq(@list);

Return true when the values in C<@list> is unique (compared string-wise). In
theory, knowing whether a list has unique values is faster using this function
compared to doing:

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

=head2 dupe

See L</dupestr>.

=head2 dupeint

Like L</dupestr> but the values are compared as integers. If you only want to
list each duplicate elements once, you can do:

 @uniq_dupes = uniqint(dupeint(@list));

where C<uniqint> can be found in L<List::Util>, but the pure-perl version is
also provided by this module, for convenience.

=head2 dupenum

Like L</dupestr> but the values are compared numerically. If you only want to
list each duplicate elements once, you can do:

 @uniq_dupes = uniqnum(dupenum(@list));

where C<uniqnum> can be found in L<List::Util>, but the pure-perl version is
also provided by this module, for convenience.

=head2 dupestr

Usage:

 @dupes = dupestr(@list);

Return duplicate elements (the second and subsequence occurrences of each
element) in C<@list>. If you only want to list each duplicate elements once, you
can do:

 @uniq_dupes = uniqstr(dupestr(@list));

where C<uniqstr> can be found in L<List::Util>, but the pure-perl version is
also provided by this module, for convenience.

=head2 dupe_ci

Like L</dupe> except case-insensitive.

=head2 pushuniq

See L</pushuniqstr>.

=head2 pushuniqstr

Usage:

 pushuniqstr @ary, LIST;

Push items of I<LIST> to I<@ary> only if items are not already in C<@ary> (using
string-wise equal comparison operator, C<eq>). Shortcut for something like:

 for my $item (LIST) { push @ary, $_ unless grep { $item eq $_ } @ary }

=head2 pushuniqnum

Usage:

 pushuniqnum @ary, LIST;

Push items of I<LIST> to I<@ary> only if items are not already in C<@ary> (using
numeric equal comparison operator, C<==>). Shortcut for something like:

 for my $item (LIST) { push @ary, $_ unless grep { $item == $_ } @ary }

=head2 pushuniqint

Usage:

 pushuniqnum @ary, LIST;

Push items of I<LIST> to I<@ary> only if items are not already in C<@ary> (using
integer equal comparison). Shortcut for something like:

 for my $item (LIST) { push @ary, $_ unless grep { int($item) == int($_) } @ary }

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-Uniq>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-Uniq>.

=head1 SEE ALSO

L<List::Util>

Other C<List::Util::*> modules.

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

This software is copyright (c) 2024, 2023, 2018 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-Uniq>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
