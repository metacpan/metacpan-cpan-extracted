use strict;
use warnings;
use Test::More tests => 32;

use HTML::Template::Parser;

test_error_message('</TMPL_IF>', qr{line 1. column 1. tag doesn't match </TMPL_IF>});
test_error_message('1 2 3 4 5</TMPL_IF>', qr{line 1. column 10. tag doesn't match </TMPL_IF>});
test_error_message('</TMPL_LOOP>', qr{line 1. column 1. tag doesn't match </TMPL_LOOP>});

test_error_message('<TMPL_IF EXPR=1>1<TMPL_ELSE>2<TMPL_LOOP NAME=l>loop</TMPL_IF>', qr{line 1. column 52. tag doesn't match </TMPL_IF>});
test_error_message('<TMPL_LOOP NAME=l><TMPL_IF EXPR=1>1</TMPL_LOOP>', qr{line 1. column 36. tag doesn't match </TMPL_LOOP>});

test_error_message('<TMPL_LOOP NAME=l>', qr{line 1. column 1. missing '</TMPL_LOOP>' pared with  <TMPL_LOOP>});
test_error_message('<TMPL_IF NAME=l>', qr{line 1. column 1. missing '</TMPL_IF>' pared with  <TMPL_IF>});
test_error_message('<TMPL_UNLESS NAME=l>', qr{line 1. column 1. missing '</TMPL_UNLESS>' pared with  <TMPL_UNLESS>});


test_error_message('<TMPL_ELSE>', qr{tag doesn't match});
test_error_message('<TMPL_IF expr=1><TMPL_ELSE><TMPL_ELSE></TMPL_IF>', qr{can't accept <TMPL_ELSE>});
test_error_message('<TMPL_IF expr=1><TMPL_ELSE><TMPL_ELSIF expr=1></TMPL_IF>', qr{can't accept <TMPL_ELSIF>});

test_error_message(q{<TMPL_VAR>}, qr/line 1. column 1. something wrong/);
test_error_message(q{abc<TMPL_IF>}, qr/line 1. column 4. something wrong/);
test_error_message(q{abcde<TMPL_IF}, qr/line 1. column 6. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='a>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='ab>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME=a'>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME=ab'>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME=">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME="a>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME="ab>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME=a">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME=ab">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='a">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME='ab">}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME="'>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME="a'>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg<TMPL_IF NAME="ab'>}, qr/line 1. column 8. something wrong/);
test_error_message(q{abcdefg hijklmn<TMPL_LOOP FOO="l">}, qr/line 1. column 16. something wrong/);
test_error_message(q{<TMPL_IF NAME=1 EXPR=1>}, qr/line 1. column 1. something wrong/);


sub test_error_message {
    my($template_string, $error_message_re) = @_;

    my $parser = HTML::Template::Parser->new;
    eval {
        my $tree = $parser->parse($template_string);
    };
    like($@, $error_message_re, "template_string is [$template_string]");
}

