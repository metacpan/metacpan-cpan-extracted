use warnings;
use strict;
use Test::More;
BEGIN { use_ok('HTML::Make') };
use HTML::Make;

my $html1 = HTML::Make->new ('table');
my $row1 = $html1->push ('tr');
my $cell1 = $row1->push ('td');
my $text1 = $html1->text ();

like ($text1, qr!<table.*?>.*?<tr.*?>.*?<td.*?>.*?</td>.*?</tr>.*?</table>!sm,
      "Nested HTML elements");

my $html2 = HTML::Make->new ('p', attr => {id => 'buggles'});
my $text2 = $html2->text ();

like ($text2, qr!<p id="buggles">!, "Use attribute");

my $html3 = HTML::Make->new ('p');
$html3->add_text ('person');
my $text3 = $html3->text ();
like ($text3, qr!<p>\s*person\s*</p>!, "Add text to element");

my $html4 = HTML::Make->new ('div', attr => {id => 'monkey'});
$html4->add_text ('boo');
my $p = $html4->push ('b');
$p->add_text ('bloody');
$html4->add_text ('hoo');
my $text4 = $html4->text ();
like ($text4, qr!<div id=\"monkey\">\s*boo<b>bloody</b>\s*hoo\s*</div>!,
    "Nested text and tags");

my $html5 = HTML::Make->new ('table');
my $row5 = $html5->push ('tr');
for my $heading (qw/red white black blue/) {
    $row5->push ('th', text => $heading);
}
my $text5 = $html5->text ();
like ($text5, qr!red.*white.*black.*blue.*!sm,
      "Insert elements using push with text");

my $html6 = HTML::Make->new ('ul');
my @list = qw/monkeys dandelions pineapples/;
$html6->multiply ('li', \@list);
my $text6 = $html6->text ();
#note ($text6);
like ($text6,
      qr!<li>monkeys</li>.*?<li>dandelions</li>.*?<li>pineapples</li>!sm,
      "Multiply elements");

eval {
    HTML::Make->new ('text');
};
ok ($@, "dies on making a text object");
eval {
    HTML::Make->new ('li', text => ['stuff']);
};
ok ($@, "dies if text is not a scalar");

# http://perlmaven.com/test-for-warnings-in-a-perl-module

{
    my @warnings;
    local $SIG{__WARN__} = sub {
	push @warnings, @_;
    };
    HTML::Make->new ('frog');
    is (@warnings, 1, "one warning issued");
    like ($warnings[0], qr/unknown tag/i, "detect unknown tags");
    @warnings = ();
    my $freaky = HTML::Make->new ('freaky', nocheck => 1);
    is (@warnings, 0, "no warnings issued when nocheck = 1");
    @warnings = ();
    my $TABLE = HTML::Make->new ('TABLE');
    is (@warnings, 0, "no warnings issued for upper-case tags");
};

{
    my @warnings;
    local $SIG{__WARN__} = sub {
	#	note (@_);
	push @warnings, @_;
    };
    my $tr = HTML::Make->new ('tr', attr => {onmouseover => 1});
    $tr->add_attr (onmouseover => 2);
    is (@warnings, 1, "one warning issued");
    like ($warnings[0], qr/overwriting attribute/i,
	  "detect overwrite attribute");
};

{
    my @warnings;
    local $SIG{__WARN__} = sub {
	push @warnings, @_;
    };
    my $table = HTML::Make->new ('table', attr => {cellspacing => 2});
    is (@warnings, 1, "got warning with bad attribute cellspacing on table");
    like ($warnings[0], qr/cellspacing is not allowed for <table>/,
	  "got correct warning for cellspacing on table");
};

{
    my @warnings;
    local $SIG{__WARN__} = sub {
	push @warnings, @_;
    };
    my $ul = HTML::Make->new ('ul');
    my $td = $ul->push ('td');
    is (@warnings, 1, "got warning with pushing <td> to non-tr");
    like ($warnings[0], qr/Pushing <td> to a non-tr element/);
};

# Check that there is no closing tag for the input tag, bugzilla bug
# 2015.

my $input = HTML::Make->new ('input');
my $inputtext = $input->text ();
unlike ($inputtext, qr!</input>!, "No closing tag for <input>");

my $el = HTML::Make->new ('ul');
my $li = $el->push ('li', text => 'item');
$li->add_comment ("Too much monkey business!");
my $text = $el->text ();
ok (index ($text, '<li>item<!-- Too much monkey business! --></li>') != -1,
    "Comment added OK");

TODO: {
    local $TODO = 'not yet';
};

done_testing ();

# Local variables:
# mode: perl
# End:
