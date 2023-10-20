package List::Util::mapsplice;

use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-09-30'; # DATE
our $DIST = 'List-Util-mapsplice'; # DIST
our $VERSION = '0.001'; # VERSION

our @EXPORT_OK = qw(
                       mapsplice
               );

sub mapsplice(&\@;$$) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my ($code, $array, $offset, $length) = @_;

    $offset = 0 unless defined $offset;
    $offset = @$array+$offset if $offset < 0;
    die "OutOfBoundError" if $offset < 0 || $offset >= @$array;
    $length = @$array unless defined $length;

    my @indices;
    my @origs;
    my @results;
    my $i = 0;
    for my $index ($length >= 0 ? ($offset .. $#{$array}) : (reverse 0 .. $offset)) {
        {
            local $_ = $array->[$index];
            my @result = $code->($_, $index);
            push @indices, $index;
            push @origs, $array->[$index];
            push @results, \@result;
        }
        last if ++$i >= abs($length);
    }

  SPLICE:
    my @removed;
    for my $i (reverse 0 .. $#indices) {
        unshift @removed, $origs[$i];
        splice @$array, $indices[$i], 1, @{ $results[$i] };
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
# ABSTRACT: Splice array with code, replace items with result from code

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::mapsplice - Splice array with code, replace items with result from code

=head1 VERSION

This document describes version 0.001 of List::Util::mapsplice (from Perl distribution List-Util-mapsplice), released on 2023-09-30.

=head1 SYNOPSIS

 use List::Util::mapsplice qw(masplice);

 my @ary = (1,2,3,4,5,6,7,8,9,10);

 # 1. remove all even numbers (equivalent to: @ary = grep { !($_ % 2 == 0) } @ary  or  @ary = map { $_ % 2 == 0 ? () : ($_) } @ary

 #                                       --------------------------- 1st param: code to match elements to remove
 #                                      /     ---------------------- 2nd param: the array
 #                                     /     /  -------------------- 3rd param: (optional) offset to start mapping, negative offset allowed
 #                                    /     /  /   ----------------- 4th param: (optional) number of elements to process, negative number allowed to reverse the direction of processing
 #                                   /     /  /   /
 mapsplice { $_ % 2 == 0 ? () : ($_) } @ary        ;  # => (1,3,5,7,9)

 # 2. replace all even numbers with two elements containing half of the original number, equivalent to: @ary = map { $_ % 2 == 0 ? ($_/2, $_/2) : ($_) } @ary
 mapsplice { $_ % 2 == 0 ? ($_/2, $_/2) : ($_) } @ary;  # => (1, 1,1, 3, 2,2, 5, 3,3, 7, 4,4, 9, 5,5)

 # 4. replace first two even numbers with their negative values
 mapsplice { $_ % 2 == 0 ? (-$_) : ($_) } @ary, 0, 4;  # => (1,-2,3,-4,5,6,7,8,9,10)

 # 5. replace the last two even numbers with their negative values
 mapsplice { $_ % 2 == 0 ? (-$_) : ($_) } @ary, -1, -4;  # => (1,2,3,4,5,6,7,-8,9,-10)

=head1 DESCRIPTION

This module provides L</mapsplice>.

=head1 FUNCTIONS

Not exported by default but exportable.

=head2 mapsplice

Usage:

 mapsplice CODE ARRAY, OFFSET, LENGTH
 mapsplice CODE ARRAY, OFFSET
 mapsplice CODE ARRAY

C<mapsplice> sort of combines C<map> and C<splice> (hence the name). You provide
a code which will be called for each element of array and is expected to return
zero or more replacement for the element. A simple C<map> usually can also do
the job, but C<mapsplice> offers these: 1) directly modify the array; 2) option
to limit the range of elements to process; 3) element index in C<$_[1]>; 4)
return the replaced elements.

In B<CODE>, C<$_> (as well as C<$_[0]>) is set to the element. C<$_[1]> is set
to the index of the element.

The third parameter, C<OFFSET>, is the array index to start processing, 0
meaning the first element. Default if not specified is 0. Negative number is
allowed, -1 means the last element, -2 the second last and so on. An
out-of-bound error will be thrown if index outside of the array is specified.

The fourth parameter, C<LENGTH>, is the number of elements to process. Undef
means unlimited/all, and is the default if unspecified. Negative number is
allowed, meaning to process backwards to decreasing index. If the end of array
(or beginning if direction is backwards) is reached, processing is stopped.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-mapsplice>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-mapsplice>.

=head1 SEE ALSO

C<map> and C<splice> in L<perlfunc>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-mapsplice>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
