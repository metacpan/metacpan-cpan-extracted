#!/usr/bin/perl

use 5.014;
use strict;
use warnings;
use HTML::Grabber;

undef $/;
my $dom = HTML::Grabber->new(html => <DATA>);
$dom->find('tr')->each(sub {
    say '-- row --';
    say $_->find('td')->length;
    say $_->find('th')->length;
    say $_->find('td, th')->length;
});

__DATA__
<html>
    <table>
        <tbody>
            <tr>
                <th>Name</th>
                <td>Martyn</td>
            </tr>
            <tr>
                <th>Age</th>
                <td>32</td>
            </tr>
            <tr>
                <th>Favourite Colour</th>
                <td>Purple</td>
            </tr>
        </tbody>
    </table>
</html>
