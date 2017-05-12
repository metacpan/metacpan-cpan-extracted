#!/usr/bin/perl -T

use strict;
use warnings;
use Test::More tests => 2;
use HTML::Element;

my $div = new HTML::Element('div')->push_content('super class content');

like(
    $div->as_HTML,
    qr{<div>super class content</div>},
    'HTML::Element output'
);

my $mydiv = new MyElement('div')->push_content( [ 'div', $div ] );
like(
    $mydiv->as_HTML,
    qr{<div><div><div>super class content</div></div></div>},
    'MyElement output'
);

package MyElement;
use base 'HTML::Element';

sub new {
    my $invoker = shift;
    my $class = ref $invoker || $invoker;

    return $class->SUPER::new(@_);
}

