use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use BaseTest;

my $obj;
lives_ok(sub { $obj = BaseTest->new() }, 'create obj ok');
is($obj->_localize('test'), 'test', 'test localilze');
lives_ok(
    sub {
        $obj = BaseTest->new(localize => sub { return "hello" });
    },
    'create obj ok'
);
is($obj->_localize('test'), 'hello', 'test localilze');
lives_ok(
    sub {
        $obj = BaseTest->new(classes => {required_asterisk => 'required_asterisk'});
    },
    'create obj ok'
);
my $result = $obj->_build_element_and_attributes('div', {class => 'adiv'}, "div content", {required_mark => 1});
is($result, '<div class="adiv"><em class="required_asterisk">**</em>div content</div>');
done_testing;
