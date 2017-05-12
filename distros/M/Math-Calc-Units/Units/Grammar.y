# To process: yapp -s -m Math::Calc::Units::Grammar Grammar.y

%{
    use Math::Calc::Units::Compute qw(plus minus mult divide power construct);
%}

# Lowest
%nonassoc BARE_UNIT
%nonassoc NUMBER CONSTRUCT
%left '+' '-'
%left '*' '/'
%left WORD
%left '**'
# Highest

%%

START : expr
      | '#' unit
;

expr : expr '+' expr   { return plus($_[1], $_[3]); }
     | expr '-' expr   { return minus($_[1], $_[3]); }
     | expr '*' expr   { return mult($_[1], $_[3]); }
     | expr '/' expr   { return divide($_[1], $_[3]); }
     | expr '**' expr  { return power($_[1], $_[3]); }
     | '(' expr ')'    { return $_[2]; }
     | value           { return $_[1]; }
     | expr unit       { return mult($_[1], [ 1, $_[2] ]); }
;

value : NUMBER unit
                       { return [ $_[1] => $_[2] ] }
      | unit %prec BARE_UNIT
                       { return [ 1 => $_[1] ] }
      | NUMBER         { return [ $_[1] => {} ] }
      | '-' NUMBER     { return [ -$_[2] => {} ] }
      | '@' NUMBER     { return [ $_[2] => { 'timestamp' => 1 } ] }
      | CONSTRUCT      { return construct($_[1]) }
;

unit : WORD	       { return { $_[1] => 1 } }
     | WORD WORD       { my $u = {}; $u->{$_[1]}++; $u->{$_[2]}++; return $u; }
;

%%
