package KwikiTextileTest;
use Test::Base -Base;

use Kwiki::Textile;

package KwikiTextileTest::Filter;
use Test::Base::Filter -base;

sub textile_filter {
    return Kwiki::Textile->text_to_html(shift);
}
