use strict;
use warnings;
use Test::More tests => 6;

use HTML::Template::Parser;

test_to_list(q!<tmpl_var expr='${foo}'>!, [
    [ 'var', [ 1, 1 ], ['expr', ['variable', 'foo']], undef, undef],
]);

test_to_list('this is string', [
    [ 'string', [ 1, 1 ], 'this is string' ]
]);
test_to_list('<html><head><title>this is html</title></head><body><a href="http://mixi.jp/">mixi</a></body></html>', [
    [ 'string', [ 1, 1 ], '<html><head><title>this is html</title></head><body><a href="http://mixi.jp/">mixi</a></body></html>' ]
]);
test_to_list(q{<html><head><title><TMPL_VAR EXPR="html(title)"></title><head><body><a href="<TMPL_VAR EXPR=html('http://mixi.jp')>">mixi</a></body></html>}, [
    [ 'string', [ 1, 1 ], '<html><head><title>' ],
    [ 'var', [ 1, 20 ],
      [ 'expr',
        [ 'function',
          [ 'name', 'html' ],
          [ 'variable', 'title' ]
      ]
    ],
      undef,
      undef
  ],
    [ 'string', [ 1, 49 ], '</title><head><body><a href="' ],
    [
        'var', [ 1, 78 ],
        [ 'expr',
          [ 'function',
            [ 'name', 'html' ],
            [ 'string', 'http://mixi.jp' ]
        ]
      ],
        undef,
        undef
    ],
    [ 'string', [ 1, 116 ], '">mixi</a></body></html>' ]
]);
test_to_list('<TMPL_IF EXPR=is_foo(x)>foo<TMPL_ELSIF EXPR=is_bar(x)>bar<TMPL_ELSE>other</TMPL_IF>', [
    [ 'if', [ 1, 1 ],
      [ 'expr',
        [ 'function',
          [ 'name', 'is_foo' ],
          [ 'variable', 'x' ]
      ]
    ]
  ],
    [ 'string', [ 1, 25 ], 'foo' ],
    [ 'elsif', [ 1, 28 ],
      [ 'expr',
        [ 'function',
          [ 'name', 'is_bar' ],
          [ 'variable', 'x' ]
      ]
    ]
  ],
    [ 'string', [ 1, 55 ], 'bar' ],
    [ 'else', [ 1, 58 ] ],
    [ 'string', [ 1, 69 ], 'other' ],
    [ 'if_end', [ 1, 74 ]
  ]
]);
test_to_list('<TMPL_LOOP NAME=loop1><TMPL_LOOP EXPR=bar(loop2)><TMPL_VAR EXPR=name></TMPL_LOOP></TMPL_LOOP>', [
    [ 'loop', [ 1, 1 ],
      [ 'name', [ 'variable', 'loop1' ] ],
      undef
  ],
    [ 'loop', [ 1, 23 ],
      [ 'expr',
        [ 'function',
          [ 'name', 'bar' ],
          [ 'variable', 'loop2' ]
      ]
    ],
      undef
  ],
    [ 'var', [ 1, 50 ],
      [ 'expr', [ 'variable', 'name' ] ],
      undef,
      undef
  ],
    [ 'loop_end', [ 1, 70 ] ],
    [ 'loop_end', [ 1, 82 ] ]
]);

sub test_to_list {
    my($template_string, $expected) = @_;

    my $parser = HTML::Template::Parser->new;
    my $list = $parser->_template_string_to_list($template_string);

    is_deeply($list, $expected, "template_string is [$template_string]") if($expected);
    if (0) {                    # for debug dump
        require Data::Dumper;
        print STDERR Data::Dumper->Dump([ $list ]);
    }
}


