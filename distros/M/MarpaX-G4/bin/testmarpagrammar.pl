#!/usr/bin/perl -w
# #################################################################################### #
# Program   testmarpagrammar                                                           #
#                                                                                      #
# Author    Axel Zuber                                                                 #
# Created   29.05.2022                                                                 #
#                                                                                      #
# Description   read a Marpa grammar from a HERE document,                             #
#               read an input file from a HERE document,                               #
#               apply the grammar to the input file and dump the parse tree            #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Input     Marpa::R2 grammar                                                          #
#           input file                                                                 #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Output    Parse tree                                                                 #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# Exit code                                                                            #
#        0 : Successful                                                                #
#        4 : Warnings                                                                  #
#        8 : Errors                                                                    #
#                                                                                      #
# ------------------------------------------------------------------------------------ #
#                                                                                      #
# History                                                                              #
# Ver   Date        Name        Description                                            #
# 0.9   29.05.2022  A. Zuber    Initial version                                        #
#                                                                                      #
# #################################################################################### #

package Main;
use strict;
use warnings FATAL => 'all';

use strict;

use Marpa::R2;
use Data::Dump;

my $dsl = <<'END_OF_DSL';
lexeme default = latm => 1

:start          ::= eval

# ---
# Discard rule from redirect options :
:discard         ~   <discarded redirects>
<discarded redirects> ~   WS
# ---
eval                ::=   additionExp
additionExp         ::=   multiplyExp additionExp_002        action => do_add
additionExp_001     ::=   '+' multiplyExp
                    |     '-' multiplyExp
additionExp_002     ::=   additionExp_001*

multiplyExp         ::=   atomExp multiplyExp_002            action => do_mult
multiplyExp_001     ::=   '*' atomExp
                    |     '/' atomExp
multiplyExp_002     ::=   multiplyExp_001*

atomExp             ::=   Number
                    |     '(' additionExp ')'
Number              ~     UNSIGNED_INTEGER opt_Number_006
SINGLE_DIGIT        ~     [0-9]
UNSIGNED_INTEGER    ~     SINGLE_DIGIT+
Number_005          ~     '.' UNSIGNED_INTEGER
opt_Number_006      ~
opt_Number_006      ~     Number_005

WS                  ~     [ \t\r\n]+
END_OF_DSL

my $grammar = Marpa::R2::Scanless::G->new({
    source          => \$dsl,
    action_object   => 'Actions',
    default_action  => 'default_action'
});
my $parser  = Marpa::R2::Scanless::R->new({ grammar => $grammar });

my $input = <<'__INPUT__';
2*((5+2)*3)
__INPUT__

$Actions::generateparsetree = 0;
$Actions::traceprocessing   = 1;

$parser->read(\$input);

my $value_ref   = $parser->value();

print Data::Dump::dump($$value_ref);

exit 0;

# ------------------------------------------------------------------------------------ #
# Example grammar actions                                                              #
# ------------------------------------------------------------------------------------ #

package Actions;
use strict;

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

sub trace
{
    my ($self, $function, $direction, $data) = @_;

    return if !$Actions::traceprocessing;

    printf "%1s %-8s", $direction, $function;
    print Data::Dump::dump($data);
    printf "\n";
}

sub do_add
{
    my ($self, @items) = @_;

    return \@items if $Actions::generateparsetree;

    $self->trace('do_add', '<', \@items);

    my $result = $items[0];
    shift @items;

    if (!scalar @{$items[0]})
    {
        $self->trace('do_add', '>', $result);
        return $result;
    }

    for my $item (@items)
    {
        my $op   = $item->[0];
        my $opnd = $item->[1];
        $opnd = $opnd->[1] if ref $opnd eq "ARRAY" && $opnd->[0] eq "(";
        SWITCH: {
            ($op eq "+") && do { $result += $opnd; last SWITCH; };
            ($op eq "-") && do { $result -= $opnd; last SWITCH; };
        }
    }

    $self->trace('do_add', '>', $result);

    return $result;
}

sub do_mult
{
    my ($self, @items) = @_;

    return \@items if $Actions::generateparsetree;

    $self->trace('do_mult', '<', \@items);

    my $result = $items[0];
    $result = $result->[1] if ref $result eq "ARRAY" && $result->[0] eq "(";
    shift @items;
    if (!scalar @{$items[0]})
    {
        $self->trace('do_mult', '>', $result);
        return $result;
    }

    for my $item (@items)
    {
        my $op   = $item->[0];
        my $opnd = $item->[1];
        $opnd = $opnd->[1] if ref $opnd eq "ARRAY" && $opnd->[0] eq "(";
        SWITCH: {
            ($op eq "*") && do { $result *= $opnd; last SWITCH; };
            ($op eq "/") && do { $result /= $opnd; last SWITCH; };
        }
    }

    $self->trace('do_mult', '>', $result);

    return $result;
}

sub default_action
{
    my ($self, @items ) = @_;

    my $result = \@items;

    if (scalar @items == 1)
    {
        $result = $items[0];
    }
    else
    {
        my $count = 0;
        my $state = 0;

        for my $item (@items)
        {
            if (ref $item ne "ARRAY" || (ref $item eq "ARRAY" && scalar @$item > 0))
            {
                $state = 2 if !$state;
                ++$count;
            }
            $state = 1 if !$state;
        }

        $result = $items[0] if $state == 2 && $count == 1;
    }

    return $result;
}
1;
