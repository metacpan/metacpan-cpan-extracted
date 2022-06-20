# ----------------------------------------------------------------------------------------------------- #
# MarpaX::G4                                                                                            #
#                                                                                                       #
# a grammar for parsing antlr4 grammars and translating them to Marpa::R2 grammars.                     #
#                                                                                                       #
# ----------------------------------------------------------------------------------------------------- #

package MarpaX::G4::Parser;
use strict;
use warnings FATAL => 'all';

use strict;
use Marpa::R2 2.039_000;

sub new
{
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{grammarstate}   = undef;

    $self->{grammar} = Marpa::R2::Scanless::G->new(
    {
action_object  => 'MarpaX::G4::Actions',
default_action => 'default_action',
source         => \(<<'END_OF_SOURCE'),
lexeme default = latm => 1

:start                              ::= g4grammar

:discard                            ~   whitespace
whitespace                          ~   [\s]+

g4grammar                           ::= grammarentry*                                       action => do_grammar

grammarentry                        ::= symbolrule
                                    |   fragmentrule
                                    |   grammarspec
                                    |   optionspec
                                    |   namedspec
                                    |   linecomment
                                    |   blockcomment

symbolrule                          ::= name opt_return opt_comment (COLON) right_side      action => do_single_rule

right_side                          ::= rhs opt_hashcomment opt_comment end_rhs             action => do_right_side
                                    |   opt_redir (SEMICOLON)                               action => do_empty_rule

end_rhs                             ::= (BAR) right_side                                    action => do_endrhs
                                    |   opt_redir (SEMICOLON)                               action => do_empty_rule

rhs                                 ::= nonterminal+                                        action => do_rhs

nonterminal                         ::= opt_assoc rulecomponent opt_card                    action => do_nonterminal

rulecomponent                       ::= token | group                                       action => do_rulecomponent

group                               ::= (LPAREN) opt_colon rhs grouplist opt_bar (RPAREN)   action => do_group

grouplist                           ::= groupelement*                                       action => do_grouplist
groupelement                        ::= (BAR) rhs                                           action => do_groupelement_alternative
                                    |   rhs                                                 action => do_groupelement_concat

fragmentrule                        ::= (fragmentkeywd) opt_comment name opt_comment
                                        (COLON) fragment_right_side                         action => do_fragment
fragmentkeywd                       ~   'fragment'

fragment_right_side                 ::= fragment_rhs opt_hashcomment opt_comment
                                        fragment_end_rhs                                    action => do_right_side
                                    |   (SEMICOLON)

fragment_rhs                        ::= tokenlist                                           action => do_rhs

fragment_end_rhs                    ::= (BAR) fragment_right_side                           action => do_endrhs
                                    |   (SEMICOLON)                                         action => do_empty_rule

token                               ::= opt_neg literal                                     action => do_token
                                    |   opt_neg tokengroup                                  action => do_token
                                    |   name ALIASOP rulecomponent                          action => do_assignalias
                                    |   opt_neg name                                        action => do_name
                                    |   range
                                    |   regex
                                    |   valueclause
                                    |   <Inline Action>
                                    |   linecomment
                                    |   blockcomment

tokengroup                          ::= (LPAREN) opt_colon tokenlist (RPAREN)               action => do_token_group
tokenlist                           ::= tokenelement+                                       action => do_token_list
tokenelement                        ::= (BAR) token opt_card                                action => do_tokenelement_alternative
                                    |   token opt_card                                      action => do_tokenelement_concat

range                               ::= literal (RANGEOP) literal                           action => do_range

name                                ~   [a-zA-Z0-9_]+

valueclause                         ::= (LANGLE) name (RANGLE)                              action => do_valueclause

literal                             ::= lstring                                             action => do_literal
                                    |   characterclass                                      action => do_characterclass

lstring                             ~   quote in_string quote
quote                               ~   [']
in_string                           ~   in_string_char*

in_string_char                      ~   [^'\\]
                                    |   '\' [']
                                    |   '\' 'b'
                                    |   '\' 'f'
                                    |   '\' 'n'
                                    |   '\' 'r'
                                    |   '\' 't'
                                    |   '\' '/'
                                    |   '\' '*'
                                    |   '\' '#'
                                    |   '\\'
                                    |   '\' 'u' four_hex_digits
                                    |   '\' 'u' '{' hex_digits '}'
                                    |   '\' 'x' hex_digits

# a dash ('-') character immediately following or preceding the opening/closing bracket counts as a dash not a range
characterclass                      ~   '[-' in_class  ']'
                                    |   '['  in_class '-]'
                                    |   '['  in_class  ']'
in_class                            ~   in_class_element+
in_class_element                    ~   in_class_char | in_class_range
in_class_range                      ~   in_class_char '-' in_class_char
in_class_char                       ~   [^-\]\\]
                                    |   '\' [^u]
                                    |   '\' 'u' four_hex_digits
                                    |   '\' 'u' '{' hex_digits '}'
                                    |   '\' 'x' hex_digits

hex_digits                          ~   hex_digit+
four_hex_digits                     ~   hex_digit hex_digit hex_digit hex_digit
hex_digit                           ~   [0-9a-fA-F]

regex                               ::= '.' regex_cardinality                               action => do_regex
regex_cardinality                   ::= cardinality*

opt_assoc                           ::=
opt_assoc                           ::= assoc_clause
assoc_clause                        ~   '<assoc=' assoc_type '>'
assoc_type                          ~   'left' | 'right' | 'group'

opt_redir                           ::=
opt_redir                           ::= (redirect) redir_target redir_list                  action => do_redirect
redir_list                          ::= redir_suffix*
redir_suffix                        ::= COMMA redir_target
redir_target                        ::= name
                                    |   name (LPAREN) name (RPAREN)
redirect                            ~   '->'

opt_bar                             ::=
opt_bar                             ::= BAR

opt_colon                           ::=
opt_colon                           ::= COLON

opt_neg                             ::=
opt_neg                             ::= negation
negation                            ~   '~'

opt_card                            ::=
opt_card                            ::= cardinality
cardinality                         ~   [?*+]
                                    |   [*+] [?]

grammarspec                         ::= opt_grammarprefix ('grammar') name (SEMICOLON)      action => do_grammarspec
opt_grammarprefix                   ::=
opt_grammarprefix                   ::= 'lexer'
                                    |   'parser'

opt_return                          ::=
opt_return                          ::= 'returns' (LBRACKET) namelist (RBRACKET)            action => do_return_clause
namelist                            ::= name+

optionspec                          ::= <Options Prefix> <Inline Action>                    action => do_option_spec
<Options Prefix>                    ~   'options'
                                    |   'channels'
                                    |   'tokens'
                                    |   '@' <Options Name>
<Options Name>                      ~   [a-zA-Z0-9_:]+

namedspec                           ::= namedoptionkeywords name (SEMICOLON)                action => do_named_spec
namedoptionkeywords                 ~   'mode'
                                    |   'import'

<Inline Action>                     ::= ('{') <inline action text> ('}')                    action => do_inline_action
<inline action text>                ~   [^}]*

opt_comment                         ::=
opt_comment                         ::= multi_comment
multi_comment                       ::= single_comment+
single_comment                      ::= linecomment
                                    |   blockcomment

opt_hashcomment                     ::=
opt_hashcomment                     ::= hashcomment
hashcomment                         ::= hashcommenttext
hashcommenttext                     ~   '#' linecommenttext

linecomment                         ::= linecommentmatch                                    action => do_comment
linecommentmatch                    ~   linecommentprefix linecommenttext
linecommentprefix                   ~   '//'
linecommenttext                     ~   [^\n]*

blockcomment                        ::= <C style comment>                                   action => do_comment
<C style comment>                   ~   '/*' <comment interior> '*/'
<comment interior>                  ~    <optional non stars> <optional star prefixed segments> <optional pre final stars>
<optional non stars>                ~   [^*]*
<optional star prefixed segments>   ~   <star prefixed segment>*
<star prefixed segment>             ~   <stars> [^/*] <optional star free text>
<stars>                             ~   [*]+
<optional star free text>           ~   [^*]*
<optional pre final stars>          ~   [*]*

LPAREN                              ~   '('
RPAREN                              ~   ')'
LBRACKET                            ~   '['
RBRACKET                            ~   ']'
LANGLE                              ~   '<'
RANGLE                              ~   '>'
COLON                               ~   ':'
SEMICOLON                           ~   ';'
COMMA                               ~   ','
RANGEOP                             ~   '..'
BAR                                 ~   [|]
ALIASOP                             ~   '='
                                    |   '+='

END_OF_SOURCE
    }
);
    return $self;
}

sub enabletrace     { my ($self) = @_; $MarpaX::G4::Actions::trace = 1;             }
sub ignoreredirect  { my ($self) = @_; $MarpaX::G4::Actions::ignoreredirect = 1;    }

sub parse
{
    my ($self, $string) = @_;
    my $parserinstance = Marpa::R2::Scanless::R->new({ grammar => $self->{grammar} });
    $parserinstance->read(\$string);
    my $value_ref = $parserinstance->value();
    return ${$value_ref};
}

# ----------------------------------------------------------------------------------------------------- #
# MarpaX::G4::Actions                                                                                   #
#                                                                                                       #
# actions for processing grammar rules.                                                                 #
# ----------------------------------------------------------------------------------------------------- #

package MarpaX::G4::Actions;
use strict;

use Data::Dumper;

my $trace           = 0;
my $ignoreredirect  = 0;

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

sub isNotNull
{
    my ($value) = @_;
    return 0 if !defined $value;
    return 0 if ref $value eq "ARRAY" && scalar @$value      == 0;
    return 0 if ref $value eq "HASH"  && scalar keys %$value == 0;
    return 1;
}

sub dumpStructure
{
    my ( $self, $title, $structure ) = @_;

    printf "=== %s\n", $title;
    $Data::Dumper::Indent = 1;
    print Dumper($structure);
}

sub abortWithError
{
    my ( $self, $msg, $structure ) = @_;

    $self->dumpStructure($msg, $structure) if defined $structure;
    die $msg;
}

sub do_trace
{
    my ($self, $subroutinename, $structure ) = @_;
    return if !$MarpaX::G4::Actions::trace;
    $self->dumpStructure($subroutinename,$structure);
}

sub flattenArray
{
    my ($self, $value) = @_;
    my $result = $value;
    if (ref $value eq "ARRAY")
    {
        $self->abortWithError("\$value must hold exactly 1 value", $value) if scalar @$value != 1;
        $result = @{$value}[0];
    }
    return $result;
}

sub default_action
{
    my ($self, @items ) = @_;
    $self->do_trace("default_action", \@items);
    my $result = \@items;
    $result = $items[0] if scalar @items == 1;
    return $result;
}

sub do_grammar
{
    my ($self, @rules ) = @_;
    return \@rules;
}

sub do_option_spec
{
    my ($self, @items) = @_;
    $self->do_trace("do_option_spec", \@items);
    my $value = $items[1]->{action};
    $value = join("\n", @$value) if ref($value) eq "ARRAY";
    my $result = { comment => sprintf("%s : <%s>", $items[0], $value) };
    return $result;
}

sub do_named_spec
{
    my ($self, @items) = @_;
    $self->do_trace("do_named_spec", \@items);
    my $result = { comment => sprintf("%s : <%s>", $items[0], $items[1]) };
    return $result;
}

sub do_return_clause
{
    my ($self, @items) = @_;
    $self->do_trace("do_return_clause", \@items);
    my $result = { comment => sprintf("returns : [%s]", join( " ", @{$items[1]})) };
    return $result;
}

sub do_comment
{
    my ($self, @comment ) = @_;
    $self->do_trace("do_comment", \@comment);
    my $result = {};

    if ( ref($comment[0]) eq "HASH")
    {
        my $multicomment = [];
        for my $entry (@comment)
        {
            $self->abortWithError( "'comment' entry not found", $entry) if !exists $entry->{comment};
            push @$multicomment,  $entry->{comment};
        }
        $result = { comment => \@$multicomment };
    }
    else
    {
        $result = { comment => $comment[0] };
        if (scalar @comment > 1)
        {
            my $multicomment = [];
            for my $entry (@comment)
            {
                push @$multicomment, $entry;
            }
            $result = { comment => \@$multicomment };
        }
    }

    return $result;
}

sub do_grammarspec
{
    my ($self, @items) = @_;
    $self->do_trace("do_grammarspec", \@items);
    my $result = { grammarspec => $items[1] };

    if (isNotNull($items[0]))
    {
        $self->{grammarstate}   = $items[0];
        $result->{type}         = $items[0];
    }

    return $result;
}

sub do_inline_action
{
    my ($self, @items) = @_;
    $self->do_trace("do_inline_action", \@items);
    my $result = { action => $items[0] };
    return $result;
}

sub do_redirect
{
    my ($self, @items ) = @_;
    $self->do_trace("do_redirect", \@items);

    ##
    #   only process skip/hidden redirects when 'ignoreredirect' is active
    ##
    return {} if $MarpaX::G4::Actions::ignoreredirect && $items[0] !~ /skip|hidden/i;

    my ($redir, @redirlist) = @items;

    my $result = $redir;
    if ( scalar @redirlist > 0)
    {
        $result = [$redir];
        map { push @$result, $_ if scalar @$_ > 0; } @redirlist;
    }

    return $result;
}

sub do_fragment
{
    my ($self, $comment1, $name, $comment2, $tokenlist ) = @_;
    $self->do_trace("do_fragment", \[$name, $tokenlist]);

    $tokenlist = $tokenlist->{rightsides} if ref $tokenlist eq "HASH" && exists $tokenlist->{rightsides};

    $self->abortWithError( "'tokenlist' must be an array in fragment $name", $tokenlist) if ref $tokenlist ne "ARRAY";

    ##
    #   save the fragment's tokenlist in the same format as a regular rule's right sides
    ##
    my $result = {};

    if ( scalar @$tokenlist <= 1 )
    {
        $result = {
            type       => 'fragment',
            name       => $name,
            rightsides => [ { rhs => $tokenlist->[0] } ]
        };
    }
    else
    {
        $result = {
            type       => 'fragment',
            name       => $name,
            rightsides => [ { rhs => { type => 'tokengroup', definition => $tokenlist } } ]
        };
    }

    if (isNotNull($comment1) || isNotNull($comment2))
    {
        my $commentlines = [];
        push @$commentlines, $comment1            if ref $comment1 eq '';
        push @$commentlines, $comment1->{comment} if ref $comment1 eq "HASH";
        if (ref $comment2 eq "ARRAY")
        {
            for my $cl (@$comment2)
            {
                push @$commentlines, $cl->{comment} if ref $cl eq "HASH";
            }
        }
        $result->{comment} = $commentlines if scalar @$commentlines > 0;
    }

    $result->{grammarstate} = $self->{grammarstate} if exists $self->{grammarstate};

    return $result;
}

sub do_single_rule
{
    my ( $self, @items ) = @_;
    $self->do_trace("do_single_rule", \@items);

    my ( $name, $retclause, $comment, $rightsides ) = @items;

    my $result = { name => $name };

    $result->{redirect} = $rightsides->{redirect} if ref $rightsides eq "HASH" && exists $rightsides->{redirect};

    # CAVEAT: extract 'redirect' before reassigning '$rightsides' !
    $rightsides         = $rightsides->{rightsides} if ref $rightsides eq "HASH" && exists $rightsides->{rightsides};

    $result->{rightsides} = $rightsides;

    if (isNotNull($comment))
    {
        if (ref $comment eq "HASH" && exists $comment->{comment})
        {
            $result->{comment} = $comment->{comment};
        }
        elsif (ref $comment eq "ARRAY")
        {
            my $commentlines = [];
            for my $cl (@$comment)
            {
                if (ref $cl eq "HASH" && exists $cl->{comment})
                {
                    push @$commentlines, $cl->{comment};
                }
                else
                {
                    push @$commentlines, $cl;
                }
            }
            $result->{comment} = $commentlines;
        }
        else
        {
            $result->{comment} = $comment;
        }
    }

    $result->{returns}      = $retclause            if isNotNull($retclause);
    $result->{grammarstate} = $self->{grammarstate} if exists $self->{grammarstate};

    return $result;
}

sub do_right_side
{
    my ($self, @items ) = @_;
    $self->do_trace("do_right_side", \@items);
    my ( $rhs, $comment1, $comment2, $endrhs ) = @items;

    my $result = {};

    ##
    #   create 'rightsides' from rhs
    ##
    if (ref $rhs eq "ARRAY" && scalar @$rhs > 0)
    {
        $rhs = { rightsides => $rhs };
    }
    else
    {
        $rhs = { rightsides => [$rhs] };
    }

    $result = $rhs;

    if (isNotNull($comment1) || isNotNull($comment2))
    {
        my $commentlines = [];
        push @$commentlines, $comment1            if ref $comment1 eq '';
        push @$commentlines, $comment1->{comment} if ref $comment1 eq "HASH";
        if (ref $comment2 eq "ARRAY")
        {
            for my $cl (@$comment2)
            {
                push @$commentlines, $cl->{comment} if ref $cl eq "HASH";
            }
        }
        $result->{comment} = $commentlines if scalar @$commentlines > 0;
    }

    my $redirect = $endrhs->{redirect} if ref $endrhs eq "HASH" && exists $endrhs->{redirect};

    if (ref $endrhs eq "ARRAY" && isNotNull($endrhs))
    {
        $self->abortWithError("unexpected : endrhs is an ARRAY\n");
    }

    ##
    #   merge the rightsides of endrhs to those of rhs
    ##
    if (ref $endrhs eq "HASH" && exists $endrhs->{rightsides})
    {
        my $rightsides = $endrhs->{rightsides};

        $self->abortWithError("INTERNAL: endrhs rightsides must be an array", $rightsides                ) if ref $rightsides ne "ARRAY";
        $self->abortWithError("INTERNAL: rhs in do_endrhs must be a hash and contain 'rightsides'", $rhs ) if ref $rhs ne "HASH" || !exists $rhs->{rightsides};
        $self->abortWithError("INTERNAL: rhs/rightsides in do_endrhs must be a an array"          , $rhs ) if ref $rhs->{rightsides} ne "ARRAY";

        # merge the rightsides of rhs and endrhs
        push (@{$result->{rightsides}}, @$rightsides);
    }

    $result->{redirect} = $redirect if defined $redirect;

    return $result;
}

sub do_empty_rule
{
    my ($self, $opt_redir ) = @_;
    $self->do_trace("do_empty_rule", \$opt_redir);
    my $result = {};
    $result->{redirect} = $opt_redir if isNotNull($opt_redir);
    return $result;
}

sub do_endrhs
{
    my ($self, @items ) = @_;
    $self->do_trace("do_endrhs", \@items);
    my $rhs = $items[0];

    ##
    #   return an empty array if we run into an empty rule/alternative.
    ##
    if (ref $rhs eq "ARRAY" && scalar @$rhs == 0)
    {
        printf "WARNING: encountered empty right side of rule in 'endrhs'\n";
        return [];
    }

    $self->abortWithError("INTERNAL: 'rhs' must be a hash", $rhs) if ref $rhs ne "HASH";

    return { redirect => $rhs->{redirect} } if exists $rhs->{redirect} && !exists $rhs->{rightsides};

    if (!exists $rhs->{rightsides})
    {
        printf "WARNING: 'rhs' does not contain 'rightsides' in 'endrhs'";
        return {};
    }

    my $rightsides = $rhs->{rightsides};
    $self->abortWithError( "INTERNAL: rightsides must be an array", $rightsides) if ref $rightsides ne "ARRAY";

    my $firstrhs = $rightsides->[0];
    $self->abortWithError( "INTERNAL: firstrhs must be a hash", $firstrhs)       if ref $firstrhs ne "HASH";
    $self->abortWithError( "INTERNAL: firstrhs must contain 'rhs'", $firstrhs)   if !exists $firstrhs->{rhs};

    $firstrhs->{rhs}{alternative} = 'true';

    return $rhs;
}

sub do_rhs
{
    my ($self, @items) = @_;
    $self->do_trace("do_rhs", \@items);
    my $result = $items[0];
    $result = \@items if scalar @items > 1;
    return $result;
}

sub do_nonterminal
{
    my ( $self, @items ) = @_;
    $self->do_trace("do_nonterminal", \@items);
    my ($opt_assoc, $rulecomponent, $opt_card) = @items;

    $rulecomponent = $rulecomponent->[0] if ref $rulecomponent eq "ARRAY" && scalar @$rulecomponent == 1;

    if (isNotNull($opt_card))
    {
        if (ref $rulecomponent ne "HASH")
        {
            if (ref $rulecomponent eq "")
            {
                $rulecomponent = { token => $rulecomponent };
            }
            else
            {
                $self->abortWithError( "'rulecomponent' must be a scalar or a hash", $rulecomponent );
            }
        }
        $rulecomponent->{cardinality}  = $self->flattenArray($opt_card);
    }

    if (isNotNull($opt_assoc))
    {
        if (ref $rulecomponent ne "HASH")
        {
            if (ref $rulecomponent eq "")
            {
                $rulecomponent = { token => $rulecomponent };
            }
            else
            {
                $self->abortWithError( "'rulecomponent' must be a scalar or a hash", $rulecomponent );
            }
        }
        $rulecomponent->{associativity} = $self->flattenArray($opt_assoc);
    }

    my $result = { rhs => $rulecomponent };

    return $result;
}

sub do_rulecomponent
{
    my ($self, @items ) = @_;
    $self->do_trace("do_rulecomponent", \@items);
    return \@items;
}

sub do_group
{
    my ($self, @items ) = @_;
    $self->do_trace("do_group", \@items);
    my ( $opt_colon, $rhs, $grouplist, $opt_bar ) = @items;

    my $resultlist = [];

    $rhs = $rhs->[1]                          if ref $rhs eq "ARRAY" && scalar @$rhs == 1;
    push @$resultlist, $rhs;

    push @$resultlist, $grouplist             if ref $grouplist eq "HASH";
    map { push @$resultlist, $_ } @$grouplist if ref $grouplist eq "ARRAY";

    my $result = { type => 'rulegroup', definition => $resultlist };
    $result->{option} = '(:' if isNotNull($opt_colon);
    $result->{option} = '|)' if isNotNull($opt_bar);

    return $result;
}

sub do_grouplist
{
    my ($self, @items ) = @_;
    $self->do_trace("do_grouplist", \@items);
    my $result = $items[0];
    return $result;
}

sub do_groupelement_concat
{
    my ($self, @items ) = @_;
    $self->do_trace("do_groupelement_concat", \@items);
    my $element = $items[0];
    my $result = { groupelement => $element };
    $result = $element if ref $element eq "HASH" && scalar keys %$element == 1;
    return $result;
}

sub do_groupelement_alternative
{
    my ($self, @items ) = @_;
    $self->do_trace("do_groupelement_alternative", \@items);
    my $element = $items[0];

    my $result = { alternative => 'true', groupelement => $element };

    if ( ref $element eq "HASH" && scalar keys %$element == 1)
    {
        $result = $element;
        $result->{alternative} = 'true';
    }

    return $result;
}

sub do_token_group
{
    my ($self, @items ) = @_;
    $self->do_trace("do_token_group", \@items);
    my $result = { type => 'tokengroup', definition => $items[1] };
    $result->{option} = '(:' if isNotNull($items[0]);
    return $result;
}

sub do_token_list
{
    my ($self, @items ) = @_;
    $self->do_trace("do_token_list", \@items);
    return \@items;
}

sub do_tokenelement_concat
{
    my ($self, $token, $opt_card ) = @_;
    $self->do_trace("do_tokenelement_concat", \[$token, $opt_card]);
    $token = $token->{token} if ref $token eq "HASH" && scalar keys %$token == 1 && exists $token->{token};
    my $result = { token => $token };
    $result->{cardinality} = $self->flattenArray($opt_card) if isNotNull($opt_card);
    return $result;
}

sub do_tokenelement_alternative
{
    my ( $self, $token, $opt_card ) = @_;
    $self->do_trace("do_tokenelement_alternative", \[$token, $opt_card]);
    $token = $token->{token} if ref $token eq "HASH" && scalar keys %$token == 1 && exists $token->{token};
    my $result = { alternative => 'true', token => $token };
    $result->{cardinality} = $self->flattenArray($opt_card) if isNotNull($opt_card);
    return $result;
}

sub do_token
{
    my ($self, $opt_neg, $token ) = @_;
    $self->do_trace("do_token", \[$opt_neg, $token]);
    my $result = { token => $token };
    $result->{negation} = $self->flattenArray($opt_neg) if isNotNull($opt_neg);
    return $result;
}

sub do_assignalias
{
    my ($self, @items ) = @_;
    $self->do_trace("do_assignalias", \@items);
    # alias op can be '=' or '+='
    my $result = { token => $items[2], alias => { name => $items[0], op => $items[1] } };
    return $result;
}

sub do_name
{
    my ($self, @items ) = @_;
    $self->do_trace("do_name", \@items);
    my $result = { token => $items[1] };
    $result->{negation} = $items[0] if isNotNull($items[0]);
    return $result;
}

sub do_range
{
    my ($self, @items ) = @_;
    $self->do_trace("do_range", \@items);
    my $result = { type => 'range', begr => $items[0], endr => $items[1] };
    return $result;
}

sub do_regex
{
    my ($self, @items ) = @_;
    $self->do_trace("do_regex", \@items);
    my $result = { type => 'regex', anchor => $items[0], cardinality => $items[1] };
    return $result;
}

sub do_valueclause
{
    my ($self, @items ) = @_;
    $self->do_trace("do_valueclause", \@items);
    my $result = { type => 'value', name => $items[0] };
    return $result;
}

sub do_literal
{
    my ($self, @items ) = @_;
    $self->do_trace("do_literal", \@items);
    my $value = $items[0];
    my $delimiter = substr($value, 0, 1);
    $value =~ s/^${delimiter}(.*)${delimiter}$/$1/;
    my $result = { type => 'literal', value => $value };
    return $result;
}

sub do_characterclass
{
    my ($self, @items ) = @_;
    $self->do_trace("do_characterclass", \@items);
    my $classtext = $items[0];
    $classtext =~ s/\[(.*)\]/$1/;
    my $result = { type => 'class', value => $classtext };
    return $result;
}

1;

# ABSTRACT: G4 parser using Marpa

=head1 SYNOPSIS
=for MarpaX::G4
name: Landing page synopsis
normalize-whitespace: 1
    use MarpaX::G4;
    my $infile = shift @ARGV;
    my $grammartext = readFile($infile);
    my $data = MarpaX::G4::parse_rules($grammartext);
=head1 DESCRIPTION
Parse an antlr4 grammar from the grammar text and return a parse tree.
=cut
