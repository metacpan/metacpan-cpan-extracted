# Test the documentation's claims under "push".

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
my $tr = HTML::Make->new ('tr');
my $td = HTML::Make->new ('td');
my $pt = $tr->push ($td);
is ($pt, $td, "Pass through of td element");
my $text = $tr->text ();
like ($text, qr!<tr>.*<td>.*</td>.*</tr>.*!s, "Got nested tr td");
done_testing ();
