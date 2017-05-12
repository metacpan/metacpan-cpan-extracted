use strict;
use warnings;

use Test::Most;
#use XXX;

use Doc::Simply;
use Doc::Simply::Extractor;

plan qw/no_plan/;

{
    my $extractor = Doc::Simply::Extractor::SlashStar->new;
    my $comments = $extractor->extract(<<'_END_');
/*
 * @head2 Icky nesting
 * Some content
 *
 * @head1 Hello, World.
 *
 * @head2 Yikes. 
 * Some more content
 * With some *markdown* content!
 *
 *      And some more
 *      And some inline code
 *
 */

/* Ignore this...
*/

/* @body 
 * ...but grab **this**!
        */

// Another ignoreable comment
_END_
    cmp_deeply($comments, [
        [ block => map { $_ . " " }  <<'_END_' ],

 * @head2 Icky nesting
 * Some content
 *
 * @head1 Hello, World.
 *
 * @head2 Yikes. 
 * Some more content
 * With some *markdown* content!
 *
 *      And some more
 *      And some inline code
 *
_END_
        [ block => <<'_END_' ],
 Ignore this...
_END_
        [ block => map { local $_ = $_; chomp; $_ } <<'_END_' ],
 @body 
 * ...but grab **this**!
        
_END_
        [ line => ' Another ignoreable comment' ],
    ]);
}

{
    my $extractor = Doc::Simply::Extractor::SlashStar->new;
    my $comments = $extractor->extract(<<'_END_');
    /* 
     * @head1 NAME
     *
     * Calculator - Add 2 + 2 and return the result
     *
     */

    // @head1 DESCRIPTION
    // @body Add 2 + 2 and return the result (which should be 4)

    /*
     * @head1 FUNCTIONS
     *
     * @head2 twoPlusTwo
     *
     * Add 2 and 2 and return 4
     *
     */

    function twoPlusTwo() {
        return 2 + 2; // Should return 4
    }
_END_
    cmp_deeply($comments, [
        [ block => re(qr{
            .*\@head1\ NAME.*
            .*\QCalculator - Add 2 + 2 and return the result\E.*
        }sx) ],
        [ line => ' @head1 DESCRIPTION' ],
        [ line => ' @body Add 2 + 2 and return the result (which should be 4)' ],
        [ block => re(qr{
            .*\@head1\ FUNCTIONS.*
            .*\@head2\ twoPlusTwo.*
            .*\QAdd 2 and 2 and return 4\E.*
        }sx) ],
        [ line => ' Should return 4' ],
    ]);
}

__END__

my $extractor = Doc::Simply::Extractor->new(
    filter => sub {
        s/^\s*#\s*//;
    }, 
    matcher => sub {
        return unless m/^(?:=|\@)([\w]+)(.*)$/; ($1, $2);
    }
);

cmp_deeply(reverse [], [ $extractor->extract(<<'_END_') ]);
@head2
@cut
# cut
_END_

cmp_deeply(reverse [
    { qw/begin 1 head head2/, body => " Xyzzy" },
    ], [ $extractor->extract(<<'_END_') ]);
@head2
# @head2 Xyzzy
_END_

cmp_deeply(reverse [
    { qw/head head2 begin 1/, body => " Xyzzy" },
    { qw/body More/ },
    { qw/head cut/ },
    ], [ $extractor->extract(<<'_END_') ]);
@head2
# @head2 Xyzzy
# More
# @cut
# Ignore this 
_END_

cmp_deeply(reverse [
    { qw/head head2 begin 1/, body => " Xyzzy" },
    { qw/body More/ },
    { body => "And more" },
    { qw/head cut begin 1/ },
    ], [ $extractor->extract(<<'_END_') ]);
@head2
# @head2 Xyzzy
# More
# And more

# But not this
@head3 Ignore this
# @cut
# Or this 
_END_

1;
