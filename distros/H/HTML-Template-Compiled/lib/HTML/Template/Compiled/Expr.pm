package HTML::Template::Compiled::Expr;
use strict;
use warnings;
use Carp qw(croak carp);
#use HTML::Template::Compiled::Expression qw(:expressions);
use HTML::Template::Compiled;
use Parse::RecDescent;
our $VERSION = '1.003'; # VERSION

my $re = qr# (?:
    \b(?:eq | ne | ge | le | gt | lt )\b
    |
    (?: == | != | <= | >= | > | <)
    |
    (?: [0-9]+ )
    ) #x;

my $GRAMMAR = <<'END';
expression : paren /^$/  { $return = $item[1] } 

paren         : '(' binary_op ')'     { $item[2] }
              | '(' subexpression ')' { $item[2] }
            | subexpression         { $item[1] }
            | '(' paren ')'         { $item[2] }

subexpression : function_call
            | method_call
            | var_deref
            | var
            | literal
            | <error>

binary_op     : paren (op paren { [ $item[2], $item[1] ] })(s)
            { $return = [ 'SUB_EXPR', $item[1], map { @$_ } @{$item[2]} ] }

op            : />=?|<=?|!=|==/      { [ 'BIN_OP',  $item[1] ] }
            | /le|ge|eq|ne|lt|gt/  { [ 'BIN_OP',  $item[1] ] }
            | /\|\||or|&&|and/     { [ 'BIN_OP',  $item[1] ] }
            | /[-+*\/%.]/           { [ 'BIN_OP',  $item[1] ] }

method_call : var '(' args ')' { [ 'METHOD_CALL', $item[1], $item[3] ] }

function_call : function_name '(' args ')'  
            { [ 'FUNCTION_CALL', $item[1], $item[3] ] }
            | function_name ...'(' paren
            { [ 'FUNCTION_CALL', $item[1], [ $item[3] ] ] }
            | function_name '(' ')'
            { [ 'FUNCTION_CALL', $item[1] ] }

function_name : /[A-Za-z_][A-Za-z0-9_]*/

args          : <leftop: paren ',' paren>

var           : /[.\/A-Za-z_][.\/A-Za-z0-9_]*/ { [ 'VAR', $item[1] ] }
              | /\$[.\/A-Za-z_][.\/A-Za-z0-9_]*/ { [ 'VAR', $item[1] ] }

var_deref     : var deref(s)  { [ 'VAR_DEREF', $item[1], $item[2] ] }
              | var deref(s)  { [ 'VAR_DEREF', $item[1], $item[2] ] }

deref         : deref_hash | deref_array

deref_hash      : '{' hash_key '}' { [ 'DEREF_HASH', $item[2] ] }

deref_array : '[' array_index ']' { [ 'DEREF_ARRAY', $item[2] ] }

hash_key      : literal | paren | var

array_index   : /-?\d+/ | paren | var

literal       : /-?\d*\.\d+/             { [ 'LITERAL', $item[1] ] }
            | /-?\d+/                  { [ 'LITERAL', $item[1] ] }
            | <perl_quotelike>         { [ 'LITERAL_STRING', $item[1][1], $item[1][2] ] }

END
my %FUNC = (
    'sprintf' => sub { sprintf( shift, @_ ); },
    'substr'  => sub {
        return substr( $_[0], $_[1] ) if @_ == 2;
        return substr( $_[0], $_[1], $_[2] );
    },
    'lc'      => sub { lc( $_[0] ); },
    'lcfirst' => sub { lcfirst( $_[0] ); },
    'uc'      => sub { uc( $_[0] ); },
    'ucfirst' => sub { ucfirst( $_[0] ); },
    'length'  => sub { length( $_[0] ); },
    'defined' => sub { defined( $_[0] ); },
    'abs'     => sub { abs( $_[0] ); },
    'atan2'   => sub { atan2( $_[0], $_[1] ); },
    'cos'     => sub { cos( $_[0] ); },
    'exp'     => sub { exp( $_[0] ); },
    'hex'     => sub { hex( $_[0] ); },
    'int'     => sub { int( $_[0] ); },
    'log'     => sub { log( $_[0] ); },
    'oct'     => sub { oct( $_[0] ); },
    'rand'    => sub { rand( $_[0] ); },
    'sin'     => sub { sin( $_[0] ); },
    'sqrt'    => sub { sqrt( $_[0] ); },
    'srand'   => sub { srand( $_[0] ); },
);
# under construction
my $DEFAULT_PARSER;
sub parse_expr {
    my ($class, $compiler, $htc, %args) = @_;
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\%args], ['args']);
    my $string = $args{expr};
    my $PARSER = $DEFAULT_PARSER ||= Parse::RecDescent->new($GRAMMAR);
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$string], ['string']);
    my $tree = $PARSER->expression("( $string )");
#    warn Data::Dumper->Dump([\$tree], ['tree']);
    my $expr = $class->sub_expression($tree, $compiler, $htc, %args);
#    warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$expr], ['expr']);
    return $expr;

}

sub bin_op {
    my ($class, $op, $args, $compiler, $htc, %args) = @_;
    unless (@$args) {
        return '';
    }
    my $right = pop @$args;
    my $right_expr = $class->sub_expression($right, $compiler, $htc, %args);
    my $left_expr = '';
    if (@$args > 1) {
        my $new_op = pop @$args;
        my $sub = $class->bin_op($new_op->[1], $args, $compiler, $htc, %args);
        $left_expr = $sub;
    }
    else {
        $left_expr = $class->sub_expression($args->[0], $compiler, $htc, %args);
    }
    my $expr = ' ( ' . $left_expr
        . ' ' . $op . ' '
        . $right_expr
        . ' ) ';
#    warn __PACKAGE__.':'.__LINE__.": !!! $expr\n";
    return $expr;
}

sub sub_expression {
    my ($class, $tree, $compiler, $htc, %args) = @_;
    my ($type, @args) = @$tree;
    #warn __PACKAGE__.':'.__LINE__.": $type\n";
    #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$tree], ['tree']);
    if ($type eq 'SUB_EXPR') {
        my $op = pop @args;
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$op], ['op']);
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@args], ['args']);
        my $expr = '';
        if ($op->[0] eq 'BIN_OP') {
            $expr = $class->bin_op($op->[1], [@args], $compiler, $htc, %args);
        }
        #warn __PACKAGE__.':'.__LINE__.": $expr\n";
        return $expr;
    }
    elsif ($type eq 'VAR') {
        my $expr = $compiler->parse_var($htc,
            %args,
            var => $args[0],
        );
        #warn __PACKAGE__.':'.__LINE__.": VAR $expr\n";
        return $expr;
    }
    elsif ($type eq 'LITERAL') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@args], ['args']);
        my $expr = $args[0];
        return $expr;
    }
    elsif ($type eq 'LITERAL_STRING') {
        my $expr = $args[0] . $args[1] . $args[0];
        return $expr;
    }
    elsif ($type eq 'METHOD_CALL') {
        #warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\@args], ['args']);
        my ($var, $params) = @args[0,1];
        my $method_args = '';
        for my $i (0 .. $#$params) {
            $method_args .= $class->sub_expression($params->[$i], $compiler, $htc, %args) . ' , ';
        }
        my $expr = $compiler->parse_var($htc,
            %args,
            var => $var->[1],
            method_args => $method_args,
        );
    }
    elsif ($type eq 'VAR_DEREF') {
        my ($var, $deref) = @args;
        my $str = $class->sub_expression($var, $compiler, $htc, %args);
        for my $d (@$deref) {
            my $deref_str = $class->sub_expression($d, $compiler, $htc, %args);
            $str .= $deref_str;
        }
        return $str;
    }
    elsif ($type eq 'DEREF_HASH') {
        my ($key) = @args;
        my $str = $class->sub_expression($args[0], $compiler, $htc, %args);
        $str = '->{' . $str . '}';
        return $str;
    }
    elsif ($type eq 'DEREF_ARRAY') {
        my ($index) = @args;
        my $str;
        if (ref $index) {
            $str = $class->sub_expression($index, $compiler, $htc, %args);
        }
        elsif ($index !~ m/-?[0-9]+/) {
            die "invalid array index $index";
        }
        else {
            $str = $index;
        }
        $str = '->[' . $str . ']';
        return $str;
    }

    elsif ($type eq 'FUNCTION_CALL') {
        my $name = shift @args;
        @args = @{ $args[0] || [] };
        my $expr = "$name( ";
        for my $i (0 .. $#args) {
            $expr .= $class->sub_expression($args[$i], $compiler, $htc, %args) . ' , ';
        }
        $expr .= ")";
        return $expr;
    }
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Expr - Expressions for HTC

=head1 DESCRIPTION

The expressions work like in L<HTML::Template::Expr>, with some additional
possibilities regarding object method calls and arbitrary data structures.

Different from L<HTML::Template::Expr>, you don't use it as the module
class, but you activate it by passing the option C<use_expressions> with
a true value.

See C<use_expressions> in L<HTML::Template::Compiled/"OPTIONS">

=cut

