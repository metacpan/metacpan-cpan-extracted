use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use HTML::Make;

my $el1 = HTML::Make->new ('h1', class => 'melon');
$el1->add_class ('maron');
my $el1out = $el1->text ();
like ($el1out, qr!class=["']melon maron["']!);

my $el2 = HTML::Make->new ('table');
$el2->add_class ('chair');
$el2->add_class ('vase');
my $el2out = $el2->text ();
like ($el2out, qr!class=["']chair vase["']!);

done_testing ();
