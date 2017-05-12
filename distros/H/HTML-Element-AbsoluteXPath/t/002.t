use strict;
use lib qw(./lib);
use warnings;

use Test::More tests => 9;                      # last test to print

use HTML::TreeBuilder 5.03;
use_ok('HTML::Element::AbsoluteXPath');

my $root = HTML::TreeBuilder->new;
my $html = <<END;
<html>
    <body>
        <div id="test" class="testclass"></div>
        <div class="testclass"></div>
        <div>
            <div class="innerclass"></div>
            <div></div>
        </div>
    </body>
</html>
END
$root->parse($html);
$root->eof();

my @found = $root->find_by_tag_name('div');

is $root->abs_xpath, '/html[1]', 'get abs xpath of root';
is $found[0]->abs_xpath, '/html[1]/body[1]/div[1]', 'get abs xpath';
is $found[0]->abs_xpath('id'), "/html[1]/body[1]/div[\@id='test'][1]", "get abs xpath with 'id' hint.";
is $found[0]->abs_xpath('id','class'), "/html[1]/body[1]/div[\@class='testclass' and \@id='test'][1]", "get abs xpath with 'id' and 'class' hints.";
is $found[1]->abs_xpath('id','class'), "/html[1]/body[1]/div[\@class='testclass'][2]", "get abs xpath hints for elem has just \@class.";
is $found[2]->abs_xpath('id','class'), "/html[1]/body[1]/div[3]", "get abs xpath with hints for elem has no attrs.";
is $found[2]->content->[0]->abs_xpath('id','class'), "/html[1]/body[1]/div[3]/div[\@class='innerclass'][1]", "get abs xpath overwrapped one";
is $found[2]->content->[1]->abs_xpath('id','class'), "/html[1]/body[1]/div[3]/div[2]", "get abs xpath overwrapped sibling";


$root->delete();

