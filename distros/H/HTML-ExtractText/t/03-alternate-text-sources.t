#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Deep;

# plan tests => 22;

use HTML::ExtractText;

{ # check basic extraction
    my $ext = HTML::ExtractText->new( separator => undef, ignore_not_found => 0);
    my $result = $ext->extract(
        {
            text_no_attr => '.text',
            text_empty   => '#empty',
            text     => '[type="text"][value="V2"]',
            password => '[type="password"]',
            image    => '[type="image"]',
            option   => 'option',
            select   => 'select',
            textarea => 'textarea',
            img      => 'img#one',
            img_no_alt => 'img#no_alt',
        },
        '
        <input type="text" id="empty">
        <input class="text" value="V1">
        <input type="text" value="V2">
        <input type="password" value="V3">
        <input type="image" alt="V4">
        <select>
            <option>S1</option>
            <option value="S2">S3</option>
        </select>
        <textarea>V5</textarea>
        <img src="" alt="V6" id="one">
        <img src="" id="no_alt">
        ',
    );

    my $expected_result = {
        text_no_attr     => ['V1'],
        text_empty  => [''],
        text     => ['V2'],
        password => ['V3'],
        image    => ['V4'],
        option   => [qw/S1 S3/],
        select   => ['S1 S3'],
        textarea => ['V5'],
        img      => ['V6'],
        img_no_alt => [''],
    };

    cmp_deeply $result, $expected_result, 'return of ->extract';
    cmp_deeply +{%$ext}, $expected_result, 'hash interpolation of object';
    cmp_deeply $ext->last_results, $expected_result,
        'return from ->last_results()';
}

done_testing();