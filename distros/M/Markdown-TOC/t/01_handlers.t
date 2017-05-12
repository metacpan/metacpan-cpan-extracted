use Test::More;
use Markdown::TOC;
use strict;

my $md = q{
# header1

some text

## header 2

another text

header
----

text

};

my $counter = 0;
my $handler = sub {

    my ($t, $l) = @_;

    if ($counter == 0) {
        is $t, 'header1', 'First header got';
        is $l, 1, 'First level got';
    }
    elsif ($counter == 1) {
        is $t, 'header 2', 'Second header got';
        is $l, 2, 'Second level got';
    }
    elsif ($counter == 3 ) {
        is $t, 'header', 'Third header got';
        is $l, 2, 'Third level got';
    }
    $counter++;
};

my $toc = Markdown::TOC->new(raw_handler => $handler);
my $result = $toc->process($md);

is $counter, 3, 'ALl the headers are checked';

my $handler_called = 0;
my $partial_handler = sub {
    my %param = @_;
    is $param{text}, 'header', 'Text checked';
    is $param{anchor}, 'anchor', 'Anchor checked';
    is $param{order_formatted}, 'order', 'Order checked';
    is $param{level}, 2, 'Level checked';
    $handler_called = 1;
};

$toc = Markdown::TOC->new(
    handler => $partial_handler,
    anchor_handler => sub { return 'anchor' },
    order_handler => sub { return 'order'}
);

$toc->process(q{## header});

ok $handler_called, 'Handler was called';

my $listener_called = 0;
my $listener = sub {
    my ($t, $l) = @_;
    is $t, 'header', 'Header found';
    is $l, 1, 'Level got';
    $listener_called = 1;
};

$toc = Markdown::TOC->new(listener => $listener);
$toc->process(q{# header});
ok $listener_called, 'Listener was called';

$toc = Markdown::TOC->new(delimeter => '<br />');
my $html = $toc->process(q{
# header1
## header2
});

is $html, '<h1>header1</h1><br /><h2>header2</h2>', 'Used delimeter';

done_testing;


