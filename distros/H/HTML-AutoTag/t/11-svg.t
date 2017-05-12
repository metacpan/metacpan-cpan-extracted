#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

use HTML::AutoTag;

my $auto = HTML::AutoTag->new( sorted => 1 );

is $auto->tag(
    tag => 'svg',
    attr => { width=>"12cm", height=>"4cm", viewBox=>"0 0 1200 400", xmlns=>"http://www.w3.org/2000/svg", version=>"1.1" },
    cdata => [
        {
            tag => 'desc',
            cdata => 'Example circle01 - circle filled with red and stroked with blue',
        },
        {
            tag => 'rect',
            attr => { x=>"1", y=>"1", width=>"1198", height=>"398", fill=>"none", stroke=>"blue", 'stroke-width'=>"2" },
        },
        {
            tag => 'circle',
            attr => { cx=>"600", cy=>"200", r=>"100", fill=>"red", stroke=>"blue", 'stroke-width'=>"10" },
        },
    ]
),
    '<svg height="4cm" version="1.1" viewBox="0 0 1200 400" width="12cm" xmlns="http://www.w3.org/2000/svg"><desc>Example circle01 - circle filled with red and stroked with blue</desc><rect fill="none" height="398" stroke="blue" stroke-width="2" width="1198" x="1" y="1" /><circle cx="600" cy="200" fill="red" r="100" stroke="blue" stroke-width="10" /></svg>',
    "valid SVG";

__DATA__
http://www.w3.org/TR/SVG/images/shapes/circle01.svg
<svg width="12cm" height="4cm" viewBox="0 0 1200 400" xmlns="http://www.w3.org/2000/svg" version="1.1">
  <desc>Example circle01 - circle filled with red and stroked with blue</desc>

  <rect x="1" y="1" width="1198" height="398" fill="none" stroke="blue" stroke-width="2"/>

  <circle cx="600" cy="200" r="100" fill="red" stroke="blue" stroke-width="10"  />
</svg>
