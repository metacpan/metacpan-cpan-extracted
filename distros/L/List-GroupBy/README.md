# NAME

List::GroupBy - Group a list of hashref's to a multilevel hash of hashrefs of arrayrefs

# SYNOPSIS

    use List::GroupBy qw( groupBy );

    my @list = (
        { firstname => 'Fred',   surname => 'Blogs', age => 20 },
        { firstname => 'George', surname => 'Blogs', age => 30 },
        { firstname => 'Fred',   surname => 'Blogs', age => 65 },
        { firstname => 'George', surname => 'Smith', age => 32 },
        { age => 99 },
    );

    my %groupedList = groupBy ( [ 'surname', 'firstname' ], @list );

    # %groupedList => (
    #     'Blogs' => {
    #         'Fred' => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         'George' => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #     },
    #     'Smith' => {
    #         'George' => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    #     '' => {
    #         '' => [
    #             { age => 99 },
    #         },
    #     },
    # )


    %groupedList = groupBy(
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'blogs' }
        },
        @list
    );

    # %groupedList => (
    #     Blogs => {
    #         Fred => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         George => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #         '' => [
    #             { age => 99 },
    #         ],
    #     },
    #     Smith => {
    #         George => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    # )


    %groupedList = groupBy (
        {
            keys => [ 'surname', 'firstname' ],
            defaults => { surname => 'Blogs' },
            operations => { surname => sub { uc $_[0] } },
        },
        @list
    );

    # %groupedList => (
    #     BLOGS => {
    #         Fred => [
    #             { firstname => 'Fred',   surname => 'Blogs', age => 20 },
    #             { firstname => 'Fred',   surname => 'Blogs', age => 65 },
    #         ],
    #         George => [
    #             { firstname => 'George', surname => 'Blogs', age => 30 },
    #         ],
    #         '' => [
    #             { age => 99 },
    #         ],
    #     },
    #     SMITH => {
    #         George => [
    #             { firstname => 'George', surname => 'Smith', age => 32 },
    #         ],
    #     },
    # )

# DESCRIPTION

List::GroupBy provides functions to group a list of hashrefs in to a hash of
hashrefs of arrayrefs.

# FUNCTIONS

- `groupBy( [ 'primary key', 'secondary key', ... ], LIST )`

    If called with and array ref as the first parameter then `groupBy` will group
    the list by the keys provided in the array ref.

    Note: undefined values for a key will be defaulted to the empty string.

    Returns a hash of hashrefs of arrayrefs

- `groupBy( { keys => [ 'key', ... ], defaults => { 'key' => 'default', ... }, operations => { 'key' => sub, ... }, LIST )`

    More advanced options are available by calling `groupBy` with a hash ref of
    options as the first parameter.  Available options are:

    - `keys` (Required)

        An array ref of the keys to use for grouping. The order of the keys dictates
        the order of the grouping.  So the first key is the primary grouping, the
        second key is used for the secondary grouping under the primary grouping an so
        on.

    - `defaults` (Optional)

        A hash ref of defaults to use one or more keys.  If a key for an item is
        undefined and there's an entry in the `defaults` option then that will be
        used. If no default value has been supplied for a key then the empty string
        will be used.

    - `operations` (Optional)

        A hash ref mapping keys to a function to use to normalise value's when
        grouping. If there's no entry for a key then the value is just used as is.

        Each funtion is passed the value as it's only parameter and it's return
        value is used for the key.

    Returns a hash of hashrefs of arrayrefs

# LICENSE

Copyright (C) Jason Cooper.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jason Cooper <JLCOOPER@cpan.org>
