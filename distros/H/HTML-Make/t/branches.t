# This test file addresses some of the issues found by
# http://cpancover.com/latest/HTML-Make-0.15/blib-lib-HTML-Make-pm.html

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

my $blank = HTML::Make->new ();
is ($blank->text (), '', "Blank element");

my $x = HTML::Make->new ('p');
eval {
    $x->add_text (undef);
};
ok ($@, "Error adding undefined text");

{
    my $warnings;
    local $SIG{__WARN__} = sub { $warnings = "@_" };
    my $doofus = HTML::Make->new ('doofus', nocheck => 1);
    ok (! $warnings, "No warnings making invalid with nocheck");
    my $zoofus = HTML::Make->new ('zoofus');
    ok ($warnings, "Warnings making invalid without nocheck");
    like ($warnings, qr!Unknown tag type 'zoofus'!, "Check format of warning");
    my $blink = HTML::Make->new ('blink');
    like ($warnings, qr!<blink> is not HTML5!, "Check format of warning");
    my $p_bad_option = HTML::Make->new ('p', bingo => 1);
    like ($warnings, qr!Unknown option 'bingo'!,
	  "Check warning about unknown option");
    $warnings = undef;
    HTML::Make->new ('p', attr => {bingo => 1});
    ok ($warnings, "Got a warning with bad attribute");
    $warnings = undef;
    my $p = HTML::Make->new ('p', attr => {bingo => 1}, nocheck => 1);
    ok (! $warnings, "Got no warning with bad attribute and nocheck => 1");
    $warnings = undef;
    my $tr = HTML::Make->new ('tr');
    $tr->push ('p');
    ok ($warnings, "Got warnings pushing <p> to <tr> parent");
    $warnings = undef;
    my $newp = HTML::Make->new ('p');
    $newp->push ('li');
    ok ($warnings, "Got warnings pushing <li> to <p> parent");
    $warnings = undef;
    my $table = HTML::Make->new ('ul');
    $table->push ('td');
    ok ($warnings, "Got warnings pushing <td> to <ul> parent");
    $warnings = undef;

    my $p2 = HTML::Make->new ('p');
    my $p3 = HTML::Make->new ('p');
    my $span = HTML::Make->new ('span');
    $p2->push ($span);
    $p3->push ($span);
    ok ($warnings, "Got warnings pushing <span> to two different paragraphs");
    like ($warnings, qr!already has a parent!, "Got right warnings");
}

my $ul = HTML::Make->new ('ul');

eval {
    $ul->multiply (undef, [qw!a b c!]);
};
ok ($@, "Error from undefined element");

my $pid = HTML::Make->new ('p', id => 'paragraph');
like ($pid->text (), qr!<p.*id="paragraph">!, "Got id attribute");

my $pocus = HTML::Make->new ('p');
my $attr = $pocus->attr ();
is_deeply ($attr, {}, "Empty hash for attributes of p with no attributes");
my $children = $pocus->children ();
is_deeply ($children, [], "Empty array for children of p with no children");

done_testing ();
