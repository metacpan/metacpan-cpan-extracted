#! perl -T
#
# categorize.t
#
# Tests for List::Categorize::categorize().
#

use strict;
use warnings;

use Test::More tests => 14;
use Test::Deep;
use Test::NoWarnings;

use List::Categorize qw( categorize );


# List of products, IDs, and prices. Used as sample data for several tests.
#
# Note: The order of this list, and of the "expected" lists in the tests
# below, is important. The comparison functions check for proper
# ordering of the sublists.
#
my @sample_data =
(
    { name => 'Aspirin',        id => 'Z1111',  price =>   5.00 },
    { name => 'Bookshelf',      id => 'Y2222',  price =>  74.99 },
    { name => 'Coffee Maker',   id => 'X3333',  price =>  69.50 },
    { name => 'Doorknob',       id => 'W4444',  price =>  -1    }, # bad price
    { name => 'Envelope',       id => 'V5555'                   }, # no price
    { name => 'Fax Machine',    id => 'U6666',  price =>  37.99 },
    { name => 'Golf Club',      id => 'T7777',  price => 120.00 },
    { name => 'Hat Rack',       id => 'S8888',  price =>  48.50 },
    { name => 'Ice Cream',      id => 'R9999',  price =>   3.99 },
    { name => 'Jump Rope',      id => 'Q0000',  price =>   4.25 },
    { name => 'Ketchup',        id => 'P1111',  price =>   1.50 },
    { name => 'Letter Opener',  id => 'O2222',  price =>   9.99 },
    { name => 'Medicine Ball',  id => 'N3333',  price =>  35.00 },
    { name => 'Night Light',    id => 'M4444',  price =>   4.99 },
    { name => 'Oil Can',        id => 'L5555',  price =>   6.45 },
    { name => 'Potato Peeler',  id => 'K6666',  price =>   6.99 },
    { name => 'Quartz Crystal', id => 'J7777',  price =>   1.99 },
    { name => 'Rowboat',        id => 'I8888',  price => 275.00 },
    { name => 'Sunscreen',      id => 'H9999',  price =>   2.99 },
    { name => 'Towel',          id => 'G0000',  price =>  13.80 },
    { name => 'Umbrella',       id => 'F1111',  price =>  22.99 },
    { name => 'Vibraphone',     id => 'E2222',  price => 118.60 },
    { name => 'Wheelbarrow',    id => 'D3333',  price => 179.00 },
    { name => 'Xylophone',      id => 'C4444',  price => 279.00 },
    { name => 'Yucca Plant',    id => 'B5555',  price =>  18.00 },
    { name => 'Zither',         id => 'A6666',  price =>  72.10 },
);


## Test Sections

test_list_of_simple_scalars();
test_list_of_hashrefs_by_name();
test_list_of_hashrefs_by_price();
test_simple_size_limited_sublists();
test_list_of_hashrefs_by_name_size_limited();
test_list_of_lists();
test_empty_list();
test_sublist_element_transform();
test_collapsing_sublist_element_transform();
test_ignored_elements();
test_categorizer_args();

# Test::NoWarnings automatically inserts an additional test
# that makes sure no warnings were emitted during testing.


## Subroutines

sub test_list_of_simple_scalars
{
    my %expected =
    (
        ODD  => [ 1, 3, 5, 7, 9 ],
        EVEN => [ 2, 4, 6, 8 ],
    );

    # Group the numbers into odds and evens (modulo 2 is true for odds,
    # false for evens).
    #
    my %odds_and_evens = categorize { $_ % 2 ? 'ODD' : 'EVEN' } ( 1 .. 9 );

    cmp_deeply(\%odds_and_evens, \%expected,
        'List of simple scalars to hash of sublists by odd/even'
    );
}


sub test_list_of_hashrefs_by_name
{
    my %expected_by_name =
    (
        'A-G' =>
        [
            { name => 'Aspirin',        id => 'Z1111',  price =>    5.00 },
            { name => 'Bookshelf',      id => 'Y2222',  price =>   74.99 },
            { name => 'Coffee Maker',   id => 'X3333',  price =>   69.50 },
            { name => 'Doorknob',       id => 'W4444',  price =>   -1    },
            { name => 'Envelope',       id => 'V5555'                    },
            { name => 'Fax Machine',    id => 'U6666',  price =>   37.99 },
            { name => 'Golf Club',      id => 'T7777',  price =>  120.00 },
        ],

        'H-M' =>
        [
            { name => 'Hat Rack',       id => 'S8888',  price =>   48.50 },
            { name => 'Ice Cream',      id => 'R9999',  price =>    3.99 },
            { name => 'Jump Rope',      id => 'Q0000',  price =>    4.25 },
            { name => 'Ketchup',        id => 'P1111',  price =>    1.50 },
            { name => 'Letter Opener',  id => 'O2222',  price =>    9.99 },
            { name => 'Medicine Ball',  id => 'N3333',  price =>   35.00 },
        ],

        'N-T' =>
        [
            { name => 'Night Light',    id => 'M4444',  price =>    4.99 },
            { name => 'Oil Can',        id => 'L5555',  price =>    6.45 },
            { name => 'Potato Peeler',  id => 'K6666',  price =>    6.99 },
            { name => 'Quartz Crystal', id => 'J7777',  price =>    1.99 },
            { name => 'Rowboat',        id => 'I8888',  price =>  275.00 },
            { name => 'Sunscreen',      id => 'H9999',  price =>    2.99 },
            { name => 'Towel',          id => 'G0000',  price =>   13.80 },
        ],

        'U-Z' =>
        [
            { name => 'Umbrella',       id => 'F1111',  price =>   22.99 },
            { name => 'Vibraphone',     id => 'E2222',  price =>  118.60 },
            { name => 'Wheelbarrow',    id => 'D3333',  price =>  179.00 },
            { name => 'Xylophone',      id => 'C4444',  price =>  279.00 },
            { name => 'Yucca Plant',    id => 'B5555',  price =>   18.00 },
            { name => 'Zither',         id => 'A6666',  price =>   72.10 },
        ],
    );

    # Build sublists based on the uppercased first letter of each
    # product name.
    #
    my %sublists_by_name = categorize {

        for ( uc $_->{name} )
        {
            return
                /^[A-G]/ ? 'A-G'     :
                /^[H-M]/ ? 'H-M'     :
                /^[N-T]/ ? 'N-T'     :
                /^[U-Z]/ ? 'U-Z'     :
                           'Unknown' ;
        }

    } @sample_data;

    cmp_deeply(\%sublists_by_name, \%expected_by_name,
        'List of hashrefs to hash of sublists by name'
    );
}


sub test_list_of_hashrefs_by_price
{
    my %expected_by_price =
    (
        '0.00 - 10.00'  =>
        [
            { name => 'Aspirin',        id => 'Z1111',  price =>   5.00 },
            { name => 'Ice Cream',      id => 'R9999',  price =>   3.99 },
            { name => 'Jump Rope',      id => 'Q0000',  price =>   4.25 },
            { name => 'Ketchup',        id => 'P1111',  price =>   1.50 },
            { name => 'Letter Opener',  id => 'O2222',  price =>   9.99 },
            { name => 'Night Light',    id => 'M4444',  price =>   4.99 },
            { name => 'Oil Can',        id => 'L5555',  price =>   6.45 },
            { name => 'Potato Peeler',  id => 'K6666',  price =>   6.99 },
            { name => 'Quartz Crystal', id => 'J7777',  price =>   1.99 },
            { name => 'Sunscreen',      id => 'H9999',  price =>   2.99 },
        ],

        '10.00 - 20.00' =>
        [
            { name => 'Towel',          id => 'G0000',  price =>  13.80 },
            { name => 'Yucca Plant',    id => 'B5555',  price =>  18.00 },
        ],

        '20.00 - 30.00' =>
        [
            { name => 'Umbrella',       id => 'F1111',  price =>  22.99 },
        ],


        '30.00 - 40.00' =>
        [
            { name => 'Fax Machine',    id => 'U6666',  price =>  37.99 },
            { name => 'Medicine Ball',  id => 'N3333',  price =>  35.00 },
        ],

        'Other' =>
        [
            { name => 'Bookshelf',      id => 'Y2222',  price =>  74.99 },
            { name => 'Coffee Maker',   id => 'X3333',  price =>  69.50 },
            { name => 'Doorknob',       id => 'W4444',  price =>  -1    },
            { name => 'Golf Club',      id => 'T7777',  price => 120.00 },
            { name => 'Hat Rack',       id => 'S8888',  price =>  48.50 },
            { name => 'Rowboat',        id => 'I8888',  price => 275.00 },
            { name => 'Vibraphone',     id => 'E2222',  price => 118.60 },
            { name => 'Wheelbarrow',    id => 'D3333',  price => 179.00 },
            { name => 'Xylophone',      id => 'C4444',  price => 279.00 },
            { name => 'Zither',         id => 'A6666',  price =>  72.10 },
        ],

        'Unspecified' =>
        [
            { name => 'Envelope',       id => 'V5555'                   },
        ]
    );

    # Group products by price.
    #
    my %sublists_by_price = categorize {

        return 'Unspecified' unless exists $_->{price};

        my $price = $_->{price};

        return
            ( $price >= 0.00 and $price <= 10.00 ) ?  '0.00 - 10.00' :
            ( $price > 10.00 and $price <= 20.00 ) ? '10.00 - 20.00' :
            ( $price > 20.00 and $price <= 30.00 ) ? '20.00 - 30.00' :
            ( $price > 30.00 and $price <= 40.00 ) ? '30.00 - 40.00' :
                                                     'Other'         ;
    } @sample_data;

    cmp_deeply(\%sublists_by_price, \%expected_by_price,
        'List of hashrefs to hash of sublists by price'
    );
}


sub test_simple_size_limited_sublists
{
    my %expected =
    (
        '(0)' => [  'A' .. 'E' ],
        '(1)' => [  'F' .. 'J' ],
        '(2)' => [  'K' .. 'M' ],
    );

    my $element_count = 0;

    my %sublists = categorize {
        '(' . int($element_count++ / 5) . ')'
    } ( 'A' .. 'M' );

    cmp_deeply(\%sublists, \%expected,
        'List of simple scalars to hash of size-limited sublists'
    );
}


sub test_list_of_hashrefs_by_name_size_limited
{
    my %expected_by_name_size_limited =
    (
        'A-M (0)' =>
        [
            { name => 'Aspirin',        id => 'Z1111',  price =>   5.00 },
            { name => 'Bookshelf',      id => 'Y2222',  price =>  74.99 },
            { name => 'Coffee Maker',   id => 'X3333',  price =>  69.50 },
            { name => 'Doorknob',       id => 'W4444',  price =>  -1    },
            { name => 'Envelope',       id => 'V5555'                   },
        ],

        'A-M (1)' =>
        [
            { name => 'Fax Machine',    id => 'U6666',  price =>  37.99 },
            { name => 'Golf Club',      id => 'T7777',  price => 120.00 },
            { name => 'Hat Rack',       id => 'S8888',  price =>  48.50 },
            { name => 'Ice Cream',      id => 'R9999',  price =>   3.99 },
            { name => 'Jump Rope',      id => 'Q0000',  price =>   4.25 },
        ],

        'A-M (2)' =>
        [
            { name => 'Ketchup',        id => 'P1111',  price =>   1.50 },
            { name => 'Letter Opener',  id => 'O2222',  price =>   9.99 },
            { name => 'Medicine Ball',  id => 'N3333',  price =>  35.00 },
        ],

        'N-Z (0)' =>
        [
            { name => 'Night Light',    id => 'M4444',  price =>   4.99 },
            { name => 'Oil Can',        id => 'L5555',  price =>   6.45 },
            { name => 'Potato Peeler',  id => 'K6666',  price =>   6.99 },
            { name => 'Quartz Crystal', id => 'J7777',  price =>   1.99 },
            { name => 'Rowboat',        id => 'I8888',  price => 275.00 },
        ],

        'N-Z (1)' =>
        [
            { name => 'Sunscreen',      id => 'H9999',  price =>   2.99 },
            { name => 'Towel',          id => 'G0000',  price =>  13.80 },
            { name => 'Umbrella',       id => 'F1111',  price =>  22.99 },
            { name => 'Vibraphone',     id => 'E2222',  price => 118.60 },
            { name => 'Wheelbarrow',    id => 'D3333',  price => 179.00 },
        ],

        'N-Z (2)' =>
        [
            { name => 'Xylophone',      id => 'C4444',  price => 279.00 },
            { name => 'Yucca Plant',    id => 'B5555',  price =>  18.00 },
            { name => 'Zither',         id => 'A6666',  price =>  72.10 },
        ],
    );

    # Categorize products by name, but limit the sublists to 5 items or
    # fewer. Incorporate the "sublist index" into the category name
    # hash key.

    my %sublist_count = ();

    my %sublists_by_name_size_limited = categorize {

        # This avoids having to init each sublist count to 0.
        #
        no warnings 'uninitialized';

        # Check for 'name' before attempting to use it, to avoid
        # autovivifying a spurious entry in the hash that $_
        # references.
        #
        return 'Unknown' unless exists $_->{name};

        my $name = $_->{name};

        # Determine the base name of this sublist, based on the
        # uppercased first letter of the name.
        #
        my $sublist_basename = $name =~ /^[A-M]/ ? 'A-M'     :
                               $name =~ /^[N-Z]/ ? 'N-Z'     :
                                                   'Unknown' ;

        # Determine the index of this sublist, based on the number
        # of elements of the (base) category that have been seen so far.
        # The max size of each sublist is 5 (in this case), so that's
        # what we divide by to determine which sublist we're loading.
        #
        my $sublist_index = int($sublist_count{$sublist_basename} / 5);

        # Bump up the number of times we've seen this particular
        # base category. Note that the sublist index isn't included
        # here; it's just the category basename.
        #
        $sublist_count{ $sublist_basename }++;

        # Return the full name of the sublist by combining the
        # base category name with the current sublist index.
        #
        return "$sublist_basename ($sublist_index)";

    } @sample_data;

    cmp_deeply(
        \%sublists_by_name_size_limited,
        \%expected_by_name_size_limited,
        'List of hashrefs to hash of size-limited sublists by name'
    );
}


sub test_list_of_lists
{
    my @source =
    (
        [ 'a' .. 'z' ],
        [ ],
        [ 0 .. 25 ],
        [ ],
        [ 'one' ],
        [ ],
        [ 'one', 'two' ],
    );

    my %expected_by_length =
    (
        0   => [ [], [], [] ],
        1   => [ [ 'one' ] ],
        2   => [ [ 'one', 'two' ] ],
        26  => [ [ 'a' .. 'z' ], [ 0 .. 25 ] ],
    );

    # Categorize each list by its length. (Each sublist in the hash
    # will be a list of lists.)
    #
    my %sublists_by_length = categorize { scalar @{ $_ } } @source;

    cmp_deeply(\%sublists_by_length, \%expected_by_length,
        'List of lists to hash of sublists by sublist length'
    );
}


sub test_empty_list
{
    my %sublists = categorize { 'Zilch' } ();

    cmp_deeply(\%sublists, {}, 'Empty list to empty hash');
}


sub test_sublist_element_transform
{
    my @source = qw( apple banana antelope bear canteloupe coyote );

    my %expected =
    (
      A => [ 'Apple', 'Antelope' ],
      B => [ 'Banana', 'Bear' ],
      C => [ 'Canteloupe', 'Coyote' ]
    );

    # Categorize by the uppercased first letter of each element.
    #
    my %capitalized = categorize {
        $_ = ucfirst $_;
        substr($_, 0, 1);
    } @source;

    cmp_deeply(\%capitalized, \%expected,
        'Transformation for simple scalars'
    );

    # Make sure that the original list hasn't been touched
    # by transforming (copies of) the source elements.
    #
    cmp_deeply(
        \@source,
        [ qw( apple banana antelope bear canteloupe coyote ) ],
        'Original source list unchanged after transformation'
    );
}


sub test_collapsing_sublist_element_transform
{
   my %expected =
   (
        List =>
        [
            'Aspirin - Z1111',
            'Bookshelf - Y2222',
            'Coffee Maker - X3333',
            'Doorknob - W4444',
            'Envelope - V5555',
            'Fax Machine - U6666',
            'Golf Club - T7777',
            'Hat Rack - S8888',
            'Ice Cream - R9999',
            'Jump Rope - Q0000',
            'Ketchup - P1111',
            'Letter Opener - O2222',
            'Medicine Ball - N3333',
            'Night Light - M4444',
            'Oil Can - L5555',
            'Potato Peeler - K6666',
            'Quartz Crystal - J7777',
            'Rowboat - I8888',
            'Sunscreen - H9999',
            'Towel - G0000',
            'Umbrella - F1111',
            'Vibraphone - E2222',
            'Wheelbarrow - D3333',
            'Xylophone - C4444',
            'Yucca Plant - B5555',
            'Zither - A6666',
        ]
   );

   my %sublists = categorize {

       # Don't use the element as-is. Instead, create a new sublist
       # element by combining the name and the ID.
       #
       $_ = $_->{name} . ' - ' . $_->{id};

       # Provide the sublist key name as usual.
       #
       return 'List';

   } @sample_data;

   cmp_deeply(\%sublists, \%expected,
       'Collapsed sublist elements collapses hashref elements'
   );
}


sub test_ignored_elements
{
    my %expected =
    (
        Teens => [ 13 .. 19 ]
    );

    # Keep 13 through 19 and toss everything else.
    #
    my %sublists = categorize {

        return 'Teens' if ($_ >= 13 and $_ <= 19);

        return;

    } ( 0 .. 20 );

    cmp_deeply(\%sublists, \%expected, 'Ignored elements');

    # Make sure "false" keys (0 and the empty string) are legal, even
    # when elements are ignored. (That is, make sure that categorize()
    # is smart enough to know the difference among '', 0, and undef.)
    #
    my %expected_with_false_keys =
    (
        0   => [ 0 ],
        ''  => [ 1 ],
        '+' => [ 2 .. 5 ],
    );

    my %sublists_with_false_keys = categorize {

        # Store zero under 0.
        return 0 if $_ == 0;

        # Store 1 under the empty string.
        return '' if $_ == 1;

        # Store other positives under '+'.
        return '+' if $_ > 1;

        # Ignore all other elements. They'll be left out entirely.
        return;

    } ( -5 .. 5 );

    cmp_deeply(\%sublists_with_false_keys, \%expected_with_false_keys,
        'Ignored elements, with empty strings as legal hash keys'
    );
}


sub test_categorizer_args
#
# Make sure that the categorizer subroutine can safely
# change @_ without affecting the @_ of categorize() itself.
#
# This is a fix for a bug reported by Johan Lodin:
# http://rt.cpan.org/Public/Bug/Display.html?id=49910
#
{
    my %expected = ( a => [0], b => [1], c => [2] );

    my %sublists = categorize {

        # If this affects the categorize() @_ array, then %sublists
        # won't be correct.
        #
        @_ = ();

        chr( ord('a') + $_ );

    } ( 0 .. 2 );

    cmp_deeply(\%sublists, \%expected,
        'Changing @_ in categorizer has no effect'
    );
}

# end categorize.t
