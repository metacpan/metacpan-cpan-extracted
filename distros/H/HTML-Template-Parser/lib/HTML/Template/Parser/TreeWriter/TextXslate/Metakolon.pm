package HTML::Template::Parser::TreeWriter::TextXslate::Metakolon;

use strict;
use warnings;

use base qw(HTML::Template::Parser::TreeWriter);
__PACKAGE__->mk_accessors(qw( expr_writer wrap_template_target special_raw_var_map ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->expr_writer(HTML::Template::Parser::TreeWriter::TextXslate::Metakolon::Expr->new);
    $self->context([]);
    $self->expr_writer->context($self->context);
    $self->special_raw_var_map({});
    $self;
}
sub get_type {
    my($self, $node) = @_;
    my($type) = (ref($node) =~ /::([^:]+)$/);
    $type;
}

sub get_node_children {
    my($self, $node) = @_;
    @{$node->children};
}

sub is_escaped {
    my($self, $node) = @_;

    if($node->[0] eq 'function' and $node->[1]->[1] =~ /^(form|html)$/){
        return 1;
    }
    return 0;
}

sub remove_escape_function {
    my($self, $node) = @_;
    return $node->[2];
}

sub _pre_String {
    my($self, $node) = @_;

    $node->text;
}

sub _pre_Var {
    my($self, $node) = @_;

    my $is_raw = 1;
    my $src = $node->name_or_expr->[1];
    if($self->is_escaped($src)){
        $is_raw = 0;
        $src = $self->remove_escape_function($src);
    }
    if(lc($node->escape) eq 'html'){
        $is_raw = 0;
        $node->escape(0);
    }
    my $name_or_expr = $self->expr_writer->write($src);
    if(defined($node->default)){
        $name_or_expr .= " || " . $self->expr_writer->write($node->default);
    }
    if($node->escape){
        $name_or_expr .= " | " . $node->escape;
    }

    if($name_or_expr =~ /^\$(.*)/ and $self->special_raw_var_map->{$1}){
        $is_raw = 1;
    }
    if($is_raw){
        qq{[% $name_or_expr | mark_raw %]};
    }else{
        qq{[% $name_or_expr %]};
    }
}

sub _pre_Include {
    my($self, $node) = @_;

    if($node->name_or_expr->[0] eq 'name'){
        # treat as string
        $node->name_or_expr->[1][0] = 'string';
    }
    if($ENV{OLD_TEMPLATE_SUFFIX} and $ENV{NEW_TEMPLATE_SUFFIX}){ # @@@
        if($node->name_or_expr->[1][0] eq 'string'){
            $node->name_or_expr->[1][1] =~ s/\.$ENV{OLD_TEMPLATE_SUFFIX}\z/.$ENV{NEW_TEMPLATE_SUFFIX}/o;
        }
    }
    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    my $template;
    if($self->wrap_template_target){ # for on-the-fly converting.
        $template = $self->wrap_template_target . "($name_or_expr)";
    }else{
        $template = $name_or_expr;
    }
    if($self->current_context){
        my $var = '$' . $self->current_context->{loop_var_name};
        qq{[% include $template { $var } %]};
    }else{
        qq{[% include $template %]};
    }
}


sub _pre_If {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    # @@@ @@@ @@@ @@@. Text::Xslate eval [] as true. so wrap it.
    "[% if(_has_value($name_or_expr)){ %]";
}

sub _pre_ElsIf {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    "[% }elsif(_has_value($name_or_expr)){ %]";
}

sub _pre_Else {
    "[% }else{ %]";
}

sub _pre_IfEnd {
    "[% } %]";
}

sub _pre_Unless {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    "[% if(! _has_value($name_or_expr)){ %]";
}

sub _pre_UnlessEnd {
    "[% } %]";
}

sub _pre_Loop {
    my($self, $node) = @_;

    my $depth = $self->get_context_depth + 1;
    my $loop_var_name = '_item_' . $depth;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    my $ret = "[% for $name_or_expr->\$$loop_var_name { %]";

    my $context = $self->create_and_push_context();
    $context->{loop_var_name} = $loop_var_name;

    $ret;
}

sub _pre_LoopEnd {
    my($self, $node) = @_;
    $self->pop_context();
    "[% } %]";
}

package HTML::Template::Parser::TreeWriter::TextXslate::Metakolon::Expr;

use strict;
use warnings;

use base qw(HTML::Template::Parser::TreeWriter);

my %op_to_name = (
    'not' => 'not_sym',
    '!'   => 'not',
);

foreach my $bin_operator (qw(or and || && > >= < <= != == le ge eq ne lt gt + - * / % =~ !~)){
    $op_to_name{$bin_operator} = 'binary';
}

sub get_type {
    my($self, $node) = @_;

    my $type = $node->[0]; # 'op', 'variable', 'function' ....
    if($node->[0] eq 'op'){
        my $op_name = $op_to_name{$node->[1]};
        die "Unknown op_name[$node->[1]]\n" unless $op_name;
        $type .= '_' . $op_name;
    }
    $type;
}

sub get_node_children {
    my($self, $node) = @_;
    die "internal error\n"; # use custom map function.
}

################################################################
# bin_op
sub _main_op_binary {
    my($self, $node) = @_;

    my %op_translate_table = (
        'eq' => '==',
        'ne' => '!=',
    );
    my $op = $op_translate_table{$node->[1]} || $node->[1];

    '(' . $self->write($node->[2]) . ' ' . $op . ' ' . $self->write($node->[3]) . ')';
}

################################################################
# op_not_sym
sub _main_op_not_sym {
    my($self, $node) = @_;

    '(' . 'not ' . $self->write($node->[2]) . ')';
}

################################################################
# op_not
sub _main_op_not {
    my($self, $node) = @_;

    '(' . '!' . $self->write($node->[2]) . ')';
}

################################################################
# function
sub _pre_function {
    my($self, $node) = @_;
    my $name = $node->[1]->[1];

    if($self->_is_static_function($name)){
        $name;
    }else{
        '$'.$name;
    }
}

sub _map_function {
    my($self, $node) = @_;

    my @chilren_out;
    for(my $i = 2;$i < @$node;$i ++){    # 0:'function', 1:['name', 'function_name'], 2:param1, 3:param2, ....
        my $child_node = $node->[$i];
        push(@chilren_out, $self->write($child_node));
    }
    @chilren_out;
}

sub _join_function {
    my($self, $node, $chilren_out) = @_;

    '(' . join(',', @$chilren_out) . ')';
}

sub _is_static_function { # @@@
    my($self, $name) = @_;

    return 1 if($name eq 'not');
    0;
}

################################################################
# string
sub _main_string {
    my($self, $node) = @_;

    qq{'$node->[1]'};
}

################################################################
# variable
sub _main_variable {
    my($self, $node) = @_;

    # @@@ TODO
    # need to suport path-like-variable. ex) ../foo /foo
    if($self->current_context){
        if($node->[1] =~ /^__counter__$/){
            # You can get the iterator index in "for" statements as "$~ITERATOR_VAR":
            sprintf('$~%s.count', $self->current_context->{loop_var_name});
        }elsif($node->[1] =~ /^__first__$/){
            sprintf('($~%s.count == 1)', $self->current_context->{loop_var_name});
        }elsif($node->[1] =~ /^__last__$/){
            sprintf('($~%s.count == $~%s.size)',
                    $self->current_context->{loop_var_name},
                    $self->current_context->{loop_var_name});
        }elsif($node->[1] =~ /^__inner__$/){
            sprintf('($~%s.count != 1 && $~%s.count == $~%s.size)',
                    $self->current_context->{loop_var_name},
                    $self->current_context->{loop_var_name},
                    $self->current_context->{loop_var_name});
        }elsif($node->[1] =~ /^__odd__$/){
            sprintf('($~%s.count %% 2)', $self->current_context->{loop_var_name});
        }else{
            my @loop_var_list;
            foreach my $context (reverse @{ $self->context }){
                push(@loop_var_list, $context->{loop_var_name});
            }
            sprintf(q!_choise_var('%s', $%s, %s)!,
                    $node->[1],
                    $node->[1],
                    join(',', (map { '$' . $_ } @loop_var_list)));
        }
    }else{
        '$' . $node->[1];
    }
}

################################################################
# number
sub _main_number {
    my($self, $node) = @_;

    $node->[1];
}

################################################################
# default
sub _main_default {
    my($self, $node) = @_;

    qq{"$node->[1]"};
}

################################################################
# regexp
sub _main_regexp {
    my($self, $node) = @_;

    $node->[1];
}

1;
