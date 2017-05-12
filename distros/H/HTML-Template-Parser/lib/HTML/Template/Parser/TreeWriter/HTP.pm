package HTML::Template::Parser::TreeWriter::HTP;

use strict;
use warnings;

use base qw(HTML::Template::Parser::TreeWriter);
__PACKAGE__->mk_accessors(qw( expr_writer ));

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->expr_writer(HTML::Template::Parser::TreeWriter::HTP::Expr->new);
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

sub _pre_String {
    my($self, $node) = @_;

    $node->text;
}

sub _pre_Var {
    my($self, $node) = @_;

    my $label = uc($node->name_or_expr->[0]);
    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    my $escape = defined($node->escape) ? (' ESCAPE='.$node->escape) : '';
    my $default = defined($node->default) ? (' DEFAULT='.$self->expr_writer->write($node->default)) : '';
    qq{<TMPL_VAR $label="$name_or_expr"$escape$default>};
}

sub _pre_Include {
    my($self, $node) = @_;

    my $label = uc($node->name_or_expr->[0]);
    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    qq{<TMPL_INCLUDE $label="$name_or_expr">};
}


sub _pre_If {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    sprintf(q{<TMPL_IF %s="%s">},
            uc($node->name_or_expr->[0]),
            $name_or_expr);
}

sub _pre_ElsIf {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    sprintf(q{<TMPL_ELSIF %s="%s">},
            uc($node->name_or_expr->[0]),
            $name_or_expr);
}

sub _pre_Else {
    q{<TMPL_ELSE>};
}

sub _pre_IfEnd {
    q{</TMPL_IF>};
}

sub _pre_Unless {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    sprintf(q{<TMPL_UNLESS %s="%s">},
            uc($node->name_or_expr->[0]), # @@@
            $name_or_expr);
}

sub _pre_UnlessEnd {
    q{</TMPL_UNLESS>};
}

sub _pre_Loop {
    my($self, $node) = @_;

    my $name_or_expr = $self->expr_writer->write($node->name_or_expr->[1]);
    sprintf(q{<TMPL_LOOP %s="%s">},
            uc($node->name_or_expr->[0]), # @@@
            $name_or_expr);
}

sub _pre_LoopEnd {
    q{</TMPL_LOOP>};
}

package HTML::Template::Parser::TreeWriter::HTP::Expr;

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
#    die "internal error\n"; # use custom map function.
    (); # @@@
}

################################################################
# bin_op
sub _main_op_binary {
    my($self, $node) = @_;

    '(' . $self->write($node->[2]) . $node->[1] . $self->write($node->[3]) . ')';
}

################################################################
# op_not_sym
sub _main_op_not_sym {
    my($self, $node) = @_;

    '(' . 'not' . $node->[2] . ')';
}

################################################################
# op_not
sub _main_op_not {
    my($self, $node) = @_;

    '(' . '!' . $node->[2] . ')';
}

################################################################
# function
sub _pre_function {
    my($self, $node) = @_;
    $node->[1]->[1];
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

    $node->[1];
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


