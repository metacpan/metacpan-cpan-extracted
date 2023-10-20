package List::Util::sglice;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-18'; # DATE
our $DIST = 'List-Util-sglice'; # DIST
our $VERSION = '0.002'; # VERSION

our @EXPORT_OK = qw(
                       sglice
                       msplice
               );

sub sglice(&\@;$) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my ($code, $array, $num_remove) = @_;

    $num_remove = @$array unless defined $num_remove;

    my @indices;
    if ($num_remove >= 0) {
        for my $index (0 .. $#{$array}) {
            goto REMOVE if @indices >= $num_remove;
            if (do { local $_ = $array->[$index]; $code->($_, $index) }) {
                push @indices, $index;
            }
        }
    } else {
        for my $index (reverse 0 .. $#{$array}) {
            goto REMOVE if @indices >= -$num_remove;
            if (do { local $_ = $array->[$index]; $code->($_, $index) }) {
                unshift @indices, $index;
            }
        }
    }

    return unless @indices;

  REMOVE:
    my @removed;
    for my $index (reverse @indices) {
        unshift @removed, splice(@$array, $index, 1);
    }

  RETURN:
    my $wantarray = wantarray;
    if ($wantarray) {
        return @removed;
    } elsif (defined $wantarray) {
        return $removed[-1];
    } else {
        return;
    }
}
1;
# ABSTRACT: Remove some elements where code returns true

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::sglice - Remove some elements where code returns true

=head1 VERSION

This document describes version 0.002 of List::Util::sglice (from Perl distribution List-Util-sglice), released on 2023-09-18.

=head1 SYNOPSIS

 use List::Util::sglice qw(sglice);

 my @ary = (1,2,3,4,5,6,7,8,9,10);

 # 1. remove all even numbers (equivalent to: @ary = grep { !($_ % 2 == 0) } @ary

 #                       --------------------------- 1st param: code to match elements to remove
 #                      /     ---------------------- 2nd param: the array
 #                     /     /  -------------------- 3rd param: (optional) how many matching elems to remove, undef means all, negative allowed to mean last N matching elems
 #                    /     /  /
 sglice { $_ % 2 == 0 } @ary    ;  # => (1,3,5,7,9)

 # 3. remove first two even numbers
 sglice { $_ % 2 == 0 } @ary,  2;  # => (1,3,5,6,7,8,9,10)

 # 4. remove last two even numbers
 sglice { $_ % 2 == 0 } @ary, -2;  # => (1,2,3,4,5,6,7,9)

 # 5. remove elements #0..#2, equivalent to: splice @ary, 0, 2
 sglice { $_[1] <= 2  } @ary;      # => (4,5,6,7,8,9,10)

 # 6. put even numbers to the beginning of array
 unshift @ary, sglice { $_ % 2 == 0 } @ary;  # => (2,4,6,8,10,  1,3,5,7,9)

=head1 DESCRIPTION

This module provides L</sglice>.

=head1 FUNCTIONS

Not exported by default but exportable.

=head2 sglice

Usage:

 sglice CODE ARRAY, NUM_TO_REMOVE
 sglice CODE ARRAY

C<sglice> (mnemonic: "g" is for I<grep>) somewhat resembles C<splice>. Instead
of specifying offset and number of elements to remove from C<ARRAY>, you specify
C<CODE> to match elements to remove. Unlike C<splice>, C<sglice> does not let
you reinsert new items (see L<List::Util::msplice> for that).

In B<CODE>, C<$_> (as well as C<$_[0]>) is set to array element. C<$_[1]> is set
to the index of the element, so you can still remove elements by their position.

The third parameter, C<NUM_TO_REMOVE>, is the number of elements to remove. If
unspecified, all matching elements will be removed. You can also specify
negative integer to remove NUM last matching elements. Setting this to 0
effectively means a no-op.

In list context, the function returns the removed elements. In scalar context,
it returns the last removed elements.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-sglice>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-sglice>.

=head1 SEE ALSO

L<List::Util::mapsplice>.

C<splice> in L<perlfunc>.

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-sglice>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
