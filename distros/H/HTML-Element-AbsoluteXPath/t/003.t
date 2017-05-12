use strict;
use lib qw(./lib);
use warnings;

use Test::More tests => 7;                      # last test to print

use HTML::TreeBuilder 5.03;
use_ok('HTML::Element::AbsoluteXPath');

my $root = HTML::TreeBuilder->new;
my $html = <<END;
<html>
    <body>
        <div id="test1" class="testclass "></div>
        <div id="test2" class=" testclass"></div>
        <div id="test3" class=" "></div>
        <div id="test4" class=" testclass  test2  "></div>
        <div id="test1" class="testclass "></div>
    </body>
</html>
END
$root->parse($html);
$root->eof();

my @found = $root->find_by_tag_name('div');

#map{ print $_."\t".$_->address."\t".$_->abs_xpath('class')."\n";}@found;  
is $found[0]->abs_xpath('class'), "/html[1]/body[1]/div[\@class='testclass '][1]", "element 1";

is $found[0]->abs_xpath('class'), "/html[1]/body[1]/div[\@class='testclass '][1]", "element 1";
is $found[1]->abs_xpath('class'), "/html[1]/body[1]/div[\@class=' testclass'][1]", "element 2";
is $found[2]->abs_xpath('class'), "/html[1]/body[1]/div[\@class=' '][1]", "element 3";
is $found[3]->abs_xpath('class'), "/html[1]/body[1]/div[\@class=' testclass  test2  '][1]", "element 4";

is $found[4]->abs_xpath(), "/html[1]/body[1]/div[5]", "element 5";


$root->delete();

