package List::Util::groupby;

use 5.010001;
use strict;
use warnings;

use Exporter 'import';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-11-20'; # DATE
our $DIST = 'List-Util-groupby'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(
                       groupby
                       hgroupby
               );

sub groupby(&;@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $code = shift;

    my @result;
    my $index = -1;
    for my $item (@_) {
        $index++;
        my $result_index;
        { local $_ = $item; $result_index = $code->($item, $index) }
        if (ref($result_index) eq 'ARRAY') {
            my $temp = \@result;
            for my $i (0 .. $#{ $result_index }) {
                $temp->[ $result_index->[$i] ] //= [];
                $temp = $temp->[ $result_index->[$i] ];
            }
            push @$temp, $item;
        } else {
            $result[$result_index] //= [];
            push @{ $result[$result_index] }, $item;
        }
    }
    @result;
}

sub hgroupby(&;@) { ## no critic: Subroutines::ProhibitSubroutinePrototypes
    my $code = shift;

    my %result;
    my $index = -1;
    for my $item (@_) {
        $index++;
        my $result_index;
        { local $_ = $item; $result_index = $code->($item, $index) }
        if (ref($result_index) eq 'ARRAY') {
            my $temp = \%result;
            for my $i (0 .. $#{ $result_index }) {
                $temp->{ $result_index->[$i] } //= $i == $#{ $result_index } ? [] : {};
                $temp = $temp->{ $result_index->[$i] };
            }
            push @$temp, $item;
        } else {
            $result{$result_index} //= [];
            push @{ $result{$result_index} }, $item;
        }
    }
    %result;
}

1;
# ABSTRACT: Group items of a list into several (possibly multilevel) buckets

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Util::groupby - Group items of a list into several (possibly multilevel) buckets

=head1 VERSION

This document describes version 0.004 of List::Util::groupby (from Perl distribution List-Util-groupby), released on 2023-11-20.

=head1 SYNOPSIS

 use List::Util::groupby qw(groupby hgroupby);

 my @buckets = groupby { $_ % 2 } 1..10; # => [ [2,4,6,8,10], [1,3,5,7,9] ]
 my @buckets = groupby { [$_ % 2, $_ % 3] } 1..10; # => [ [ [6], [4,10], [2,8]], [ [3,9], [1,7], [5] ] ]

 my @recs = (
   {name=>"andi",date=>"2023-09-29",result=>9.8},
   {name=>"andi",date=>"2023-09-30",result=>10.3},
   {name=>"budi",date=>"2023-09-29",result=>11.1},
   {name=>"budi",date=>"2023-09-30",result=>10.5},
 my %buckets = hgroupby { $_->{name} } @recs;
 # => (
 #   andi => [ {name=>"andi",date=>"2023-09-29",result=>9.8} , {name=>"andi",date=>"2023-09-30",result=>10.3} ],
 #   budi => [ {name=>"budi",date=>"2023-09-29",result=>11.1}, {name=>"budi",date=>"2023-09-30",result=>10.5} ],
 # )

 my %buckets = hgroupby { [$_%2, $_%3] } 1..10;
 #{
 #  "0" => { "0" => [6], "1" => [4, 10], "2" => [2, 8] },
 #  "1" => { "0" => [3, 9], "1" => [1, 7], "2" => [5] },
 #}

=head1 DESCRIPTION

This module provides L</groupby> and L</hgroupby>.

=head1 FUNCTIONS

Not exported by default but exportable.

=head2 groupby

Usage:

 @buckets = groupby CODE ARRAY

Group a list into several buckets.

In B<CODE>, C<$_> (as well as C<$_[0]>) is set to array element. C<$_[1]> is set
to the index of the element, so you can still group elements by their position.
Code is expected to return an integer index to indicate which bucket the item
should be grouped into. Code can also return an arrayref of integer indices for
multilevel buckets.

Return a (possibly multilevel) array of arrayrefs.

=head2 hgroupby

Usage:

 %buckets = hgroupby CODE ARRAY

Just like L</groupby>, except code is expected to return keys (of arrayref of
keys) and the function will return a (possibly multilevel) hash of arrayrefs.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/List-Util-groupby>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-List-Util-groupby>.

=head1 SEE ALSO

L<Array::Group>, L<Array::GroupBy>, L<List::GroupBy>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=List-Util-groupby>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
