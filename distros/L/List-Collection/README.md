# NAME

List::Collection - List::Collection

# VERSION

version 0.0.4

# SYNOPSIS

    use List::Collection;
    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my @c = qw/5 6 7 8 9 10/;

    # get intersection set between two or more List
    my @intersect = intersect(\@a, \@b, \@c);  # result is (5,6)

    # get union set between two or more List
    my @union = union(\@a, \@b, \@c);    # result is (1,2,3,4,5,6,7,8,9,10)

    # get substraction between two
    my @substract = subtract(\@a, \@b);  # result is (1,2,3)

    # get complementation between two or more
    my @complement = complement(\@a, \@b);  # result is (1,2,3,7,8,9)

Or in a object-oriented way

    use List::Collection;
    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my $lc = List::Collection->new();
    my @union = $lc->union(\@a, \@b);
    my @intersect = $lc->intersect(\@a, \@b);

# DESCRIPTION

Blablabla

# METHODS

## new

List::Collection's construction function

## intersect

Intersection of multiple Lists, number of parameter could be bigger than two and type is ArrayRef

    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my @intersect = intersect(\@a, \@b);

## union

union set of multiple Lists, number of parameter could be bigger than two and type is ArrayRef

    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my @union = union(\@a, \@b);

## subtract

subtraction(difference set) of two Lists, input parameters' type is ArrayRef

    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my @subtract = subtract(\@a, \@b);

## complement 

complement set of multiple Lists, number of parameter could be bigger than two and  type is ArrayRef

    my @a = qw/1 2 3 4 5 6/;
    my @b = qw/4 5 6 7 8 9/;
    my @complement = complement(\@a, \@b);

# AUTHOR

Yan Xueqing <yanxueqing621@163.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
