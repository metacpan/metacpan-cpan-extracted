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

my @lyrics = (
    'Goodbye Rubik Tuesday',
    'Who Could Hang a Name on Cubes?',
);
my $ul = HTML::Make->new ('ul', attr => {class => 'cubik-newsday'});
my $li1 = $ul->push ('li', text => $lyrics[0]);
my $li2 = $ul->push ('li', text => $lyrics[1]);
my $ch = $ul->children ();
cmp_ok (scalar (@$ch), '==', 2, "Got two children");
cmp_ok ($ch->[0]->type (), 'eq', 'li', "Got li element as first");
my $grandch = $ch->[0]->children ();
cmp_ok (scalar (@$grandch), '==', 1, "Got one grandchild");
cmp_ok ($grandch->[0]->type (), 'eq', 'text', "Got a text type");
my $textback = $grandch->[0]->text ();
cmp_ok ($textback, 'eq', $lyrics[0], "Got text back");
my $attr = $ul->attr ();
cmp_ok ($attr->{class}, 'eq', 'cubik-newsday', "Got class back");

done_testing ();
