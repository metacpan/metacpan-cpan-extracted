use strict;
use warnings;
use Test::More tests => 5;

use HTML::Template::Parser;

use YAML;

test_to_tree('this is string', <<'END;');
--- &1 !!perl/hash:HTML::Template::Parser::Node::Root
type: root
can_have_child: 1
children:
  - !!perl/hash:HTML::Template::Parser::Node::String
    type: string
    parent: *1
    line: 1
    column: 1
    text: this is string
    children: []
END;
test_to_tree('<html><head><title>this is html</title></head><body><a href="http://mixi.jp/">mixi</a></body></html>', <<'END;');
--- &1 !!perl/hash:HTML::Template::Parser::Node::Root
type: root
can_have_child: 1
children:
  - !!perl/hash:HTML::Template::Parser::Node::String
    type: string
    line: 1
    column: 1
    parent: *1
    text: '<html><head><title>this is html</title></head><body><a href="http://mixi.jp/">mixi</a></body></html>'
    children: []
END;
test_to_tree(q{<html><head><title><TMPL_VAR EXPR="html(title)"></title><head><body><a href="<TMPL_VAR EXPR=html('http://mixi.jp')>">mixi</a></body></html>},  <<'END;');
--- &1 !!perl/hash:HTML::Template::Parser::Node::Root
type: root
can_have_child: 1
children:
  - !!perl/hash:HTML::Template::Parser::Node::String
    type: string
    line: 1
    column: 1
    parent: *1
    text: '<html><head><title>'
    children: []
  - !!perl/hash:HTML::Template::Parser::Node::Var
    type: var
    line: 1
    column: 20
    parent: *1
    default: ~
    escape: ~
    name_or_expr:
      - expr
      -
        - function
        -
          - name
          - html
        -
          - variable
          - title
    children: []
  - !!perl/hash:HTML::Template::Parser::Node::String
    type: string
    line: 1
    column: 49
    parent: *1
    text: </title><head><body><a href="
    children: []
  - !!perl/hash:HTML::Template::Parser::Node::Var
    parent: *1
    type: var
    line: 1
    column: 78
    default: ~
    escape: ~
    name_or_expr:
      - expr
      -
        - function
        -
          - name
          - html
        -
          - string
          - http://mixi.jp
    children: []
  - !!perl/hash:HTML::Template::Parser::Node::String
    type: string
    parent: *1
    line: 1
    column: 116
    text: '">mixi</a></body></html>'
    children: []
END;
test_to_tree('<TMPL_IF EXPR=is_foo(x)>foo<TMPL_ELSIF EXPR=is_bar(x)>bar<TMPL_ELSE>other</TMPL_IF>',  <<'END;');
--- &1 !!perl/hash:HTML::Template::Parser::Node::Root
type: root
can_have_child: 1
children:
  - &2 !!perl/hash:HTML::Template::Parser::Node::Group
    type: group
    sub_type: if
    line: 1
    column: 1
    parent: *1
    can_have_child: 1
    is_group_tag: 1
    children:
      - &3 !!perl/hash:HTML::Template::Parser::Node::If
        type: if
        line: 1
        column: 1
        parent: *2
        else_seen: 1
        can_have_child: 1
        children:
          - !!perl/hash:HTML::Template::Parser::Node::String
            type: string
            parent: *3
            line: 1
            column: 25
            text: foo
            children: []
        name_or_expr:
          - expr
          -
            - function
            -
              - name
              - is_foo
            -
              - variable
              - x
      - &4 !!perl/hash:HTML::Template::Parser::Node::ElsIf
        type: elsif
        parent: *2
        line: 1
        column: 28
        can_have_child: 1
        children:
          - !!perl/hash:HTML::Template::Parser::Node::String
            type: string
            line: 1
            column: 55
            parent: *4
            text: bar
            children: []
        expected_begin_tag: !!perl/regexp (?-xism:if|unless)
        is_end_tag: 1
        name_or_expr:
          - expr
          -
            - function
            -
              - name
              - is_bar
            -
              - variable
              - x
      - &5 !!perl/hash:HTML::Template::Parser::Node::Else
        type: else
        line: 1
        column: 58
        parent: *2
        expected_begin_tag: !!perl/regexp (?-xism:if|unless)
        is_end_tag: 1
        can_have_child: 1
        children:
          - !!perl/hash:HTML::Template::Parser::Node::String
            type: string
            line: 1
            column: 69
            parent: *5
            text: other
            children: []
      - !!perl/hash:HTML::Template::Parser::Node::IfEnd
        type: if_end
        line: 1
        column: 74
        parent: *2
        expected_begin_tag: if
        is_end_tag: 1
        children: []
END;
test_to_tree('<TMPL_LOOP NAME=loop1><TMPL_LOOP EXPR=bar(loop2)><TMPL_VAR EXPR=name></TMPL_LOOP></TMPL_LOOP>',  <<'END;');
--- &1 !!perl/hash:HTML::Template::Parser::Node::Root
type: root
can_have_child: 1
children:
  - &2 !!perl/hash:HTML::Template::Parser::Node::Group
    type: group
    sub_type: loop
    line: 1
    column: 1
    parent: *1
    is_group_tag: 1
    can_have_child: 1
    children:
      - &3 !!perl/hash:HTML::Template::Parser::Node::Loop
        type: loop
        line: 1
        column: 1
        parent: *2
        can_have_child: 1
        name_or_expr:
          - name
          -
            - variable
            - loop1
        children:
          - &4 !!perl/hash:HTML::Template::Parser::Node::Group
            type: group
            sub_type: loop
            line: 1
            column: 23
            parent: *3
            is_group_tag: 1
            can_have_child: 1
            children:
              - &5 !!perl/hash:HTML::Template::Parser::Node::Loop
                type: loop
                line: 1
                column: 23
                parent: *4
                can_have_child: 1
                children:
                  - !!perl/hash:HTML::Template::Parser::Node::Var
                    type: var
                    line: 1
                    column: 50
                    parent: *5
                    default: ~
                    escape: ~
                    name_or_expr:
                      - expr
                      -
                        - variable
                        - name
                    children: []
                name_or_expr:
                  - expr
                  -
                    - function
                    -
                      - name
                      - bar
                    -
                      - variable
                      - loop2
              - !!perl/hash:HTML::Template::Parser::Node::LoopEnd
                type: loop_end
                line: 1
                column: 70
                parent: *4
                expected_begin_tag: loop
                is_end_tag: 1
                children: []
      - !!perl/hash:HTML::Template::Parser::Node::LoopEnd
        type: loop_end
        line: 1
        column: 82
        parent: *2
        expected_begin_tag: loop
        is_end_tag: 1
        children: []
END;

sub test_to_tree {
    my($template_string, $expected) = @_;

    my $parser = HTML::Template::Parser->new;
    my $tree = $parser->parse($template_string);

    is_deeply($tree, YAML::Load($expected), "template_string is [$template_string]");
    if (0) {                    # for debug dump
        print STDERR YAML::Dump($tree);
    }
}


