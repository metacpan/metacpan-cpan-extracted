# This is a test for module HTML::Make::Page.

use warnings;
use strict;
use utf8;
use Test::More;
use_ok ('HTML::Make::Page');
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

use HTML::Make::Page 'make_page';

my ($enpage, undef) = make_page (lang => 'en', quiet => 1);
my $text = $enpage->text ();
like ($text, qr!<html lang="en"!, "Got language on html tag");

done_testing ();
# Local variables:
# mode: perl
# End:
