package List::Rank;

our $DATE = '2018-01-26'; # DATE
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(rank rankstr rankby sortrank sortrankstr sortrankby);

sub rank(@) {
    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort { $a->[0] <=> $b->[0] } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if ($ary[$i-1][0] == $ary[$i][0]) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { $_->[2] } sort { $a->[1] <=> $b->[1] } @ary;
}

sub rankstr(@) {
    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort { $a->[0] cmp $b->[0] } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if ($ary[$i-1][0] eq $ary[$i][0]) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { $_->[2] } sort { $a->[1] <=> $b->[1] } @ary;
}

sub rankby(&;@) {
    no strict 'refs';

    my $cmp = shift;

    my $caller = caller();

    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort {
        local ${"$caller\::a"} = $a->[0];
        local ${"$caller\::b"} = $b->[0];
        $cmp->();
    } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if (do {
                local ${"$caller\::a"} = $ary[$i-1][0];
                local ${"$caller\::b"} = $ary[$i][0];
                !$cmp->();
            }) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { $_->[2] } sort { $a->[1] <=> $b->[1] } @ary;
}

sub sortrank(@) {
    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort { $a->[0] <=> $b->[0] } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if ($ary[$i-1][0] == $ary[$i][0]) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { ($_->[0], $_->[2]) } @ary;
}

sub sortrankstr(@) {
    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort { $a->[0] cmp $b->[0] } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if ($ary[$i-1][0] eq $ary[$i][0]) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { ($_->[0], $_->[2]) } @ary;
}

sub sortrankby(&;@) {
    no strict 'refs';

    my $cmp = shift;

    my $caller = caller();

    my @ary;
    my $i = 0;
    for (@_) { push @ary, [$_, $i++, undef] }
    @ary = sort {
        local ${"$caller\::a"} = $a->[0];
        local ${"$caller\::b"} = $b->[0];
        $cmp->();
    } @ary;
    my $j = 1;
    for ($i=0; $i<@ary; $i++) {
        if ($i == 0) {
            $ary[$i][2] = $j;
        } else {
            if (do {
                local ${"$caller\::a"} = $ary[$i-1][0];
                local ${"$caller\::b"} = $ary[$i][0];
                !$cmp->();
            }) {
                $ary[$i-1][2] = $ary[$i][2] = "$j=";
            } else {
                $j = $i+1;
                $ary[$i][2] = $j;
            }
        }
    }
    map { ($_->[0], $_->[2]) } @ary;
}

1;
# ABSTRACT: Ranking of list elements

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Rank - Ranking of list elements

=head1 VERSION

This document describes version 0.002 of List::Rank (from Perl distribution List-Rank), released on 2018-01-26.

=head1 SYNOPSIS

Return the ranks of the elements if sorted numerically (note that equal values
will be given equal ranks):

 my @ranks = rank 10, 30, 20, 20; # => 1, 4, "2=", "2="

Return the ranks of the elements if sorted ascibetically:

 my @ranks = rankstr "apricot", "cucumber", "banana", "banana"; # => 1,4,"2=","2="

Return the ranks of the elements if sorted by a custom sorter:

 my @ranks = rankby {length($a) <=> length($b)}
     "apricot", "cucumber", "banana", "banana"; # => 3, 4, "1=", "1="

Sort the list numerically and return the elements as well as ranks in pairs:

 my @res = sortrank 10, 30, 20, 20; => 10,1, 20,"2=", 20,"2=", 30,4

Sort the list ascibetically and return the elements as well as ranks in pairs:

 my @res = sortrankstr "apricot", "cucumber", "banana", "banana";
     # => "apricot",1, "banana","2=", "banana","2=", "cucumber",4

Sort the list by a custom sorter and return the elements as well as ranks in
pairs:

 my @res = sortrankby "apple", "cucumber", "banana", "banana";
     # => "banana","1=", "banana","1=", "apricot",3, "cucumber",4

=head1 FUNCTIONS

=head2 rank

=head2 rankstr

=head2 rankby

=head2 sortrank

=head2 sortrankstr

=head2 sortrankby

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Rank>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Rank>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Rank>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Sort::Rank>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
