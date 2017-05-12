use v6-alpha;

grammar Language::Tea::Grammar;

token ws {
    [ \s 
    | \n 
    ]+
}

token hws {
    [ \h | \\ \n ]
}

token comment {
    '#' 
    $<comment_text> := [\N+] 
}

token arg_symbol{ 
    #'$'? 
    #(
        <-[ \s \n \] \} \) ]>+
    #)
    # (\S+) 
    #{ return ~$0 }
}

token arg_substitution {
    '$' <arg_symbol>
}

token arg_double {
    |  \d+ \. \d+  
    |  \d+  'd'   # ???
}

token arg_integer {
    \d+
}

token arg_string {
        [
        |   \\ \" 
        |    <-[\"]>
        ]* 
}

token arg_do {
    #{ say 'arg do'; }
    '['
    <ws>?
    <statement>*
    <ws>?
    ']'
    #{ return $<statement> }
}

token arg_list {
    '('
    <ws>?
    [ 
        <arg> 
        <ws>*   
    ]*
    ')'
}

token arg_code {
    '{'
    <ws>?
    [
        <statement>
        <ws>?
    ]*
    '}'
}

token arg {
    | <arg_double>
    | <arg_integer>
    | '"' <arg_string> '"'
    | <arg_do>
    | <arg_list>
    | <arg_code>
    | <arg_substitution>
    | <arg_symbol>
}

token define { define | global }

token statement {
    # | <comment>
    # |   # $<func>   := <arg> 
        
        <define> <?hws>+ <arg_symbol> <?hws>+ <arg_list> <?hws>+ <arg_code>
    |
        <define> <?hws>+ <arg_symbol> <?hws>+ <statement>*
    |
        [
            | <?hws>*
              <comment>
            | <?hws>*
              <arg>
        ]+
        <?hws>*  
}

token statements {
    <?ws>?
    [
        <statement>
        <?ws>?
    ]*
}

