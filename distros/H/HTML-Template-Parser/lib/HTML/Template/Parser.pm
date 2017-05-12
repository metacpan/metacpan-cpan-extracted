package HTML::Template::Parser;

use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.1011';

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw());

use Parse::RecDescent;
use English;

use HTML::Template::Parser::NodeBuilder;

use vars '$errortext';
use vars '$errorprefix';

sub parse {
    my($self, $template_string) = @_;

    $self->_list_to_tree($self->_template_string_to_list($template_string));
}

sub _template_string_to_list {
    my($self, $template_string) = @_;

    my @list;
    my($line, $column) = (1, 1); # 1 orign
    while($template_string =~ m!</?TMPL_!i){
        my $pre = $PREMATCH;
        my $tag = $MATCH . $POSTMATCH;
        my $tmp;

        # keep as plain text
        push(@list, ['string', [$line, $column], $pre]) if(length($pre));

        # calc line & column
        $line += (($tmp = $pre) =~ s/\n//g);
        $column = 1 if($pre =~ /\n/);
        ($tmp = $pre) =~ s/.*\n//s;
        $column += length($tmp);
        my $xxx = ( split(/\n/, $tag) )[0];

        # parse TMPL_* tag
        my $tag_temp = $tag;
        my $parsed_tag;
        # capture error message.
        my $error_string = '';
        eval {
            local (*STDERR, *Parse::RecDescent::ERROR);
            if(Parse::RecDescent->can('_write_ERROR')){ # @@@ @@@
                open(STDERR, '>:scalar', \$error_string);
            }else{
                open(Parse::RecDescent::ERROR, '>', \my $error_string) or die "open:[$!]\n";
            }
            $parsed_tag = $self->_get_parser_instance->tag(\$tag_temp);
        };
        if($@){
            die "line $line. column $column. something wrong. $@\n";
        }
        if($tag eq $tag_temp){
            my $first_line_of_tag = ( split(/\n/, $tag) )[0];
            my $first_line_of_error_string = ( split(/\n/, $error_string) )[0];
            die "line $line. column $column. something wrong. Couldn't parse tag well\n[$first_line_of_tag][$first_line_of_error_string]\n";
        }
        splice(@$parsed_tag, 1, 0, [$line, $column]);
        push(@list, $parsed_tag);

        # calc line & column
        my $num_parsed = length($tag)-length($tag_temp);
        my $parsed_string = substr($tag, 0, $num_parsed);
        $line += (($tmp = $parsed_string) =~ s/\n//g);
        $column = 1 if($parsed_string =~ /\n/);
        ($tmp = $parsed_string) =~ s/.*\n//s;
        $column += length($tmp);

        $template_string = $tag_temp;
    }
    push(@list, ['string', [$line, $column], $template_string]) if(length($template_string));
    \@list;
}

sub _list_to_tree {
    my($self, $raw_list) = @_;

    # insert Node::Group before Node::(If|Loop|Unless) and insert Node::GrooupEnd after Node::(IfEnd|LoopEnd|UnlessEnd) to make easier to convert.
    my @node_list;
    foreach my $raw_item (@$raw_list){
        my $node = HTML::Template::Parser::NodeBuilder::createNode($raw_item);

        if($node->type =~ /\A(if|loop|unless)\Z/){
            push(@node_list, HTML::Template::Parser::Node::Group->new({sub_type => $1, line => $node->line, column => $node->column}));
        }
        push(@node_list, $node);
        if($node->type =~ /\A(if|loop|unless)_end\Z/){
            push(@node_list, HTML::Template::Parser::Node::GroupEnd->new({sub_type => $1, line => $node->line, column => $node->column}));
        }
    }

    my $root = HTML::Template::Parser::Node::Root->new();
    $root->add_chidren(\@node_list);
    $root;
}

my $_instance;

sub _get_parser_instance {
    return $_instance if $_instance;
    $::RD_ERRORS=1;
    $::RD_WARN=1;
    $::RD_HINT=1;
#    $::RD_TRACE=1; # @@@
    return $_instance = Parse::RecDescent->new(<<'END;');
{
  use strict;
  use warnings;

  use HTML::Template::Parser::ExprParser;

  sub _parse_name_or_expr {
      my $name_or_expr = shift;

      if($name_or_expr->[0] eq 'name'){
          my $name = $name_or_expr->[1];
          if($name =~ /^\$/){
            die "Can't use \${name} at NAME. [$name]\n";
          }
          $name =~ s/\$?{([^}]+)}/$1/;
          return [ 'name', [ 'variable', $name ] ];
      }

      my $expr = $name_or_expr->[1];
      my $expr_temp = $expr;
      my $parsed_expr = HTML::Template::Parser::ExprParser->new->parse(\$expr_temp);
      if($expr_temp !~ /\A\s*\Z/){
          die "something wrong. Couldn't parse expr well\n[$expr]=>[$expr_temp]\n";
      }
      [ 'expr', $parsed_expr ];
  }

  sub __dump_item__ {
    require Data::Dumper;
    my($thisrule, $a_item, $h_item) = @_;
    print STDERR "Rule: $thisrule\n";
    print STDERR Data::Dumper->Dump([{
       '@item' => $a_item,
       '%item' => $h_item,
    }]);
  }
}

tag:  htp_tag | <error: error near "$text">

htp_tag: htp_var
htp_tag: htp_include
htp_tag: htp_if
htp_tag: htp_else
htp_tag: htp_elsif
htp_tag: htp_unless
htp_tag: htp_loop

htp_var: '<' /TMPL_VAR/i escape_1(?) name_or_expr escape_2(?) default(?) m!/?>! {
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
  my $escape = $item{'escape_1(?)'}->[0] || $item{'escape_2(?)'}->[0];
  my $default = $item{'default(?)'}->[0];

  [ 'var', $name_or_expr, $escape, $default ];
}

htp_include: '<' /TMPL_INCLUDE/i name_or_expr m!/?>! {
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
  [ 'include',  $name_or_expr, ];
}
htp_include: '<' /TMPL_INCLUDE/i name_or_expr_bare m!/?>! {
  my $name = [ 'name', $item{name_or_expr_bare} ];
  [ 'include',  ['name', $name, ]];
}

htp_if: '<' /TMPL_IF/i name_or_expr '>' {
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
 
  [ 'if',  $name_or_expr, ];
}
htp_if: '<' /TMPL_IF/i name_or_expr_bare '>' {
  my $name = $item{name_or_expr_bare};

  [ 'if',  [ 'name', [ 'variable', $name, ] ] ];
}
htp_if: '</' /TMPL_IF/i '>' {
  [ 'if_end' ];
}

htp_else: '<' /TMPL_ELSE/i '>' {
  [ 'else' ];
}

htp_elsif: '<' /TMPL_ELSIF/i name_or_expr '>' {
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
  [ 'elsif',  $name_or_expr, ];
}
htp_elsif: '<' /TMPL_ELSIF/i name_or_expr_bare '>' {
  my $name = $item{name_or_expr_bare};
  [ 'elsif',  $name, ];
}

htp_unless: '<' /TMPL_UNLESS/i name_or_expr '>' {
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
  [ 'unless',  $name_or_expr, ];
}
htp_unless: '<' /TMPL_UNLESS/i name_or_expr_bare '>' {
  my $name = $item{name_or_expr_bare};
  [ 'unless',  $name, ];
}
htp_unless: '</' /TMPL_UNLESS/i '>' {
  [ 'unless_end' ];
}

htp_loop: '<' /TMPL_LOOP/i name_or_expr default(?) '>' {
#  __dump_item__($thisrule, \@item, \%item);
  my $name_or_expr = _parse_name_or_expr($item{name_or_expr});
  my $default = $item{'default(?)'}->[0];
  [ 'loop',  $name_or_expr, $default ];
}
htp_loop: '</' /TMPL_LOOP/i '>' {
  [ 'loop_end' ];
}

name_or_expr: /NAME|EXPR/i '=' name_or_expr_bare {
  my $type = lc($item[1]);

  [ $type, $item{name_or_expr_bare} ];
}

name_or_expr_bare: /'([^']*)'/ 		{  $1; }
name_or_expr_bare: /"([^"]*)"/		{  $1; }

name_or_expr_bare: /[^>\s]+/ <reject: $item[1] =~ /^(NAME|EXPR)=/i or $item[1] =~ /^['"]|['"]$/> { $item[1]; }


escape_1: escape
escape_2: escape

escape: /ESCAPE/i '=' /['"]?(0|1|URL|NONE|HTML|JS)['"]?/i {
  lc($1);
}

default: /DEFAULT/i '=' name_or_expr_bare { [ 'default', $item[3] ]; }

END;
}

1;

1;
__END__

=head1 NAME

HTML::Template::Parser - Parser for HTML::Template syntax template file & writer.

=head1 VERSION

This document describes HTML::Template::Parser version 0.1.

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => qw(recursion);

    use HTML::Template::Parser;
    use HTML::Template::Parser::TreeWriter::TextXslate::Metakolon;

    my $parser = HTML::Template::Parser->new;
    my $tree = $parser->parse("<TMPL_VAR EXPR=html(name)>");

    my $writer = HTML::Template::Parser::TreeWriter::TextXslate::Metakolon->new;
    print $writer->write($tree);

=head1 DESCRIPTION

HTML::Template::Parser is parser module for tempalte file that is written in HTML::Template.
It parse template file to tree object.
It can write tree as TextXslate::Metakolon format.

=head1 INTERFACE

=head2 B<< HTML::Template::Parser->new() >>

Creates a new tempalte parser.

=head2 B<< $parser->parse($string) >>

Parse $string to tree.

=head1 ACKNOWLEDGEMENT

Thanks to __gfx__ for the bug reports and patches.

=head1 AUTHOR

Shigeki Morimoto E<lt>Shigeki(at)Morimo.toE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011, Shigeki, Morimoto. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
