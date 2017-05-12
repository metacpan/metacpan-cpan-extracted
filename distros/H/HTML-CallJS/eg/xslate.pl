use strict;
use warnings;
use utf8;
use Text::Xslate;
use HTML::CallJS;

my $tx = Text::Xslate->new(
    html_builder_module => [
        'HTML::CallJS' => [qw(call_js)]
    ]
);
print $tx->render_string(
    '<: call_js("foo", {x=>$x}) :>', { x => 5963 },
), "\n";

# => <script class="call_js" type="text/javascript">foo({"x":5963})</script>

