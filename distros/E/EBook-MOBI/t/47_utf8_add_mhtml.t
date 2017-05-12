#!/usr/bin/perl

use utf8;
use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 1;

use EBook::MOBI;
use Encode;
my $obj = EBook::MOBI->new();
$obj->set_encoding(':encoding(UTF-8)');

my $text = encode_utf8("<p>Here is some Chinese text - 你好!</p>");
$obj->add_mhtml_content($text);
$obj->make();
my $res = $obj->print_mhtml(1);

# The text should not be different after adding it.
like($res, qr|$text</body>|s, 'Direct add_mhtml_content OK');


########
# done #
########
1;

