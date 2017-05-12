#!/usr/bin/env perl -w
use strict;
use Test::More tests => 1;

use Markapl::FromHTML;
use Perl::Tidy qw(perltidy);

my $html = <<HTML;
<h1>Hello World</h1>
<div>
  <p>I am the third one. With a <a href="#">hyperlink.</a></p>
</div>
HTML

my $h2m = Markapl::FromHTML->new;

$h2m->load($html);

my ($h1, $h2) = ($h2m->dump, <<MARKAPL);
sub {
    h1 { "Hello World" };
    div {
        p {
            outs "I am the third one. With a ";
            a( href => "#" ) { "hyperlink." };
        };
    };
}
MARKAPL

is $h1, $h2;
