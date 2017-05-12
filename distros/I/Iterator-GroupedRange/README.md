[![Build Status](https://travis-ci.org/zigorou/p5-iterator-groupedrange.png?branch=master)](https://travis-ci.org/zigorou/p5-iterator-groupedrange)
# NAME

Iterator::GroupedRange - Iterates retrieving a set of specified number rows

# SYNOPSIS

    use Iterator::GroupedRange;

    my @ds = (
      [ 1 .. 6 ],
      [ 7 .. 11 ],
      [ 11 .. 25 ],
    );

    my $i1 = Iterator::GroupedRange->new( sub { shift @ds; }, 10 );
    $i1->next; # [ 1 .. 10 ]
    $i1->next; # [ 11 .. 20 ]
    $i1->next; # [ 21 .. 25 ]

    my $i2 = Iterator::GroupedRange->new( [ 1 .. 25 ], 10 );
    $i2->next; # [ 1 .. 10 ]
    $i2->next; # [ 11 .. 20 ]
    $i2->next; # [ 21 .. 25 ]

# DESCRIPTION

Iterator::GroupedRange is module to iterate retrieving a set of specified number rows.
Code reference or list reference becomes provider of sets.

It accepts other iterator to get rows, or list.

# METHODS

## new( \\&provider\[, $range, \\%opts\] )

## new( \\@list\[, $range, \\%opts\] )

Return new instance. Arguments details are:

- &provider

    The code reference must be taking a list reference or undef.
    If the return value is undef or empty array reference, [#has\_next()](https://metacpan.org/pod/#has_next\(\)) will return false value.

- @list

    This list reference will be code reference that will be return a set of specified number rows.

- $range

    Most number of retrieving rows by each iteration. Default value is 1000.

- %opts
    - range

        Grouped size.

    - rows

        Number of rows. For example, using [DBI](https://metacpan.org/pod/DBI)'s statement handle:

            my $sth = $dbh->prepare('SELECT blah FROM example');
            $sth->execute;
            my $iter; $iter = Iterator::GroupedRange->new(sub {
                if ( my $ids = $sth->fetchrow_arrayref( undef, $iter->range ) ) {
                    return [ map { $_->[0] } @$ids ];
                }
                else {
                    return;
                }
            }, { rows => $sth->rows, range => 1000 });

## has\_next()

Return which the iterator has next rows or not.

## next()

Return next rows.

## is\_last()

Return which the iterator becomes ended of iteration or not.

## append(@items)

## append(\\@items)

Append new items.

## range()

Return grouped size.

## rows()

Return total rows.

# AUTHOR

Toru Yamaguchi <zigorou@cpan.org>

# SEE ALSO

- [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils)

    [List::MoreUtils](https://metacpan.org/pod/List::MoreUtils) has `natatime` subroutine looks like this module.
    The `natatime` subroutine can treat only list.

- [DBI](https://metacpan.org/pod/DBI)

    [DBI](https://metacpan.org/pod/DBI)'s fetchall\_arrayref can accepts max\_rows argument.
    This feature is similar to this module. For example:

        use DBI;
        use Data::Dumper;

        my $sth = $dbh->prepare('SELECT id FROM people');
        while ( my $ids = $sth->fetchall_arrayref(undef, 100) ) {
            $ids = [ map { $_->[0] } @$ids ];
            warn Dumper($ids);
        }

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
