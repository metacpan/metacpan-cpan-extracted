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
# Input     ANTLR4 grammar                                                             #
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
:discard        ~   <discarded redirects>
<discarded redirects> ~   WS
# ---
eval            ::= additionExp
additionExp     ::= multiplyExp additionExp_002
additionExp_001 ::= '+' multiplyExp
                |   '-' multiplyExp
additionExp_002 ::= additionExp_001*

multiplyExp     ::= atomExp multiplyExp_002
multiplyExp_001 ::= '*' atomExp
                |   '/' atomExp
multiplyExp_002 ::= multiplyExp_001*

atomExp         ::= Number
                |   '(' additionExp ')'
Number          ::= Number_002 opt_Number_006
Number_001      ~   [0-9]
Number_002      ::= Number_001+
Number_003      ~   [0-9]
Number_004      ::= Number_003+
Number_005      ::= '.' Number_004
opt_Number_006  ::=
opt_Number_006  ::= Number_005

WS     ~   WS_002
WS_001 ~   [ \t\r\n]
WS_002 ~   WS_001+
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

sub default_action
{
    my ($self, @items ) = @_;

    my $result = \@items;
    if (scalar @items == 1)
    {
        $result = $items[0];
    }

    return $result;
}
1;
