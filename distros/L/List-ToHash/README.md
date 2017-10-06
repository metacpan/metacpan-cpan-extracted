[![Build Status](https://travis-ci.org/akiym/List-ToHash.svg?branch=master)](https://travis-ci.org/akiym/List-ToHash)
# NAME

List::ToHash - List to hash which have unique keys

# SYNOPSIS

    use List::ToHash qw/to_hash/;
    my @users = (
        {
            id => 1,
            value => 'foo',
        },
        {
            id => 2,
            value => 'bar',
        },
    );
    my $x = to_hash { $_->{id} } @users;
    # {
    #     "1" => {
    #        "id" => 1,
    #        "value" => "foo"
    #     },
    #     "2" => {
    #        "id" => 2,
    #        "value" => "bar"
    #     }
    # };

# DESCRIPTION

List::ToHash provides fast conversion list to hash by using lightweight callback API.

`map` is so simple and good for readability. I usually use this in this situation.

    my $x = +{map { ($_->{id} => $_) } @users};

`List::Util::reduce` is a little tricky however it works faster than `map`.

    my $x = List::Util::reduce { $a->{$b->{id}} = $b; $a } ({}, @ARRAY);

`for` is lame... Look, it spends two lines.

    my $x = {};
    $x->{$_->{id}} = $_ for @users;

`List::ToHash::to_hash` is a quite simple way, more faster.

    my $x = List::ToHash::to_hash { $_->{id} } @users;

## BENCHMARK

List::ToHash is the fastest module in this benchmark `eg/bench.pl`.

    Benchmark: running for, map, reduce, to_hash for at least 3 CPU seconds...
           for:  3 wallclock secs ( 3.18 usr +  0.01 sys =  3.19 CPU) @ 19303.13/s (n=61577)
           map:  3 wallclock secs ( 3.13 usr +  0.02 sys =  3.15 CPU) @ 13437.46/s (n=42328)
        reduce:  3 wallclock secs ( 3.20 usr +  0.02 sys =  3.22 CPU) @ 18504.66/s (n=59585)
       to_hash:  4 wallclock secs ( 3.12 usr +  0.01 sys =  3.13 CPU) @ 26635.78/s (n=83370)
               Rate     map  reduce     for to_hash
    map     13437/s      --    -27%    -30%    -50%
    reduce  18505/s     38%      --     -4%    -31%
    for     19303/s     44%      4%      --    -28%
    to_hash 26636/s     98%     44%     38%      --

# FUNCTIONS

- my $hashref = to\_hash { ... } @list;

    Returns the hash reference of given `@list` for which have the key returned by the block.

        my $id_to_user_row = to_hash { $_->{id} } @user_rows;

# LICENSE

Copyright (C) Takumi Akiyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Takumi Akiyama &lt;t.akiym@gmail.com>
