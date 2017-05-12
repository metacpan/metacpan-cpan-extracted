# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-TagTree.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('HTML::TagTree') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
my $html = HTML::TagTree->new('html');
ok (defined $html, 'object created');
my $html_output = $html->get_html_text(0,1);
ok ($html_output eq '<html></html>', 'get_html_text');
my $head = $html->head;
my $body = $html->body;
ok (defined $body, 'child object created');
$html_output = $html->get_html_text(0,1);
$html->release;

my $textarea = HTML::TagTree->new('textarea','','name=test_textarea placeholder="Enter some text"');
my $result = $textarea->get_html_text(0,1);
ok ($result eq '<textarea name="test_textarea" placeholder="Enter some text" ></textarea>',
    'textarea is good. No auto newline before end tag');
done_testing();

