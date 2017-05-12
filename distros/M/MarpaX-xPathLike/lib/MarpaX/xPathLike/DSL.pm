package MarpaX::xPathLike::DSL;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.201';

our $xpath = <<'END_OF_SOURCE';

:default ::= action => ::array
:start ::= Start

Start    ::= 
    (WS) OperExp (WS)                                  action => ::first

OperExp ::=
    PathExpr                                           action => _do_path
    |Function                                          action => ::first

Function ::=
    NumericFunction                                    action => ::first
    | StringFunction                                   action => ::first
    | ListFunction                                     action => ::first

PathExpr ::=
    absolutePath                                       action => _do_absolutePath
    | relativePath                                     action => _do_relativePath
    | PathExpr '|' PathExpr                            action => _do_pushArgs2array

PredPathExpr ::=
    absolutePath                                       action => _do_absolutePath
    | stepPathNoDigitStart                             action => _do_relativePath
    | './' stepPath                                    action => _do_relativePath2
    | PredPathExpr '|' PredPathExpr                    action => _do_pushArgs2array

relativePath ::=    
    stepPath                                           action => ::first

absolutePath ::=    
    subPath                                            action => ::first

subPath ::=    
    ('/') stepPath                                     action => ::first
    | '//' stepPath                                    action => _do_vlen

stepPath ::=
    step Filter subPath                                action => _do_stepFilterSubpath
    | step Filter                                      action => _do_stepFilter
    | step subPath                                     action => _do_stepSubpath
    | step                                             action => ::first


step ::= 
    keyOrAxis                                          action => ::first            
    |index                                             action => ::first

index ::=
    UINT                                               action => _do_array_hash_index

stepPathNoDigitStart ::=     
    keyOrAxis Filter subPath                           action => _do_stepFilterSubpath
    | keyOrAxis Filter                                 action => _do_stepFilter
    | keyOrAxis subPath                                action => _do_stepSubpath
    | keyOrAxis                                        action => ::first


keyOrAxis ::= 
    keyname                                            action => _do_keyname
    | '[' UINT ']'                                     action => _do_array_index
    | '.'                                              action => _do_self
    | '[.]'                                            action => _do_selfArray
    | '{.}'                                            action => _do_selfHash
    | 'self::*'                                        action => _do_self    
    | 'self::[*]'                                      action => _do_selfArray    
    | 'self::{*}'                                      action => _do_selfHash    
    | 'self::' keyname                                 action => _do_selfNamed    
    | 'self::' UINT                                    action => _do_selfIndexedOrNamed    
    | 'self::[' UINT ']'                               action => _do_selfIndexed    
    | '*'                                              action => _do_child
    | '[*]'                                            action => _do_childArray
    | '{*}'                                            action => _do_childHash
    | 'child::*'                                       action => _do_child
    | 'child::[*]'                                     action => _do_childArray
    | 'child::{*}'                                     action => _do_childHash
    | 'child::' keyname                                action => _do_childNamed
    | 'child::'    UINT                                action => _do_childIndexedOrNamed
    | 'child::[' UINT ']'                              action => _do_childIndexed
    | '..'                                             action => _do_parent
    | '[..]'                                           action => _do_parentArray
    | '{..}'                                           action => _do_parentHash
    | 'parent::*'                                      action => _do_parent
    | 'parent::[*]'                                    action => _do_parentArray
    | 'parent::{*}'                                    action => _do_parentHash
    | 'parent::' keyname                               action => _do_parentNamed              
    | 'parent::' UINT                                  action => _do_parentIndexedOrNamed              
    | 'parent::[' UINT ']'                             action => _do_parentIndexed              
    | 'ancestor::*'                                    action => _do_ancestor
    | 'ancestor::[*]'                                  action => _do_ancestorArray
    | 'ancestor::{*}'                                  action => _do_ancestorHash
    | 'ancestor::' keyname                             action => _do_ancestorNamed
    | 'ancestor::' UINT                                action => _do_ancestorIndexedOrNamed
    | 'ancestor::[' UINT ']'                           action => _do_ancestorIndexed
    | 'ancestor-or-self::*'                            action => _do_ancestorOrSelf
    | 'ancestor-or-self::[*]'                          action => _do_ancestorOrSelfArray
    | 'ancestor-or-self::{*}'                          action => _do_ancestorOrSelfHash
    | 'ancestor-or-self::'     keyname                 action => _do_ancestorOrSelfNamed
    | 'ancestor-or-self::'     UINT                    action => _do_ancestorOrSelfIndexedOrNamed
    | 'ancestor-or-self::[' UINT ']'                   action => _do_ancestorOrSelfIndexed
    | 'descendant::*'                                  action => _do_descendant
    | 'descendant::[*]'                                action => _do_descendantArray
    | 'descendant::{*}'                                action => _do_descendantHash
    | 'descendant::' keyname                           action => _do_descendantNamed
    | 'descendant::' UINT                              action => _do_descendantIndexedOrNamed
    | 'descendant::[' UINT ']'                         action => _do_descendantIndexed
    | 'descendant-or-self::*'                          action => _do_descendantOrSelf
    | 'descendant-or-self::[*]'                        action => _do_descendantOrSelfArray
    | 'descendant-or-self::{*}'                        action => _do_descendantOrSelfHash
    | 'descendant-or-self::' keyname                   action => _do_descendantOrSelfNamed
    | 'descendant-or-self::' UINT                      action => _do_descendantOrSelfIndexedOrNamed
    | 'descendant-or-self::[' UINT ']'                 action => _do_descendantOrSelfIndexed
    | 'preceding-sibling::*'                           action => _do_precedingSibling
    | 'preceding-sibling::[*]'                         action => _do_precedingSiblingArray
    | 'preceding-sibling::{*}'                         action => _do_precedingSiblingHash
    | 'preceding-sibling::' keyname                    action => _do_precedingSiblingNamed
    | 'preceding-sibling::' UINT                       action => _do_precedingSiblingIndexedOrNamed
    | 'preceding-sibling::[' UINT ']'                  action => _do_precedingSiblingIndexed
    | 'following-sibling::*'                           action => _do_followingSibling
    | 'following-sibling::[*]'                         action => _do_followingSiblingArray
    | 'following-sibling::{*}'                         action => _do_followingSiblingHash
    | 'following-sibling::' keyname                    action => _do_followingSiblingNamed
    | 'following-sibling::' UINT                       action => _do_followingSiblingIndexedOrNamed
    | 'following-sibling::[' UINT ']'                  action => _do_followingSiblingIndexed

IndexExprs ::= IndexExpr+             separator => <comma>

IndexExpr ::=
    IntExpr                                            action => _do_index_single
    | rangeExpr                                        action => ::first

rangeExpr ::= 
    IntExpr '..' IntExpr                               action => _do_index_range
    |IntExpr '..'                                      action => _do_startRange
    | '..' IntExpr                                     action => _do_endRange

Filter ::= 
    IndexFilter
    | LogicalFilter
    | Filter Filter                                    action => _do_mergeFilters

LogicalFilter ::=     
    '[' LogicalExpr ']'                                action => _do_boolean_filter

IndexFilter ::=     
    '[' IndexExprs ']'                                 action => _do_index_filter


IntExpr ::=
  (WS) ArithmeticIntExpr (WS)                          action => ::first

 ArithmeticIntExpr ::=
     INT                                               action => ::first
    | IntegerFunction                                  action => ::first
    | '(' IntExpr ')'                                  action => _do_group
    || '-' ArithmeticIntExpr                           action => _do_unaryOperator
     | '+' ArithmeticIntExpr                           action => _do_unaryOperator
    || IntExpr '*' IntExpr                             action => _do_binaryOperation
     | IntExpr 'div' IntExpr                           action => _do_binaryOperation
#     | IntExpr ' /' IntExpr                           action => _do_binaryOperation 
#     | IntExpr '/ ' IntExpr                           action => _do_binaryOperation 
     | IntExpr '%' IntExpr                             action => _do_binaryOperation
    || IntExpr '+' IntExpr                             action => _do_binaryOperation
     | IntExpr '-' IntExpr                             action => _do_binaryOperation


NumericExpr ::=
  (WS) ArithmeticExpr (WS)                             action => ::first

ArithmeticExpr ::=
    NUMBER                                             action => ::first
    || PredPathExpr                                    action => _do_getValueOperator
    | NumericFunction                                  action => ::first
    | '(' NumericExpr ')'                              action => _do_group
    || '-' ArithmeticExpr                              action => _do_unaryOperator
     | '+' ArithmeticExpr                              action => _do_unaryOperator
    || NumericExpr '*' NumericExpr                     action => _do_binaryOperation
     | NumericExpr 'div' NumericExpr                   action => _do_binaryOperation
#     | NumericExpr ' /' NumericExpr                   action => _do_binaryOperation
#     | NumericExpr '/ ' NumericExpr                   action => _do_binaryOperation
     | NumericExpr 'mod' NumericExpr                   action => _do_binaryOperation
     | NumericExpr '%' NumericExpr                     action => _do_binaryOperation
    || NumericExpr '+' NumericExpr                     action => _do_binaryOperation
     | NumericExpr '-' NumericExpr                     action => _do_binaryOperation

LogicalExpr ::=
    (WS) LogicalFunction (WS)                          action => ::first
    || (WS) compareExpr (WS)                           action => ::first

compareExpr ::=    
    PredPathExpr                                       action => _do_exists
    || AnyTypeExpr '<' AnyTypeExpr                     action => _do_binaryOperation
     | AnyTypeExpr '<=' AnyTypeExpr                    action => _do_binaryOperation
     | AnyTypeExpr '>' AnyTypeExpr                     action => _do_binaryOperation
     | AnyTypeExpr '>=' AnyTypeExpr                    action => _do_binaryOperation
     | StringExpr 'lt' StringExpr                      action => _do_binaryOperation
     | StringExpr 'le' StringExpr                      action => _do_binaryOperation
     | StringExpr 'gt' StringExpr                      action => _do_binaryOperation
     | StringExpr 'ge' StringExpr                      action => _do_binaryOperation
     | StringExpr '~' RegularExpr                      action => _do_binaryOperation
     | StringExpr '!~' RegularExpr                     action => _do_binaryOperation
     | NumericExpr '===' NumericExpr                   action => _do_binaryOperation
     | NumericExpr '!==' NumericExpr                   action => _do_binaryOperation
     | AnyTypeExpr '==' AnyTypeExpr                    action => _do_binaryOperation 
     | AnyTypeExpr '=' AnyTypeExpr                     action => _do_binaryOperation #to be xpath compatible
     | AnyTypeExpr '!=' AnyTypeExpr                    action => _do_binaryOperation
     | StringExpr 'eq' StringExpr                      action => _do_binaryOperation
     | StringExpr 'ne' StringExpr                      action => _do_binaryOperation
    || LogicalExpr 'and' LogicalExpr                   action => _do_binaryOperation
    || LogicalExpr 'or' LogicalExpr                    action => _do_binaryOperation


AnyTypeExpr ::=
    (WS) allTypeExp (WS)                               action => ::first    

allTypeExp ::=
    NumericExpr                                        action => ::first
    |StringExpr                                        action => ::first                    
  || PredPathExpr                                      action => _do_getValueOperator 


StringExpr ::=
    (WS) allStringsExp (WS)                             action => ::first

allStringsExp ::=
    STRING                                             action => ::first
     | StringFunction                                  action => ::first
     | PredPathExpr                                    action => _do_getValueOperator
     || StringExpr '||' StringExpr                     action => _do_binaryOperation


RegularExpr ::= 
    WS STRING    WS                                    action => _do_re

LogicalFunction ::=
    'not' '(' LogicalExpr ')'                          action => _do_func
    | 'isRef' '('  OptionalPathArgs  ')'               action => _do_func
    | 'isScalar' '(' OptionalPathArgs ')'              action => _do_func
    | 'isArray' '(' OptionalPathArgs ')'               action => _do_func
    | 'isHash' '(' OptionalPathArgs ')'                action => _do_func
    | 'isCode' '(' OptionalPathArgs ')'                action => _do_func

StringFunction ::=
    NameFunction                                       action => ::first
    | ValueFunction                                    action => ::first

NameFunction ::= 
    'name' '(' OptionalPathArgs ')'                    action => _do_func

OptionalPathArgs ::= 
    RequiredPathArgs                                   action => ::first
    | EMPTY                                            action => ::first

RequiredPathArgs ::=
    (WS) PathExpr (WS)                                 action => ::first

EMPTY ::= 

ValueFunction ::= 
    'value' '(' OptionalPathArgs ')'                   action => _do_func

CountFunction ::= 
    'count' '(' RequiredPathArgs ')'                   action => _do_func

LastFunction ::= 
    'last' '(' OptionalPathArgs ')'                    action => _do_func

PositionFunction ::= 
    'position' '(' OptionalPathArgs ')'                action => _do_func

SumFunction ::= 
    'sum' '(' RequiredPathArgs ')'                     action => _do_func

SumProductFunction ::= 
    'sumproduct' '(' RequiredPathArgs ',' RequiredPathArgs ')'             action => _do_funcw2args

NumericFunction ::=
    IntegerFunction                                    action => ::first
    |ValueFunction                                     action => ::first
    |SumFunction                                       action => ::first
    |SumProductFunction                                action => ::first

IntegerFunction ::=
    CountFunction                                      action => ::first
    |LastFunction                                      action => ::first
    |PositionFunction                                  action => ::first

ListFunction ::=
    'names' '(' OptionalPathArgs ')'                   action => _do_func
    | 'values' '(' OptionalPathArgs ')'                action => _do_func
    | 'lasts' '(' OptionalPathArgs ')'                 action => _do_func
    | 'positions' '(' OptionalPathArgs ')'             action => _do_func


 NUMBER ::= 
     unumber                                           action => ::first
     | '-' unumber                                     action => _do_join
     | '+' unumber                                     action => _do_join

unumber    
    ~ uint
    | uint frac
    | uint exp
    | uint frac exp
    | frac
    | frac exp
 
uint            
    ~ digits

digits 
    ~ [\d]+
 
frac
    ~ '.' digits
 
exp
    ~ e digits
 
e
    ~ 'e'
    | 'e+'
    | 'e-'
    | 'E'
    | 'E+'
    | 'E-'

INT ::= 
    UINT                                               action => ::first
    | '+' UINT                                         action => _do_join    #avoid ambiguity
    | '-' UINT                                         action => _do_join    #avoid ambiguity

UINT
    ~digits

STRING ::= 
    double_quoted                                      action => _do_double_quoted
    | single_quoted                                    action => _do_single_quoted

single_quoted        
    ~ ['] single_quoted_chars [']

single_quoted_chars      
     ~ single_quoted_char*
 
single_quoted_char  
    ~ [^'\\]
    | '\' [']
    | '\' '\'

double_quoted        
    ~ ["] double_quoted_chars ["]

double_quoted_chars      
     ~ double_quoted_char*
 
double_quoted_char  
    ~ [^"\\]
    | '\' '"'
    | '\' '\'

keyname ::= 
    keyword                                           action => ::first
    | ('{') keyword ('}')                             action => ::first
    | ('{') UINT ('}')                                action => ::first
    | ('{') STRING ('}')                              action => ::first
#   | STRING                                          action => ::first
#   | curly_delimited_string                          action => _do_curly_delimited_string

# curly_delimited_string
#     ~ '{' keyword '}'
#     | '{' double_quoted '}'
#     | '{' single_quoted '}'

# curly_delimited_chars
#     ~ curly_delimited_char*

# curly_delimited_char
#     ~ [^}{]
#     | '\'    '{'
#     | '\'    '}'

keyword ::=
    token                                             action => _do_token 

token 
    ~ ID

ID                      #must have at least one non digit 
    ~ notreserved
    | ID digits 
    | ID digits ID
    | digits ID
    | digits ID digits

notreserved 
    ~ [^\d:./*,'"|\s\]\[\(\)\{\}\\+-<>=!]+


# :discard 
#     ~ WS

WS ::= 
    whitespace
    |EMPTY

whitespace
    ~ [\s\n\r]+

comma 
    ~ ','

END_OF_SOURCE

1;
__END__

=pod 

=head1 DSL 

    xpathLike grammar

=cut
