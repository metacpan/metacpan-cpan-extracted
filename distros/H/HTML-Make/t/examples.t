# In the future, this file is intended to be machine-generated from
# the examples themselves.

use warnings;
use strict;
use HTML::Make;
use Test::More;

my $obj = HTML::Make->new ('li');
$obj->add_attr (class => 'beano');
my $obj_text = $obj->text ();
is ($obj_text, "<li class=\"beano\"></li>\n");

my $element = HTML::Make->new ('p');
$element->add_text ('peanuts');
my $text = $element->text ();
like ($text, qr!<p>\s*peanuts\s*</p>!);

my $p = HTML::Make->new ('p');
my $p_text = $p->text ();
like ($p_text, qr!<p>\s*</p>!);

my $ol = HTML::Make->new ('ol');
$ol->multiply ('li', ['one', 'two', 'three']);
my $ol_text =  $ol->text ();
like ($ol_text, qr!<ol>\s*<li>\s*one</li>\s*<li>two</li>\s*<li>three</li>\s*</ol>!);

done_testing ();
