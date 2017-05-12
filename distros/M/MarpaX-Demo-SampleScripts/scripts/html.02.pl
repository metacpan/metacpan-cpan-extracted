#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Marpa::R2 2.082000;
use Marpa::R2::HTML qw(html);

# Author: Jeffrey Kegler.

# ---------------------------

# The strategy is based on a values view
# We give values to tables and links
# Each value is a list of link entries, of
# the form "[ text, boolean ]", where text
# is the text of the link, and the boolean indicates
# whether we think it is in a table.

# In the strategy, we record each link as not in
# a table when we first find it, and then, when
# in the process of upward traversal we find we were
# in table, set the boolean.

my %handlers_to_scrape_table_links = (

    # When we first find a link, the link entry list contains one link,
    # which has the in-table boolean unset.
    a => sub {
        my @link_entry = [ Marpa::R2::HTML::original(), 0 ];
        return \@link_entry;
    },

    # When we find a table, all links become table links
    table => sub {

        # For all the lists of links
        my @new_link_entry_list = ();
        for my $list_of_links ( @{ Marpa::R2::HTML::values() } ) {

            # For each link, ignore the boolean and push a new entry with
            # the boolean set
            push @new_link_entry_list, [ $_->[0], 1 ] for @{$list_of_links};
        } ## end for my $list_of_links ( @{ Marpa::R2::HTML::values() ...})

        # Return a new list of link entry, will all in-table booleans set
        return \@new_link_entry_list;
    },

    # At the top, we return the table links as a reference to an array
    ':TOP' => sub {
        my @links;
        for my $list_of_links ( @{ Marpa::R2::HTML::values() } ) {

            # For each link
            for my $link_entry ( @{$list_of_links} ) {
                my ( $link_text, $is_in_table ) = @{$link_entry};
                push @links, $link_text if $is_in_table;
            }
        } ## end for my $list_of_links ( @{ Marpa::R2::HTML::values() ...})
        return \@links;
    }
);

my @input = (
    qq{<a href="one">Link not in table</a>\n}
        . qq{Text<table><tr><td>I am a cell<a href="two">link</a></table> More Text\n}
        . qq{<a href="three">Link not in table</a>\n},
    qq{Text<tr><a href="four">link1</a>I am a cell\n}
        . qq{<a href="five">link with missing tag</table> More Text\n},
    qq{<a href="six">Link not in table</a>\n},
);

for my $input (@input) {

    say "HTML:";
    say $input;

    my $value_ref = html( \$input, \%handlers_to_scrape_table_links );
    die "HTML parse failed" if not defined $value_ref;

    my $table_link_count = scalar @{$value_ref};
    say "Found $table_link_count table link(s)";
    for my $ix ( 0 .. $table_link_count-1 ) {
        say "Link $ix: ", $value_ref->[$ix];
    }

    print "\n";

} ## end for my $input (@input)
