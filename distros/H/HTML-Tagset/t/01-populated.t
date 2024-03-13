#!perl

# Verify that all the hashes and arrays are populated.

use strict;
use warnings;

use Test::More tests => 32;

use HTML::Tagset;

my @vars = qw(
    %emptyElement
    %optionalEndTag
    %linkElements
    %boolean_attr
    %isPhraseMarkup
    %is_Possible_Strict_P_Content
    %isHeadElement
    %isList
    %isTableElement
    %isFormElement
    %isBodyElement
    %isHeadOrBodyElement
    %isKnown
    %canTighten
    %isCDATA_Parent

    @p_closure_barriers
);


HASHES: {
    for my $var ( grep { /%/ } @vars ) {
        $var =~ s/^%(.+)/%HTML::Tagset::$1/ or die;

        my %h = eval "$var";
        cmp_ok( scalar keys %h, '>', 0, "$var is not an empty hash" );

        my @undefs = grep { !defined } values %h;
        is( scalar @undefs, 0, "$var has no undef values" );
    }
}


ARRAYS: {
    for my $var ( grep { /@/ } @vars ) {
        $var =~ s/^\@(.+)/\@HTML::Tagset::$1/ or die;

        my @a = eval "$var";
        cmp_ok( scalar @a, '>', 0, "$var is not an empty array" );

        my @undefs = grep { !defined } @a;
        is( scalar @undefs, 0, "$var has no undef values" );
    }
}


exit;
