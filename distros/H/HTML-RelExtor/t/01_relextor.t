use strict;
use Test::Base;

use HTML::RelExtor;
plan 'no_plan';

filters { expected => 'yaml' };

run {
    my $block = shift;
    my $p = HTML::RelExtor->new(base => $block->base || undef);
    $p->parse($block->input);

    my @links = $p->links;
    my @data  = map {
        +{ tag => $_->tag, href => $_->href, rel => [ $_->rel ], text => $_->text }
    } @links;

    is_deeply \@data, $block->expected;
}

__END__

=== nofollow
--- input
<a href="http://www.example.com/test1" rel="nofollow">Test1</a>
<a href="http://www.example.com/test2">Test2</a>
<a href="http://www.example.com/test3" rel="nofollow tag">Test3</a>

--- expected
- tag: a
  href: http://www.example.com/test1
  rel: [ nofollow ]
  text: Test1
- tag: a
  href: http://www.example.com/test3
  rel: [ nofollow, tag ]
  text: Test3

=== link
--- base: http://foobar.example.com/
--- input
<link href="http://www.example.com/test1" rel="stylesheet" type="text/stylesheet" />
<link href="/index.css" rel="stylesheet" type="text/stylesheet" />

--- expected
- tag: link
  href: http://www.example.com/test1
  rel: [ stylesheet ]
  text: ~
- tag: link
  href: http://foobar.example.com/index.css
  rel: [ stylesheet ]
  text: ~
