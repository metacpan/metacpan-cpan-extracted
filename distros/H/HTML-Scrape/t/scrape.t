#!/usr/bin/perl

use 5.010;
use strict;
use warnings;

use Test::More tests => 10;
use Test::Warnings;

use HTML::Scrape;


SIMPLE: {
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> simple </title>
    </head>
    <body>
        <p id="outer">
            This is a <span id="inner">inner tag</span>
            <input type="self-closing" />
            <br />
            and <span id="inner2">another inner</span>.
            <br>
        </p>
    </body>
</html>
HTML

    my $expected = {
        'inner2'  => 'another inner',
        'inner'   => 'inner tag',
        'outer'   => 'This is a inner tag and another inner.',
        'nothing' => undef,
    };

    _check_single_ids( $html, $expected, 'Simple' );
    _check_all_ids( $html, $expected, 'Simple' );
}


UNCLOSED_TAGS_THAT_ARE_OK: {
    my $html = <<'HTML';
<!DOCTYPE html>
<html>
    <head>
        <title> unclosed </title>
    </head>
    <body>
        <ul>
            <li id="one"> uno
            <li id="two"> dos
            <li id="three"> tres </li>
            <li id="four"> cuatro
        </ul>
        <p id="p1">
        stuff
        </p>
        <p id="p2">
        more stuff
        <p id="p3">
        still more stuff
    </body>
</html>
HTML

    my $expected = {
        'one'     => 'uno',
        'two'     => 'dos',
        'three'   => 'tres',
        'four'    => 'cuatro',
        'p1'      => 'stuff',
        'p2'      => 'more stuff',
        'p3'      => 'still more stuff',
        'nothing' => undef,
    };
    _check_single_ids( $html, $expected, 'Unclosed tags' );
    _check_all_ids( $html, $expected, 'Unclosed tags' );
}


PARTIAL_DOCUMENTS: {
    my $html = <<'HTML';
<table>
    <tr>
        <td>blah blah</td>
        <td id="cell1">One</td>
    </tr>
    <tr>
        <td>blah blah</td>
        <td id="cell2">Two</td>
HTML

    my $expected = {
        'cell1'     => 'One',
        'cell2'     => 'Two',
        'nothing' => undef,
    };

    _check_single_ids( $html, $expected, 'Partial document' );
    # Don't check on _check_all_ids because it will complain about unclosed tags.
}


BLOCK_ELEMENT_SPACING: {
    my $html = <<'HTML';
<div id="AAA">
    one<br>two<br />three<hr>
</div>
<div id="BBB">
    two<span>-by-</span>four
</div>
<div id="CCC">
    foo<p>bar</p>bat
</div>
<div id="DDD">
    bingo<hr>bongo<table>bingo</table>bongo
</div>

HTML

    my $expected = {
        AAA => 'one two three',
        BBB => 'two-by-four',
        CCC => 'foo bar bat',
        DDD => 'bingo bongo bingo bongo',
    };

    _check_single_ids( $html, $expected, 'Block element spacing' );
    _check_all_ids( $html, $expected, 'Block element spacing' );
}


EMPTY_TAGS: {
    # Even if a tag has no content it should still exist with a blank value.

    my $html = <<'HTML';
<div id="AAA">
    Stuff
    <hr id="HR">
    More stuff
    <input id="next_page" class="small button" type="submit" name="next.x" value="Next Page">
    Still more stuff
    <p>
        Cavalcade of stuff
    </p>
</div>
HTML

    my $expected = {
        HR        => '',
        next_page => '',
        prev_page => undef,
        AAA       => 'Stuff More stuff Still more stuff Cavalcade of stuff',
    };

    _check_single_ids( $html, $expected, 'Empty tags' );
    _check_all_ids( $html, $expected, 'Empty tags' );
}


exit 0;


sub _check_single_ids {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $html     = shift;
    my $expected = shift;
    my $msg      = shift // die;

    return subtest $msg => sub {
        plan tests => 2 * keys %{$expected};

        # For each value, scrape it two different ways.
        while ( my ($id,$exp) = each %{$expected} ) {
            # Check it via scrape_id.
            is( HTML::Scrape::scrape_id( $id, $html ), $exp, $id );

            if ( defined $exp ) {
                my $all_ids = HTML::Scrape::scrape_all_ids( $html, $id );
                is_deeply( $all_ids, { $id => $exp } );
            }
            else {
                pass( 'Exp is undef' );
            }
        }
    };
}


sub _check_all_ids {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $html     = shift;
    my $expected = shift;
    my $msg      = shift // die;

    return subtest $msg => sub {
        plan tests => 1;

        my %existing;
        while ( my ($k,$v) = each %{$expected} ) {
            $existing{$k} = $v if defined $v;
        }

        my $ids = HTML::Scrape::scrape_all_ids( $html );
        is_deeply( $ids, \%existing );
    };
}
