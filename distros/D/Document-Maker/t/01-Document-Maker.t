#!perl -T

use strict;
use warnings;

use Test::More qw/no_plan/;

ok(1); # Hee, hee

1;

__END__

use Document::Maker;
use Directory::Scratch;

use constant Maker => "Document::Maker";

my $scratch = new Directory::Scratch;
$scratch->create_tree({
        'A/B/C/D/z.tt2.html' => <<_END_,
_END_
        'A/B/C/y.tt2.html' => <<_END_,
_END_
});
my $scratch_base = $scratch->base;

my $maker = Maker->new;
my $rule;

$rule = $maker->rule(
    tgt_pattern => qq/%.html/,
	src_pattern => qq/%.tt2.html/,
    tgt_lst => [qw(a.html b.html A/c.html)],
    src_lst => [$scratch_base->subdir(qw/A B C D/), $scratch_base->subdir(qw/A B C/)],
    do => sub {
        my $tgt = shift;
		my $src = shift;
		my $name = shift;
		diag "$tgt $src $name";
	}
);

$rule->build_all;

$rule = $maker->rule(
    {
        tgt_pattern => qq/%.html/,
        src_pattern => qq/%.tt2.html/,
        tgt_lst => [qw(a.html b.html A/c.html)],
    },
    {
        tgt_pattern => "Z/X/Y/%.html",
        src_pattern => qq/%.tt2.html/,
        src_lst => [$scratch_base->subdir(qw/A B C D/), $scratch_base->subdir(qw/A B C/)],
    },
    do => sub {
        my $tgt = shift;
		my $src = shift;
		my $name = shift;
		diag "$tgt $src $name";
	}
);

$rule->build_all;

$rule = $maker->rule(
    [ [qw( a.html b.html A/c.html )], "%*.html", "src/%.tt2.html", ],
    [ undef, "Z/Y/X/%.html", "%.tt2.html", [ $scratch_base->subdir(qw/ A B C D /), $scratch_base->subdir(qw/ A B C /) ] ],
    do => sub {
        my $tgt = shift;
		my $src = shift;
		my $name = shift;
		diag "$tgt $src $name";
	}
);

$rule->build_all;

ok(1);
