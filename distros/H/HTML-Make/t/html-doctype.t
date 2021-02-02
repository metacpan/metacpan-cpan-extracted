use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use HTML::Make;

my $html = HTML::Make->new ('html');
my $text = $html->text ();
like ($text, qr{<!DOCTYPE html>\n<html>\s*</html},
      "Added doctype to html tag");

done_testing ();
