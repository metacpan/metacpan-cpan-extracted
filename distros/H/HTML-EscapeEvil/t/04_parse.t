
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-EscapeEvil.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use strict;
use warnings;

use HTML::EscapeEvil;

my($escapeevil,%option,$html,$htmlfile,$writehtmlfile);
%option = (
			allow_comment => 1,
			allow_declaration => 1,
			allow_process => 1,
			allow_style => 1,
			allow_script => 1,
			allow_entity_reference => 1,
			allow_tags => [qw(html head title body a)],
		);

$html = "<html><head><title>test</title></head><body>hello<a href=\"hello.html\">a</a></body></html>";
$htmlfile = "t/escapeevil.html";
$writehtmlfile = "write.html";

$escapeevil = HTML::EscapeEvil->new(%option);

# ==================================================== #
# 1 - 4
# Filter Check
# ==================================================== #
$escapeevil->parse($html);
ok($escapeevil->filtered_html);

$escapeevil->parse_file($htmlfile);
$escapeevil->filtered_file($writehtmlfile);
ok(-e $writehtmlfile);
unlink $writehtmlfile;

$escapeevil->deny_tags(qw(a));
isnt(length $escapeevil->filtered($html),length $html);
open FILE,"< $htmlfile" or die $!;
$escapeevil->filtered(*FILE,$writehtmlfile);
ok(-e $writehtmlfile);
unlink $writehtmlfile;

$escapeevil->clear;
