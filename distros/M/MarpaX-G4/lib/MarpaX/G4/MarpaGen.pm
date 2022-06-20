# ----------------------------------------------------------------------------------------------------- #
# MarpaX::MarpaGen                                                                                      #
#                                                                                                       #
# translate the parsed antlr4 rules to Marpa::R2 syntax.                                                #
#                                                                                                       #
# ----------------------------------------------------------------------------------------------------- #

package MarpaX::G4::MarpaGen;

use strict;
use warnings FATAL => 'all';
no warnings 'recursion';

use Data::Dumper;

use MarpaX::G4::Parser;
use MarpaX::G4::Symboltable;

# --------------------------------------------------- #
# exposed class methods                               #
# --------------------------------------------------- #

sub new
{
    my $invocant    = shift;
    my $class       = ref($invocant) || $invocant;  # Object or class name
    my $self        = {};                           # initiate our handy hashref
    bless($self,$class);                            # make it usable

    $self->{symboltable}        = undef;
    $self->{verbosity}          = 0;
    $self->{level}              = -1;
    $self->{outputfilename}     = '-';
    $self->{outf}               = undef;
    $self->{rules}              = {};
    $self->{subrules}           = {};
    $self->{generationoptions}  = {};

    return $self;
}

sub setVerbosity         { my ($self, $verbosity) = @_; $self->{verbosity} = defined($verbosity) ? $verbosity : 0; }
sub symboltable          { my ($self) = @_; return $self->{symboltable};                                           }
sub setoutputfile        { my ($self, $outputfilename) = @_; $self->{outputfilename} = $outputfilename;            }

sub fragment2class       { my ($self) = @_; $self->{generationoptions}{fragment2class}       = 'true';             }
sub embedactions         { my ($self) = @_; $self->{generationoptions}{embedactions}         = 'true';             }
sub stripactions         { my ($self) = @_; $self->{generationoptions}{stripactions}         = 'true';             }
sub stripallcomments     { my ($self) = @_; $self->{generationoptions}{stripallcomments}     = 'true';             }
sub matchcaseinsensitive { my ($self) = @_; $self->{generationoptions}{matchcaseinsensitive} = 'true';             }
sub shiftlazytogreedy    { my ($self) = @_; $self->{generationoptions}{shiftlazytogreedy}    = 'true';             }
sub buildkeywords        { my ($self) = @_; $self->{generationoptions}{buildkeywords}        = 'true';             }

sub testoption
{
    my ( $self, $option ) = @_;

    return undef if !defined $option;
    $option = lc $option;
    return undef if !exists $self->{generationoptions}{$option};

    return $self->{generationoptions}{$option};
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

    $self->dumpStructure($msg, $structure);
    die "aborting on unrecoverable error";
}

sub mydie
{
    my ( $msg ) = @_;
    die "${msg}";
}

sub addMarpaRule
{
    my ( $self, $rulename, $marparule ) = @_;

    my $rules = $self->{rules};
    mydie "INTERNAL: rule $rulename defined more than once" if exists $rules->{$rulename};
    $rules->{$rulename} = $marparule;
}

##
#   deleteMarpaRule : delete '$rulename'
##
sub deleteMarpaRule
{
    my ( $self, $rulename ) = @_;

    my $rules = $self->{rules};

    mydie "INTERNAL: can't delete undefined rule $rulename" if !exists $rules->{$rulename};

    $self->deleteAllSubrules($rulename);
    $rules->{$rulename} = { deletedafterconversiontoclass => 'true' };
}

##
#   deleteAllSubrules : delete all subrules of '$rulename'
##
sub deleteAllSubrules
{
    my ($self, $rulename ) = @_;

    my $subrules    = $self->{subrules};
    my $rules       = $self->{rules};

    return if !exists $subrules->{$rulename};

    for my $subrulename (@{$subrules->{$rulename}})
    {
        $rules->{$subrulename} = { deletedafterconversiontoclass => 'true' };
    }
}

##
#   deleteSingleSubrule : delete 'subrulename' if it is a subrule of 'rulename'
##
sub deleteSingleSubrule
{
    my ( $self, $rulename, $subrulename ) = @_;

    return if !exists $self->{subrules}{$rulename};

    my $subrules = $self->{subrules}{$rulename};

    ##
    #   remove the subrule by creating a new list of subrules
    ##
    my $status = 0;
    my @newrules;

    map {
        if ( $_ eq $subrulename )
        {
            $status = 1;
        }
        else
        {
            push @newrules, $_;
        }
    } @$subrules;

    $self->{subrules}{$rulename} = \@newrules;
    if ($status)
    {
        my $rules = $self->{rules};
        mydie "INTERNAL: can't delete undefined rule $subrulename" if !exists $rules->{$subrulename};
        $rules->{$subrulename} = { deletedafterconversiontoclass => 'true' }
    }
}

sub checkMarpaRuleExists
{
    my ( $self, $rulename ) = @_;

    my $rules = $self->{rules};

    return undef if !exists $rules->{$rulename};

    return $rules->{$rulename};
}

sub getMarpaRule
{
    my ( $self, $parent, $rulename ) = @_;

    my $rules = $self->{rules};

    if (!exists $rules->{$rulename})
    {
        $parent = "<ROOT>" if !defined $parent;
        mydie "INTERNAL: rule $rulename is undefined under parent $parent";
    }

    return $rules->{$rulename};
}

sub tagMarpaRule
{
    my ( $self, $rulename ) = @_;

    my $rules = $self->{rules};
    mydie "INTERNAL: rule $rulename is undefined" if !exists $rules->{$rulename};
    $rules->{$rulename}{status} = 'done';
}

sub isSubrule
{
    my ( $self, $rulename, $subrulename ) = @_;

    my $subrules = $self->{subrules};

    return 0 if !exists $subrules->{$rulename};

    for my $sr (@{$subrules->{$rulename}})
    {
        return 1 if $sr eq $subrulename;
    }

    return 0;
}

# --------------------------------------------------- #
# grammar generator                                   #
# --------------------------------------------------- #

sub enterLevel
{
    my ($self, $rulename, $context) = @_;

    my $level   = $context->{level} if exists $context->{level};
    $level      = -1 if !defined $level;
    ++$level;
    $context->{level} = $level;
}

sub exitLevel
{
    my ($self, $rulename, $context) = @_;

    my $level = $context->{level};
    --$level;
    $context->{level} = $level;
}

sub  retrieveModifier
{
    my ($token, $tag) = @_;

    return undef if ref $token ne 'HASH';

    my $modifier = undef;
    $modifier = $token->{$tag} if exists $token->{$tag};

    return $modifier;
}

sub negateElement
{
    my ($self, $rulename, $mxtoken, $context) = @_;

    # if ($rulename =~ /NATIONAL_CHAR_STRING_LIT/)
    # {
    #     printf "found!\n";
    # }

    mydie "INTERNAL: negated element is not a hash in rule $rulename" if ref $mxtoken ne 'HASH';

    my $mxelement;

    if (! exists $mxtoken->{class4list} )
    {
        mydie "INTERNAL: can't negate missing class4list in rule $rulename";
        ##
        #   TODO:   verify if we could continue by mapping this error to 'unsupported'
        #           so that we could process the complete input
        ##
        $mxelement = { type => 'unsupported', msg => "can't negate non-class token in $rulename" };
    }

    my $class4list = $mxtoken->{class4list};
    $mxelement = { type => 'negatedclass', value => "^${class4list}" };

    $mxelement->{grammarstate}      = $mxtoken->{grammarstate}      if exists $mxtoken->{grammarstate};
    $mxelement->{isFragmentOrChild} = $mxtoken->{isFragmentOrChild} if exists $mxtoken->{isFragmentOrChild};

    ##
    #   delete the negated subrule since it will be replaced with a new subrule.
    ##
    if (exists $mxtoken->{rhs} && exists $mxtoken->{rhs}{token})
    {
        my $token = $mxtoken->{rhs}{token};
        if (ref $token eq "")
        {
            $self->deleteSingleSubrule($rulename, $token);
        }
    }

    return $mxelement;
}

sub translateLiteralCase
{
    my ($string, $case) = @_;

    return $case =~ /^U/i ? uc $string : lc $string;
}

##
#   generatematchcaseinsensitive : make a literal (somewhat) case-insensitive by creating a subrule with 2 match alternatives :
#
#   - all uppercase
#   - characterclass with the 1st character in upper/lower case, the rest all lowercase
#
#   if the literal is only a single letter, we only retain the characterclass
#   if the first character is not a letter, we don't generate a class.
#
## --------------------------------------------------------------------------------------------------------- ##
##  CAVEAT : introduction of the ':i' and ':ic' literal and class modifiers has made this function obsolete. ##
##           we retain it as a demo of generated subrules.                                                   ##
## --------------------------------------------------------------------------------------------------------- ##
sub generateMatchCaseInsensitive
{
    my ($tokenvalue) = @_;

    my $lctoken = translateLiteralCase($tokenvalue, 'L');
    my $uctoken = translateLiteralCase($tokenvalue, 'U');
    my $prefix  = substr($lctoken, 0, 1);
    my $rest    = substr($lctoken, 1);
    my $lcp     = lc $prefix;
    my $ucp     = uc $prefix;
    my $mixedcase = "${lcp}${ucp}";

    my $literaltoken;

    if ($lcp =~ /[A-Z]/i)
    {
        $literaltoken = { type => 'tokengroup',
            definition => [{token => {type => 'class', value => $mixedcase}}]
        };
        push @{$literaltoken->{definition}}, {token => {type => 'literal', value => $rest }}                         if length($rest)    > 0;
        push @{$literaltoken->{definition}}, {token => {type => 'literal', value => $uctoken}, alternative=> 'true'} if length($uctoken) > 1;
    }
    else
    {
        $literaltoken = { type => 'tokengroup',
            definition => [{token => {type => 'literal', value => $lctoken}}]
        };
        push @{$literaltoken->{definition}}, {token => {type => 'literal', value => $uctoken}, alternative=> 'true'} if length($uctoken) > 1;
    }

    return $literaltoken;
}

sub isSingleChar
{
    my ($string) = @_;

    return 1 if $string =~ /^.$/;
    return 1 if $string =~ /^\\[^u]$/i;
    return 1 if $string =~ /^\\u[0-9A-F]{4,4}$/i;
    return 1 if $string =~ /^\\u\{[0-9A-F]{5,5}\}$/i;
    return 0;
}

sub isKeywordLetter
{
    my ($self, $rulename, $rule ) = @_;

    return 0 if !exists $rule->{class4list};
    my $s = $rule->{class4list};
    return 1 if $rulename =~ /^[a-z]$/i && $s =~ /([a-z])([a-z])/i && ( uc "$1" eq "$2" || lc "$1" eq "$2");
    return 0;
}

##
#   isKeywordFragment : return 1 if '$string' is a characterclass with a pair of lower/upper case letters
##
sub isKeywordFragment
{
    my ($self, $rulename, $rule ) = @_;

    return undef if !exists $rule->{class4list};
    my $string = $rule->{class4list};

    return lc substr($string, 0, 1) if $string =~ /([a-z])([a-z])/i && ( uc "$1" eq "$2" || lc "$1" eq "$2");
    return substr($string, 0, 1) if $string !~ /[a-z]/i;
    return substr($string, 0, 1) if $string =~ /[0-9]/i;

    return undef;
}

sub convertLiteralToClass
{
    my ($literal) = @_;

    return undef if !isSingleChar($literal);

    return "${literal}";
}

sub convertRangeToClass
{
    my ($token) = @_;

    my $begr = $token->{begr};
    my $endr = $token->{endr};

    return { type => 'unsupported', msg => "can't convert non-literal beg/end range to class" } if $begr->{type} ne 'literal' || $endr->{type} ne 'literal';

    $begr = $begr->{value};
    $endr = $endr->{value};

    return { type => 'unsupported', msg => "can't convert range (${begr} .. ${endr}) to class" } if !isSingleChar($begr) || !isSingleChar($endr);

    my $classtext = "${begr}-${endr}";

    return { type => 'class', value => $classtext, isLexeme => 1, class4list => $classtext };
}

sub mergeClass4List
{
    my ($tracker, $mxelement) = @_;

    mydie "tracker has no 'status'" if !exists $tracker->{status};

    if ( !exists $mxelement->{class4list} || $tracker->{status} == -1 )
    {
        $tracker->{status} = -1;
    }
    else
    {
        $tracker->{value} .= $mxelement->{class4list};
    }
}

sub mergeKeywordFragment
{
    my ($tracker, $mxelement) = @_;

    mydie "tracker has no 'status'" if !exists $tracker->{status};

    if ( !exists $mxelement->{keywordfragment} || $tracker->{status} == -1 )
    {
        $tracker->{status} = -1;
    }
    else
    {
        $tracker->{value} .= $mxelement->{keywordfragment};
    }
}

sub generateSubruleName
{
    my ($self, $rulename, $cardinality, $context) = @_;

    $context->{subruleindex}{$rulename}{index} = 0 if !exists $context->{subruleindex}{$rulename}{index};

    my $subruleindex = ++$context->{subruleindex}{$rulename}{index};
    my $subrulename  = sprintf "%s_%03d", $rulename, $subruleindex;

    if ( defined $cardinality && $cardinality eq "?" )
    {
        $subrulename = "opt_" . $subrulename;
    }

    push @{$self->{subrules}{$rulename}}, $subrulename;

    return $subrulename;
}

##
#   createSubRule :     create a (non-)anonymous subrule to 'rulename'.
#                       create a negated class if the class or token group was negated.
#
#   CAVEAT:             remember to reset the 'negation' flag in the caller
#                       to avoid negating twice.
##
sub createSubRule
{
    my ($self, $rulename, $mxelement, $negation, $cardinality, $context ) = @_;

    if ( defined $negation )
    {
        $mxelement = $self->negateElement($rulename, $mxelement, $context);
    }

    my $subrulename = $self->generateSubruleName($rulename, $cardinality, $context);

    ##
    #   propagate grammar fragment states to subrules (i.e. children)
    ##
    $mxelement->{grammarstate}      = $context->{subruleindex}{$rulename}{grammarstate}      if exists $context->{subruleindex}{$rulename}{grammarstate};
    $mxelement->{isFragmentOrChild} = $context->{subruleindex}{$rulename}{isFragmentOrChild} if exists $context->{subruleindex}{$rulename}{isFragmentOrChild};

    ##
    #   wrap cardinality "?" into an 'opt_' rule
    ##
    $mxelement->{cardinality} = $cardinality if defined $cardinality && $cardinality eq "?";

    $self->addMarpaRule($subrulename, $mxelement);

    my $mxalias = { rule => $subrulename, rhs => { token => $subrulename } };

    ##
    #   CAVEAT: don't propagate the lexeme tag upwards.
    #           this avoids confusion in G1 rules.
    ##
    $mxalias->{class4list}          = $mxelement->{class4list}                               if exists $mxelement->{class4list} && !defined $cardinality;
    $mxalias->{grammarstate}        = $context->{subruleindex}{$rulename}{grammarstate}      if exists $context->{subruleindex}{$rulename}{grammarstate};
    $mxalias->{isFragmentOrChild}   = $context->{subruleindex}{$rulename}{isFragmentOrChild} if exists $context->{subruleindex}{$rulename}{isFragmentOrChild};

    return $mxalias;
}

## ------------------------------------------------------
# 'walktoken' : process all token flavours
## ------------------------------------------------------
sub walktoken
{
    my ($self, $rulename, $token, $context) = @_;

    # if ( $rulename eq "EOF")
    # {
    #     printf "found!\n";
    # }

    my $alternative = retrieveModifier( $token, 'alternative' );
    my $cardinality = retrieveModifier( $token, 'cardinality' );

    my $mxToken     = {};
    my $comments    = [];

    if (ref $token eq 'HASH' && exists $token->{comment} && !$self->testoption('stripallcomments'))
    {
        mydie "comment not a plain string in rule $rulename" if ref $token->{comment} ne "";
        my $cl = $self->renderComment($rulename, [$token->{comment}]);
        push (@$comments, @$cl);
    }

    my $negation = retrieveModifier($token, 'negation');

    SWITCH:
    {
        (ref $token eq "") && do {
            $mxToken = $self->processSubRule($token, $context);
            $mxToken = $self->createSubRule( $rulename, $mxToken, $negation, $cardinality, $context );
            # reset 'negation' since it was processed by 'createSubRule'
            $negation = undef;
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'tokengroup') && do {
            $mxToken = $self->walkgroup($rulename, $token, $context);
            $mxToken = $self->createSubRule( $rulename, $mxToken, $negation, $cardinality, $context );
            # reset 'negation' since it was processed by 'createSubRule'
            $negation = undef;
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'rulegroup') && do {
            $mxToken = $self->walkgroup($rulename, $token, $context);
            # strip lexeme status off rule groups
            delete $mxToken->{isLexeme};
            $mxToken = $self->createSubRule( $rulename, $mxToken, $negation, $cardinality, $context );
            # reset 'negation' since it was processed by 'createSubRule'
            $negation = undef;
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'literal') && do {
            my $tokenvalue = $token->{value};
            $mxToken = { type => 'literal', value => $tokenvalue, isLexeme => 1 };
            my $class4list = convertLiteralToClass($tokenvalue);
            $mxToken->{class4list} = $class4list if defined $class4list;
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'class') && do {
            $mxToken = { type => 'class', value => $token->{value}, isLexeme => 1, class4list => $token->{value} };
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'regex') && do {
            $mxToken = { type => 'unsupported', msg => "can't convert arbitrary regex to Marpa in $rulename" };
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'range') && do {
            $mxToken = convertRangeToClass($token);
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{type} && $token->{type} eq 'value') && do {
            $mxToken = { type => 'unsupported', msg => "can't convert 'value' to Marpa in $rulename" };
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{token}) && do {
            $mxToken = $self->walktoken($rulename, $token->{token}, $context);
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{action}) && do {
            $mxToken = { type => 'ignore', msg => "embedded action in $rulename" };
            last SWITCH;
        };
        (ref $token eq 'HASH' && exists $token->{comment}) && do {
            $mxToken = { type => 'ignore', msg => "comment in $rulename" };
            last SWITCH;
        };
        do {
            $self->abortWithError( "can't process token for rule $rulename", $token );
            last SWITCH;
        };
    }

    ##
    #   apply 'negation' to every token type but groups and subrules
    ##
    if ( defined $negation )
    {
        $mxToken = $self->negateElement($rulename, $mxToken, $context);
        $negation = undef;
    }

    ###
    #   create explicit subrule for
    #   - nonterminals
    #   - subgroups
    #   annotated for cardinality
    ##
    if ( defined $cardinality )
    {
        $mxToken = $self->createSubRule( $rulename, $mxToken, undef, $cardinality, $context );

        # strip lexeme status off annotated subrules
        delete $mxToken->{isLexeme};
    }

    $mxToken->{alternative} = 'A'           if defined $alternative;
    $mxToken->{comments}    = $comments     if scalar @$comments > 0 && !$self->testoption('stripallcomments');

    return $mxToken;
}

sub walknonterminal
{
    my ( $self, $rulename, $nonterminal, $context ) = @_;

    mydie "nonterminal is not a hash for rule $rulename" if ref $nonterminal ne 'HASH';

    my $mxToken = {};

    SWITCH:
    {
        (exists $nonterminal->{rhs}) && do {
            my $rhs = $nonterminal->{rhs};
            $mxToken = $self->walktoken($rulename, $rhs, $context);
            last SWITCH;
        };
        do {
            $self->abortWithError( "can't process nonterminal for rule $rulename", $nonterminal );
            last SWITCH;
        };
    }

    return $mxToken;
}

## -------------------------------------------------------------------------------
# 'retagSimpleRule' : check if the cardinality can be added to 'mxtoken'.
#  Conditions :
#  - '?' is consumed by 'opt_' subrules, so we have to reject it here
#  - 'mxtoken' must be a subrule of 'rule'
#  - the parent rule must consist of a single element
#    (responsibility of the caller to verify)
## -------------------------------------------------------------------------------
sub retagSimpleRule
{
    my ( $self, $rulename, $mxtoken, $cardinality, $context, $options ) = @_;

    mydie "retagSimpleRule : token must be a hash in $rulename" if ref $mxtoken ne 'HASH';
    return 0 if $cardinality eq "?";

    $cardinality =~ s/([+*])\?/$1/ if $cardinality =~ /[+*]\?/ && $self->testoption('shiftlazytogreedy');
    mydie sprintf "lazy quantifier %s in rule %s not supported by Marpa. use option -g to map to greedy.", $cardinality, $rulename if $cardinality =~ /[+*]\?/;

    $options = {} if !defined $options;

    my $abortatfirstlevel = exists $options->{abortatfirstlevel};

    SWITCH: {
        (exists $mxtoken->{rhs}) && do {
            my $rhs = $mxtoken->{rhs};

            mydie "'rhs' must be a hash in $rulename"   if ref $rhs ne 'HASH';
            mydie "'token' must be a scalar in 'rhs' in rule $rulename" if !exists $rhs->{token} || ref $rhs->{token} ne "";

            return 0 if !defined $self->checkMarpaRuleExists($rhs->{token});

            my $rc = 0;

            if ($abortatfirstlevel)
            {
                my $subrulename = $rhs->{token};

                # don't push cardinality to a rule unless it is a subrule of the parent
                return 0 if !$self->isSubrule($rulename, $subrulename);

                my $rule  = $self->getMarpaRule($rulename, $subrulename);
                if ($cardinality ne "?")
                {
                    $rule->{cardinality} = $cardinality;
                    # cardinality-tagged tokens loose 'class4list' status
                    delete $rule->{class4list};
                    $rc = 1;
                }
            }
            else
            {
                my $subrulename = $rhs->{token};

                # don't push cardinality to a rule unless it is a subrule of the parent
                return 0 if !$self->isSubrule($rulename, $subrulename);

                my $rule  = $self->getMarpaRule($rulename, $subrulename);
                $rc = $self->retagSimpleRule($rulename, $rule, $cardinality, $context, $options);
                if ($rc)
                {
                    mydie "can't retag subrule $subrulename twice in rule $rulename" if exists $rule->{cardinality};
                    $rule->{cardinality} = $cardinality;
                    # cardinality-tagged tokens loose 'class4list' status
                    delete $rule->{class4list};
                }
            }
            return $rc;
            last SWITCH;
        };
        (exists $mxtoken->{type} && $mxtoken->{type} eq "group") && do {
            mydie "group rhs must contain 'list' in $rulename" if !exists $mxtoken->{list};
            my $ec = 0;
            for my $al (@{$mxtoken->{list}})
            {
                mydie "alternative list is not an array in rule $rulename" if ref $al ne 'HASH' || !exists $al->{list};
                for my $le (@{$al->{list}})
                {
                    mydie "alternative element is not simple in rule $rulename" if exists $le->{type} && $le->{type} !~ /literal|class/;
                    $ec += 1;
                }
            }
            return $ec <= 1;
            last SWITCH;
        };
        (exists $mxtoken->{type} && $mxtoken->{type} eq 'literal') && do {
            $mxtoken->{cardinality} = $cardinality;
            return 1;
            last SWITCH;
        };
        (exists $mxtoken->{type} && $mxtoken->{type} eq "class") && do {
            mydie "'class' can't be multiplied twice in $rulename" if exists $mxtoken->{cardinality};
            $mxtoken->{cardinality} = $cardinality;
            return 1;
            last SWITCH;
        };
        (exists $mxtoken->{type} && $mxtoken->{type} eq "negatedclass") && do {
            mydie "'negatedclass' can't be multiplied twice in $rulename" if exists $mxtoken->{cardinality};
            $mxtoken->{cardinality} = $cardinality;
            return 1;
            last SWITCH;
        };
        do {
            $self->abortWithError( "don't know how to analyze element in $rulename", $mxtoken );
            last SWITCH;
        };
    }

    return 0;
}

## ------------------------------------------------------
#   removeCaseEquivalentBranches :
#        go over the branches from the alternative lists.
#        if 2 branches
#           - consist of exactly 1 symbol
#           - are case-equivalent
#        then remove one of them.
## ------------------------------------------------------
sub removeCaseEquivalentBranches
{
    my ($self, $alternativelists) = @_;

    return $alternativelists if scalar @$alternativelists < 2;

    my $filteredlist    = [];
    my $filtered        = 0;
    my $literal;

    for my $branch (@$alternativelists)
    {
        if ( !exists $branch->{list})
        {
            push @$filteredlist, $branch;
        }
        else
        {
            my $branchlist = $branch->{list};
            if (scalar @$branchlist > 1)
            {
                push @$filteredlist, $branch;
            }
            else
            {
                my $rhs = $branchlist->[0];
                my $matchfound = 0;

                if ( exists $rhs->{type} && $rhs->{type} eq 'literal' )
                {
                    my $newliteral = $rhs->{value};

                    if (defined $literal)
                    {
                        my $tmp1 = uc $literal;
                        my $tmp2 = uc $newliteral;
                        $matchfound = $tmp1 ne "" && $tmp1 eq $tmp2;
                        $filtered = 1 if $matchfound;
                    }
                    else
                    {
                        $literal = $newliteral;
                    }
                }

                push @$filteredlist, $branch if !$matchfound;
            }
        }
    }

    return $alternativelists if !$filtered;

    return $filteredlist;
}

## ------------------------------------------------------
# 'processRightSides' converts a single list of tokens some of which
# are tagged as 'alternative' into (possibly) multiple lists
# each of which is an alternative for a group or rule
## ------------------------------------------------------
sub processRightSides
{
    my ( $self, $rulename, $rhslist, $context ) = @_;

    # symbol lists of alternative branches
    my $alternativelists    = [];
    # current alternative branch
    my $currentlist         = [];
    # number of symbols in current alternative branch
    my $alternativelength   = 0;

    my $metalist            = { comments => [], actions => [] };

    # status tracking for conversion to keyword, lexeme or class
    my $class4list          = { status => 0, value => "" };
    my $class4group         = { status => 0, value => "" };
    my $groupisLexeme       = { status => 0 };
    my $keywordfragment     = { status => 0 };

    # if ( $rulename eq "outer_join_sign")
    # {
    #     printf "found!\n";
    # }

    for my $e (@$rhslist)
    {
        $e = $e->{rhs}          if ref $e eq 'HASH' && exists $e->{rhs}  && !exists $e->{token};
        $e = { token => $e }    if ref $e eq 'HASH' && exists $e->{type} &&  exists $e->{definition};

        my $negation    = retrieveModifier($e, 'negation');
        my $cardinality = retrieveModifier($e, 'cardinality');

        if (exists $e->{comment} || exists $e->{action})
        {
            if (exists $e->{comment} && !$self->testoption('stripallcomments'))
            {
                push @{$metalist->{comments}}, $self->renderComment($rulename, [$e->{comment}]);
                $metalist->{state} = 1;
            }

            if (exists $e->{action} && !$self->testoption('stripactions'))
            {
                push @{$metalist->{actions}}, $self->testoption('embedactions') ? $e->{action} : $self->renderComment($rulename, [$e->{action}]);
                $metalist->{state} = 1;
            }

            ##
            #   skip the rest of processing for comment/action tokens
            ##
            next;
        }

        if (ref $e eq 'HASH' && !exists $e->{token})
        {
            $self->abortWithError( "generic regex rules not supported in rule $rulename", $e ) if exists $e->{type} && $e->{type} eq "regex";
            $self->abortWithError( "INTERNAL: 'e' must be a hash and contain 'token' in rule $rulename", $e );
        }

        my $alternative = retrieveModifier($e, 'alternative');

        if (defined $alternative)
        {
            if (scalar @$currentlist > 0)
            {
                ##
                #   close the current alternative list
                ##
                my $newlist;

                ##
                #   replace a keyword built from lower/upper case character classes by a literal
                ##
                my $keyword = $keywordfragment->{value};
                if ($self->testoption("buildkeywords") && $keywordfragment->{status} == 0 && $keyword =~ /^[a-z]/i)
                {
                    $currentlist = [
                        { type => 'literal', value => $keyword, isLexeme => 1 }
                    ];
                    $newlist = { list => $currentlist, isLexeme => 1 };
                }
                else
                {
                    $newlist = { list => $currentlist };
                    $newlist->{class4list}      = $class4list->{value} if $class4list->{status} != -1;
                    $newlist->{metalist}        = $metalist            if exists $metalist->{state};
                }

                push @$alternativelists, $newlist;
                ##
                #   re-initialize the list state
                ##
                $currentlist        = [];
                $class4list         = { status => 0, value => "" };
                $metalist           = { comments => [], actions => [] };
                $keywordfragment    = { status => 0 };
                $alternativelength  = 0;
            }
        }
        else
        {
            ##
            #   a sequence of literals can't be mapped to a class, so we reset class4list
            ##
            if ($alternativelength > 1)
            {
                $class4group->{status} = -1;
                delete $class4group->{value};
            }
        }

        my $mxelement;

        if (ref $e->{token} eq "")
        {
            ##
            #   translate a G4 subrule into a Marpa subrule
            ##
            my $symbol = $e->{token};
            $mxelement = $self->processSubRule($symbol, $context);
        }
        else
        {
            $self->abortWithError( "can't process group for rule $rulename", $rhslist ) if ref $e ne 'HASH' || !exists $e->{token};
            $mxelement = $self->walktoken($rulename, $e->{token}, $context);
            # ignore embedded comments/actions
            next if exists $mxelement->{type} && $mxelement->{type} eq "ignore";

            my $keywordfragment = $self->isKeywordFragment($rulename, $mxelement);
            $mxelement->{keywordfragment} = $keywordfragment if defined $keywordfragment;
        }

        ##
        #   collect embedded comments in the alternative branch state
        ##
        if (exists $mxelement->{comments})
        {
            push (@{$metalist->{comments}}, @{$mxelement->{comments}});
            $metalist->{state} = 1;
            delete $mxelement->{comments};
            next if scalar keys %$mxelement == 0;
        }

        ##
        #   CAVEAT: retrieve 'isLexeme' from $mxelement
        ##
        my $il = retrieveModifier($mxelement, 'isLexeme');
        $groupisLexeme->{status} = -1 if !defined $il;

        ##
        #   negation should not come from the token
        ##
        mydie "processRightsides : unexpected negation in 'mxelement'" if exists $mxelement->{negation};

        if ( defined $negation )
        {
            $mxelement = $self->negateElement($rulename, $mxelement, $context);
        }

        ##
        #   CAVEAT: use 'cardinality' from $e since $mxtoken
        #           was computed without metainformation.
        ##
        if (defined $cardinality)
        {
            ##
            #   if both the parent and the sub rules are simple, we can propagate the cardinality
            #   to the subrule.
            #   in all other cases we create a new subrule.
            ##
            if ( scalar @$rhslist <= 1 && $self->retagSimpleRule($rulename, $mxelement, $cardinality, $context) )
            {
                ##
                #   if the tagged element is part of an alternative branch (i.e. a branch that has more than one element),
                #   we have to make it into a subrule
                ##
                if (defined $alternative && scalar @$rhslist > 1)
                {
                    $mxelement = $self->createSubRule( $rulename, $mxelement, undef, undef, $context );
                }
            }
            else
            {
                ##
                #   create a subrule for cardinality-tagged element lists
                ##
                $mxelement = $self->createSubRule( $rulename, $mxelement, undef, $cardinality, $context );

                ##
                #   propagate the cardinality to the new subrule
                #   ("?" is wrapped into an 'opt_' rule in 'createSubRule', so it was already consumed).
                #
                #   TODO : check if the '!defined $alternative' clause below should be reinstated
                ##
                # if ( !defined $alternative && $cardinality ne "?" && !$self->retagSimpleRule($rulename, $mxelement, $cardinality, $context, {abortatfirstlevel => 'true'}) )
                if ( $cardinality ne "?" && !$self->retagSimpleRule($rulename, $mxelement, $cardinality, $context, {abortatfirstlevel => 'true'}) )
                {
                    mydie "INTERNAL: no destination for cardinality found in rule '$rulename'" if scalar @$rhslist > 1;
                    $mxelement->{cardinality} = $cardinality if $cardinality ne "?";
                }
            }

            # cardinality-annotated subrules loose lexeme status
            delete $mxelement->{class4list};
            delete $mxelement->{isLexeme};
            $groupisLexeme->{status} = -1;
        }

        mergeClass4List( \%$class4list,  $mxelement );
        mergeClass4List( \%$class4group, $mxelement );
        mergeKeywordFragment( \%$keywordfragment, $mxelement );

        push @$currentlist, $mxelement;
        ++$alternativelength;

        ##
        #   a list of lexemes is not itself a lexeme (unless declared in the 'lexer' grammar).
        ##
        $groupisLexeme->{status} = -1 if $alternativelength > 1;
    }

    ##
    #   replace a keyword built from lower/upper case character classes by a literal.
    #   keyword literals must start with a letter.
    ##
    if ($self->testoption("buildkeywords") && $keywordfragment->{status} == 0 && $keywordfragment->{value} =~ /^[a-z]/i)
    {
        $currentlist = [
            { type => 'literal', value => $keywordfragment->{value}, isLexeme => 1 }
        ];
        $groupisLexeme->{status} = 0;
    }

    ##
    #   append the current list to the alternative list if it has entries.
    ##
    if ( scalar @$currentlist > 0)
    {
        my $newlist = { list => $currentlist };
        $newlist->{class4list}   = $class4list->{value}  if $class4list->{status} != -1;
        $newlist->{isLexeme}     = 1                     if $groupisLexeme->{status} == 0;
        $newlist->{metalist}     = $metalist             if exists $metalist->{state};
        push @$alternativelists, $newlist;
    }

    ##
    #   remove branches that are case-equivalent
    ##
    $alternativelists = $self->removeCaseEquivalentBranches($alternativelists) if $self->testoption('matchcaseinsensitive');

    my $grouplist = { type => 'group', list => $alternativelists };
    # single lists of literals can be tagged as lexemes
    # regular rules with alternative right sides will be tagged as G1
    $grouplist->{class4list} = $class4group->{value} if $class4group->{status} != -1;
    $grouplist->{isLexeme}   = 1                     if $groupisLexeme->{status} == 0;

    return $grouplist;
}

## ------------------------------------------------------
# 'walkgroup' processes the tokens from a parenthesized group
#  or from a complete rule
## ------------------------------------------------------
sub walkgroup
{
    my ($self, $rulename, $tokengroup, $context) = @_;

    $self->abortWithError( "INTERNAL: group is missing 'definition' in rule $rulename", $tokengroup ) if ref $tokengroup ne 'HASH' || !exists $tokengroup->{definition};
    my $definition  = $tokengroup->{definition};
    my $grouplist   = $self->processRightSides( $rulename, $definition, $context );

    return $grouplist;
}

## ------------------------------------------------------
# 'walkrule' processes the 'rightsides' list of a parsed rule
## ------------------------------------------------------
sub walkrule
{
    my ($self, $rulename, $rule, $context) = @_;

    # if ( $rulename eq "outer_join_sign")
    # {
    #     printf "found!\n";
    # }

    my $symboltable = $self->symboltable;
    my $rulestatus  = $symboltable->rulestatus($rulename);

    # test if we traversed this node already
    if ( defined $rulestatus )
    {
        my $mxrule;

        SWITCH: {
            ($rulestatus eq "inprogress") && do {$mxrule = $symboltable->rule( $rulename ); last SWITCH; };
            ($rulestatus eq "done")       && do {$mxrule = $self->getMarpaRule( undef, $rulename ); last SWITCH; };
            ($rulestatus eq "synthetic" && !$self->checkMarpaRuleExists($rulename)) && do
            {
                my $mxrightside = $self->processRightSides( $rulename, $rule->{rightsides}, $context );
                $self->addMarpaRule($rulename, $mxrightside);
                $symboltable->tagrule($rulename, 'done');
                $rulestatus     = $symboltable->rulestatus($rulename);
                $mxrule         = {};
                last SWITCH;
            };
            do { mydie "unexpected rule status $rulestatus in rule $rulename" };
        }

        my $result              = { mxrule => $rulename, rhs => { token => $rulename } };
        $result->{class4list}   = $mxrule->{class4list} if exists $mxrule->{class4list};

        return $result;
    }

    $self->enterLevel($rulename, $context);

    my $mxrightside = {};
    my $rightside   = $rule->{rightsides};
    if (defined $rightside)
    {
        $self->abortWithError( "rhs is not an array ref in $rulename", $rightside ) if ref $rightside ne 'ARRAY';

        $context->{subruleindex}{$rulename}{grammarstate}      = $rule->{grammarstate} if exists $rule->{grammarstate} && $rule->{grammarstate} eq "lexer";
        $context->{subruleindex}{$rulename}{isFragmentOrChild} = 'true'                if exists $rule->{type}         && $rule->{type}         eq "fragment";

        ##
        #  prevent infinite recursion by tagging any symbol
        #  before processing begins with 'inprogress'.
        #  the 'defined($rulestatus)' clause at the top ensures
        #  that we don't pick up a symbol that is already
        #  being processed.
        ##
        $symboltable->tagrule($rulename, 'inprogress');
        $mxrightside = $self->processRightSides( $rulename, $rightside, $context );
        $symboltable->tagrule($rulename, 'done');
    }

    $mxrightside->{grammarstate}       = $rule->{grammarstate} if exists $rule->{grammarstate} && $rule->{grammarstate} eq "lexer";
    $mxrightside->{isFragmentOrChild}  = 'true'                if exists $rule->{type}         && $rule->{type}         eq "fragment";
    if (exists $rule->{redirect})
    {
        $mxrightside->{redirected} = 'true';
        push @{$self->{discarded}}, $rulename;
    }

    $self->addMarpaRule($rulename, $mxrightside);

    $self->exitLevel($rulename, $context);

    return $mxrightside;
}

## ------------------------------------------------------
# 'processSub'  processes a reference to a G4 subrule
## ------------------------------------------------------
sub processSubRule
{
    my ($self, $rulename, $context) = @_;

    my $symboltable = $self->symboltable;
    my $rule        = $symboltable->rule($rulename);

    my $mxrule      = $self->walkrule( $rulename, $rule, $context );

    my $result      = { rule => $rulename, rhs => { token => $rulename } };

    my $keywordfragment = $self->isKeywordFragment($rulename, $mxrule);
    $result->{keywordfragment} = $keywordfragment if defined $keywordfragment;

    return $result;
}

## ------------------------------------------------------
# 'reportUnusedRules'  report all symbol table entries
#                      that are not referred to by
#                      parent rules.
## ------------------------------------------------------
sub printHeaderUnusedRulesReport
{
    printf "\n";
    printf "WARNING: the rules listed below are orphaned. They can't be reached from the start rule:\n";
    printf "=======:\n\n";
    printf  <<'END_OF_SOURCE';
       +----------------------------- rule name
    +--!----------------------------- Lexical (L) or parser rule
 +--!--!----------------------------- Fragment (F) or regular rule
 !  !  !
 V  V  V
END_OF_SOURCE
}

sub reportUnusedRules
{
    my ($self) = @_;

    my $symboltable = $self->symboltable;

    my $status  = 0;
    my @symbols = $symboltable->symbols;

    for my $rulename (sort @symbols)
    {
        my $rule = $symboltable->rule($rulename);
        if (!exists $rule->{generationstatus})
        {
            if (!$status)
            {
                printHeaderUnusedRulesReport();
                $status = 1;
            }

            printf "[%1s][%1s] %s\n",
                (exists $rule->{grammarstate}      && $rule->{grammarstate} =~ /lexer/i) ? "L" : "",
                (exists $rule->{isFragmentOrChild}) ? "F" : "",
                $rulename;
        }
    }

    printf "\n\n" if $status;
}

## ------------------------------------------------------
# 'processRedirectRules'  define Marpa rules for all
#                         G4 rules that are tagged 'redirect'
#                         and are not referred in parent rules
## ------------------------------------------------------
sub processRedirectRules
{
    my ($self) = @_;

    my $symboltable = $self->symboltable;

    my @symbols = $symboltable->symbols;

    for my $rulename (sort @symbols)
    {
        my $rule = $symboltable->rule($rulename);
        if (!exists $rule->{generationstatus} && exists $rule->{redirect})
        {
            $self->walkrule( $rulename, $rule, {level => 0} );
        }
    }
}

## -------------------------------------------------------------------------------------
# 'translateG4Grammar'  create nested Marpa rules for the G4 rules from the symbol table
#                       by doing a depth-first traversal starting with the grammar's
#                       start symbol.
#                       this creates the convex hull of the start symbol collecting all
#                       symbols that can be reached from the start symbol.
#                       'reportUnusedRules' creates a report of all symbols from the
#                       parse tree that are not part of the convex hull.
## -------------------------------------------------------------------------------------
sub translateG4Grammar
{
    my ($self) = @_;

    my $symboltable     = $self->symboltable;

    my $startrule       = $symboltable->startrule;
    my $startrulename   = $startrule->{name};
    $startrule          = $symboltable->rule($startrulename);

    mydie "INTERNAL: start rule $startrulename is missing 'rightsides'" if !exists $startrule->{rightsides};

    $self->walkrule( $startrulename, $startrule, {level => 0} );

    $self->processRedirectRules;
    $self->reportUnusedRules;
}

## ================================================== #
# write the generated Marpa rules to the output file  #
## ================================================== #

sub openOutputFile
{
    my ($self) = @_;

    my $outputfile = $self->{outputfilename};

    if ( $outputfile ne "-" )
    {
        my $outf;
        mydie("cannot open output file $outputfile") unless open( $outf, ">$outputfile" );
        $self->{outf}       = $outf;
        $self->{is_stdout}  = 0;
    }
    else
    {
        $self->{outf}       = *STDOUT;
        $self->{is_stdout}  = 1;
    }
}

sub closeOutputFile
{
    my ($self) = @_;
    close($self->{outf}) if $self->{is_stdout};
}

sub pad
{
    my ($self, $s ) = @_;

    return undef if !defined $s;

    my $len = length($s);
    my $pad = $self->{indent} - $len;

    return $s if $pad < 0;

    return $s . (" " x $pad);
}

sub renderComment
{
    my ($self, $rulename, $comments) = @_;

    mydie "INTERNAL : 'comments' is not an array in rule $rulename" if ref $comments ne 'ARRAY';

    my $result      = [];
    for my $comment (@$comments)
    {
        $comment =~ s/\/\*(.*)\*\//$1/;
        my @commentlist = split '\n', $comment;

        for my $cl (@commentlist)
        {
            $cl =~ s/^\/\/\s*//;
            $cl =~ s/^#\s*//;
            push @$result, "# ${cl}";
        }
    }

    return $result;
}

sub processRedirected
{
    my ($self, $token) = @_;

    mydie "processRedirected : 'token' must be a scalar" if ref $token ne "";

    my $rule = $self->getMarpaRule(undef, $token);

    if ($self->testoption('matchcaseinsensitive') && $self->isKeywordLetter($token, $rule))
    {
        my $value = $rule->{class4list};
        $value = substr($value, 0, 1);
        return { value => "'${value}':i" };
    }

    return { discard => 'true' } if exists $rule->{redirected};

    return { value => $token };
}

sub fragmentEligible2Convert
{
    my ($rule) = @_;

    return 0 if !exists $rule->{class4list};
    my $class4list = $rule->{class4list};

    # replace escaped characters and unicode codepoints with a single character
    $class4list =~ s/\\([^u])/$1/g;
    $class4list =~ s/\\u([0-9a-f]{4,4})/u/ig;

    return length($class4list) > 1;
}

sub writeFragmentAsClass
{
    my ($self, $rulename, $rule, $options ) = @_;

    my $synthclass = { type => "class", value => $rule->{class4list} };
    my $outputline = $self->printRhs( $rulename, $synthclass, {status => 0, delimiter => '|', assignop => '~'} );
    $self->deleteAllSubrules($rulename);

    my $outf = $self->{outf};
    printf $outf "%s\n", $outputline;
}

#
#   translateunicode :  translate unicodes embedded in literals or classes.
#                       die if we are in codepages beyond 00
##
sub translateunicode
{
    my ($self, $rulename, $string ) = @_;

    while ( $string =~ /(\\u([0-9A-F]{4,4}))|(\\u\{([0-9A-F]+)\})/i )
    {
        my $fourmatch   = $2;
        my $bracedmatch = $4;

        SWITCH: {
            (defined $fourmatch) && do {
                mydie "translateunicode : class string $string not in codepage 00 in $rulename" if $fourmatch !~ /00([0-9A-Z][0-9A-Z])/i;
                my $translatedcode = $1;
                $string =~ s/\\u${fourmatch}/\\x${translatedcode}/i;
                last SWITCH;
            };
            (defined $bracedmatch) && do {
                mydie "translateunicode : class string $string not in codepage 00 in $rulename" if $bracedmatch !~ /0*([0-9A-Z]{2,2})/i;
                my $translatedcode = $1;
                $string =~ s/\\u\{${bracedmatch}\}/\\x${translatedcode}/i;
                last SWITCH;
            };
            do {
                mydie "translateunicode : unexpected match";
                last SWITCH;
            };
        }
    }

    return $string;
}

#
#   normalizeClassString :  remove class elements that are redundant when the class is made case-insensitive
#                           return the modified class text as well as an indicator if the class contains letters
##
sub normalizeClassString
{
    my ($self, $classstring ) = @_;

    my $classhash = {};
    my $characterhash = {};

    # strip [/] from classtring
    $classstring =~ s/^\[([^\]]*)\]$/$1/;

    my $result = "";
    my $isalphaclass = 0;
    while ( $classstring ne "" )
    {
        SWITCH: {
        ($classstring =~ /(\\[ux][0-9a-f]+)-(\\[ux][0-9a-f]+)(.*)$/i) && do {
            my $beg = $1;
            my $end = $2;
            $result .= "${1}-${2}";
            $classstring = $3;
            last SWITCH;
        };
        ($classstring =~ /(\\[ux][0-9a-f]{2,4})(.*)$/i) && do {
            my $c = $1;
            $result .= $c;
            $classstring = $2;
            last SWITCH;
        };
        ($classstring =~ /([^-])-([^-])(.*)$/) && do {
            my $beg = $1;
            my $end = $2;
            my $key = "${beg}-${end}";
            if (!exists $classhash->{lc $key} && !exists $classhash->{uc $key})
            {
                $classhash->{$key} = 1;
                $result .= $key;
                $isalphaclass = 1 if $beg =~ /[a-z]/i || $end =~ /[a-z]/i;
            }
            $classstring = $3;
            last SWITCH;
        };
        ($classstring =~ /(\\.)(.*)$/) && do {
            my $c = $1;
            if (!exists $characterhash->{$c})
            {
                $characterhash->{$c} = 1;
                $result .= $c;
            }
            $classstring = $2;
            last SWITCH;
        };
        ($classstring =~ /(.)(.*)$/) && do {
            my $c = $1;
            if (!exists $characterhash->{lc $c} && !exists $characterhash->{uc $c})
            {
                $characterhash->{$c} = 1;
                $result .= $c;
                $isalphaclass = 1 if $c =~ /^[a-z]$/i;
            }
            $classstring = $2;
            last SWITCH;
        };
    }
    }

    return { isalphaclass => $isalphaclass, classstring => $result };
}

sub isAlphaLiteral
{
    my ($self, $literal ) = @_;

    return 0 if $literal !~ /[a-z]/i;

    my $isAlpha = 0;

    while ( $literal ne "" )
    {
        SWITCH: {
            ($literal =~ /(\\.)(.*)$/) && do {
                my $c = $1;
                $literal = $2;
                last SWITCH;
            };
            ($literal =~ /(.)(.*)$/) && do {
                my $c = $1;
                $literal = $2;
                $isAlpha = 1 if $c =~ /^[a-z]$/i;
                last SWITCH;
            };
        }
    }

    return $isAlpha;
}

##
#   computeRhs :
##
sub computeRhs
{
    my ($self, $rulename, $rhs, $options ) = @_;

    # if ($rulename eq "HEXNUMBER_003")
    # {
    #     printf "found!\n";
    # }

    SWITCH:
    {
        (exists $rhs->{type} && $rhs->{type} eq 'negatedclass') && do {
            mydie "computeRhs : 'value' missing in negatedclass $rulename" if !exists $rhs->{value};
            my $value = $rhs->{value};
            $value = $self->translateunicode($rulename, $value);
            $rhs = { value => "[${value}]" };
            last SWITCH;
        };
        (exists $rhs->{deletedafterconversiontoclass}) && do {
            $rhs = { discard => 'true' };
            last SWITCH;
        };
        (exists $rhs->{type} && $rhs->{type} eq 'unsupported') && do {
            mydie $rhs->{msg};
            last SWITCH;
        };
        (exists $rhs->{type} && $rhs->{type} eq 'class') && do {
            my $value = $rhs->{value};
            $value = $self->translateunicode($rulename, $value);
            my $modifier = "";
            if ($self->testoption('matchcaseinsensitive') && $self->isAlphaLiteral($value))
            {
                my $normclass = $self->normalizeClassString($value);
                $value = $normclass->{classstring};
                $modifier = ':ic' if $normclass->{isalphaclass};
            }
            $rhs = { value => "[${value}]${modifier}" };
            last SWITCH;
        };
        (exists $rhs->{type} && $rhs->{type} eq 'literal') && do {
            my $literal = $rhs->{value};
            $literal = $self->translateunicode($rulename, $literal);
            $literal =  ($literal eq "\\'") ? "[']" : "'${literal}'";
            if ($self->testoption('matchcaseinsensitive') && $self->isAlphaLiteral($literal))
            {
                $literal = lc $literal;
                $literal .= ':i';
            }
            $rhs = { value => $literal };
            last SWITCH;
        };
        (exists $rhs->{type} && $rhs->{type} eq 'action') && do {
            push @{$options->{comments}}, " # Action: " . $rhs->{token}{action};
            $rhs = { discard => 'true' };
            last SWITCH;
        };
        (exists $rhs->{rhs}) && do {
            $rhs = $rhs->{rhs};
            mydie "computeRhs: scalar 'token' missing in rhs" if !exists $rhs->{token} || ref $rhs->{token} ne "";
            $rhs = $self->processRedirected($rhs->{token});
            last SWITCH;
        };
        (exists $rhs->{token}) && do {
            $rhs = $self->processRedirected($rhs->{token});
            last SWITCH;
        };
        (exists $rhs->{comments}) && do {
            my $cl = $self->renderComment($rulename, $rhs->{comments});
            push (@{$options->{comments}}, @$cl );
            $rhs = { discard => 'true' };
            last SWITCH;
        };
        do {
            $self->abortWithError( "computeRhs : don't know how to process rhs for $rulename, modify this rule to make it convertible", $rhs  );
        };
    }

    return $rhs;
}

##
#   printRhs :  print a single right hand clause (alternative) of a rule.
#               depending on $option->{status} format the clause :
#               0 : prefix the rule name and use '::=' or '~' as operator
#               1 : start an alternative branch
#               2 : add a clause to a branch
##
sub printRhs
{
    my ( $self, $rulename, $rule, $options ) = @_;

    mydie "printRhs: 'status' not defined for rule $rulename" if !exists $options->{status};

    my $status          = $options->{status};
    my $rhs             = $self->computeRhs($rulename, $rule, $options);

    return "" if exists $rhs->{discard};

    mydie "'options' not well-defined" if ref $options ne 'HASH' || !exists $options->{delimiter};

    my $delimiter       = $options->{delimiter};

    my $cardinality     = "";
    $cardinality        = $options->{cardinality} if exists $options->{cardinality};
    $cardinality        =~ s/([+*])\?/$1/ if $cardinality =~ /[+*]\?/ && $self->testoption('shiftlazytogreedy');
    mydie sprintf "lazy quantifier %s in rule %s not supported by Marpa", $cardinality, $rulename if $cardinality =~ /[+*]\?/;

    # if ($rulename eq "local_xmlindex_clause_001")
    # {
    #     printf "found!\n";
    # }

    my $definitionop    = "::=";
    $definitionop       = $options->{assignop} if exists $options->{assignop};

    my $result;

    # process optional rules
    if ( defined $cardinality && $cardinality eq "?")
    {
        $result = sprintf "%s %-3s %s%s\n", $self->pad($rulename), $definitionop, "", "";
        $cardinality = "";
    }

    SWITCH:
    {
        ($status == 0) && do {
            $result .= sprintf "%s %-3s %s%s", $self->pad($rulename), $definitionop, $rhs->{value}, $cardinality;
            last SWITCH;
        };
        ($status == 1) && do {
            $result .= sprintf "%s %-3s %s%s", $self->pad(""), $delimiter, $rhs->{value}, $cardinality;
            last SWITCH;
        };
        ($status == 2) && do {
            $result .= sprintf " %s%s", $rhs->{value}, $cardinality;
            last SWITCH;
        };
        do {
            mydie "printRhs : illegal status";
        };
    }

    return $result;
}

##
#   writeMarpaRuleList :    print all alternative branches of a rule
##
sub writeMarpaRuleList
{
    my ( $self, $rulename, $rule, $options ) = @_;

    # if ($rulename eq "SAFECODEPOINT")
    # {
    #     printf "found!\n";
    # }

    $options->{status}  = 0;

    my $outf = $self->{outf};

    mydie "writeMarpaRuleList : 'list' missing from 'rule' in $rulename" if !exists $rule->{list};

    my $list = $rule->{list};
    my $actiontext;

    for my $rulelist (@$list)
    {
        mydie "writeMarpaRuleList : 'list' missing from 'rulelist' in $rulename" if !exists $rulelist->{list};

        if (exists $rulelist->{metalist})
        {
            my $metalist = $rulelist->{metalist};

            for my $cl (@{$metalist->{comments}})
            {
                $cl = $cl->[0] if ref $cl eq 'ARRAY';
                printf $outf "%s\n", $cl;
            }
            if (exists $metalist->{actions})
            {
                if (!$self->testoption('embedactions'))
                {
                    for my $cl (@{$metalist->{actions}})
                    {
                        $cl = $cl->[0] if ref $cl eq 'ARRAY';
                        printf $outf "%s\n", $cl;
                    }
                }
                else
                {
                    $actiontext = "";
                    for my $cl (@{$metalist->{actions}})
                    {
                        $cl = $cl->[0] if ref $cl eq 'ARRAY';
                        $actiontext .= $cl;
                    }
                }
            }
        }

        my $outputline  = "";
        my $linelen     = 0;

        for my $rhs (@{$rulelist->{list}})
        {
            my $cardinality = $rhs->{cardinality} if exists $rhs->{cardinality};

            $options->{delimiter}   = "|";
            $options->{cardinality} = $cardinality if defined $cardinality;

            if (exists $rhs->{comments})
            {
                my $cl = $rhs->{comments};
                mydie "TODO : comments";
            }

            my $nextclause;

            SWITCH:
            {
                (exists $rhs->{type} && $rhs->{type} eq "group" && exists $rhs->{list}) && do {
                    if ( exists $rhs->{class4list})
                    {
                        $nextclause = $self->printRhs( $rulename, $rhs, $options );
                        $options->{status} = 2;
                    }
                    else
                    {
                        mydie "writeMarpaRuleList : unexpected embedded 'list'";
                    }
                    last SWITCH;
                };
                do {
                    $nextclause = $self->printRhs( $rulename, $rhs, $options );
                    $options->{status} = 2;
                    last SWITCH;
                };
            }

            $options->{delimiter}= "|";

            if ($linelen + length($nextclause) > $self->{indent} + 3 + 125)
            {
                $outputline .= "\n" . (' ' x $self->{indent}) . (' ' x 3) . ' ' . $nextclause;
                $linelen = $self->{indent} + 3 + length($nextclause);
            }
            else
            {
                $outputline .= $nextclause;
                $linelen += length($nextclause);
            }
        }

        if (defined $actiontext)
        {
            my $padlen = $self->{indent} + 40 - length($outputline);
            $padlen = 1 if $padlen < 0;
            $outputline .= ' ' x $padlen . "action => ${actiontext}";
            $actiontext = undef;
        }

        $options->{status} = 1;
        printf $outf "%s\n", $outputline if length($outputline) > 0;
        $linelen = 0;
    }

    if (exists $options->{comments})
    {
        for my $cl (@{$options->{comments}})
        {
            printf $outf "%s\n", $cl;
        }
        delete $options->{comments};
    }
}

##
#   writeMarpaRule :    print a complute rule :
#                       - rule name + 1st branch
#                       - all subsequent branches
##
sub writeMarpaRule
{
    my ($self, $rulename ) = @_;

    $self->dumpMarpaRule($rulename) if $self->{verbosity};

    $self->tagMarpaRule($rulename);

    # if ( $rulename eq "IDENTIFIER")
    # {
    #     printf "found!\n";
    # }

    my $rule                = $self->getMarpaRule(undef, $rulename);

    my $cardinality         = $rule->{cardinality}      if exists $rule->{cardinality};

    my $options             = { delimiter => "", status => 0 };
    $options->{cardinality} = $cardinality      if defined $cardinality;
    $options->{assignop}    = '~'               if exists $rule->{isLexeme} || exists $rule->{isFragmentOrChild} || exists $rule->{grammarstate};

    my $outputline          = "";
    my $outf                = $self->{outf};

    my $printoutputcreated  = 1;

    SWITCH:
    {
        ##
        #   discard rules that implement a case-insensitive single-letter literal
        #   if we are building case-insensitive keyword literals.
        ##
        ($self->testoption('buildkeywords') && $self->isKeywordLetter($rulename, $rule)) && do {
            $self->deleteMarpaRule($rulename);
            $printoutputcreated = 0;
            last SWITCH;
        };
        #(exists $rule->{isFragmentOrChild} && $self->testoption('fragment2class') && fragmentEligible2Convert($rule)) && do {
        ##
        #   conditionally translate eligible fragments to classes if the fragment is not tagged with a '?' quantifier
        ##
        ($self->testoption('fragment2class') && $rulename !~ /^opt_/ && fragmentEligible2Convert($rule)) && do {
            $self->writeFragmentAsClass($rulename, $rule, $options );
            last SWITCH;
        };
        ##
        #   print a rule with alternative branches
        ##
        (exists $rule->{list}) && do {
            $self->writeMarpaRuleList($rulename, $rule, $options );
            last SWITCH;
        };
        ##
        #   print a simple rule
        ##
        do {
            $outputline = $self->printRhs( $rulename, $rule, $options );
            $printoutputcreated = 0 if !length($outputline);
            last SWITCH;
        };
    }

    printf $outf "%s\n", $outputline if length($outputline) > 0;

    return $printoutputcreated;
}

sub dumpMarpaRule
{
    my ( $self, $rulename ) = @_;

    my $marparule = $self->getMarpaRule(undef, $rulename);
    $self->dumpStructure( sprintf("=== %s\n", $rulename), $marparule);
}

##
# 'computeIndentation' : compute the maximum rulename length
##
sub computeIndentation
{
    my ($self) = @_;

    my $symboltable = $self->{symboltable};
    my $ruletable   = $symboltable->ruletable;
    my $subrules    = $self->{subrules};

    my $indent = -1;
    for my $rule (@$ruletable)
    {
        next if !defined $rule || !exists $rule->{name} || !exists $rule->{generationstatus};
        my $rulename    = $rule->{name};
        $indent         = length($rulename) if length($rulename) > $indent;
        next if !exists $subrules->{$rulename};
        for my $subrulename (@{$subrules->{$rulename}})
        {
            $indent = length($subrulename) if length($subrulename) > $indent;
        }
    }

    mydie "INTERNAL: couldn't compute rhs indentation" if $indent == -1;

    $self->{indent} = $indent;
}

sub generateGenericOptions
{
    my ($self) = @_;
    my $outf = $self->{outf};
    printf $outf "%s\n\n", "lexeme default = latm => 1";
}

sub generateStartClause
{
    my ($self) = @_;

    my $startrule = $self->symboltable->startrule;
    return if !defined $startrule;

    my $outf = $self->{outf};

    printf $outf "%s %-3s %s\n\n", $self->pad(":start"), "::=", $startrule->{name};
}

sub convertRedirectToDiscard
{
    my ($self) = @_;

    return if !exists $self->{discarded} || ref $self->{discarded} ne 'ARRAY' || scalar @{$self->{discarded}} < 1;

    my $outf = $self->{outf};

    printf $outf "# ---\n";
    printf $outf "# Discard rule from redirect options :\n";
    printf $outf "%s %-3s %s\n", $self->pad(":discard"), "~", "<discarded redirects>";

    my $lhs         = "<discarded redirects>";
    my $delimiter   = "~";
    for my $rulename (@{$self->{discarded}})
    {
        printf $outf "%s %-3s %s\n", $self->pad($lhs), $delimiter, $rulename;
        $lhs        = "";
        $delimiter  = "|";
    }

    printf $outf "# ---\n";
}

## -------------------------------------------------------------------------------------
# 'writeMarpaGrammar'   create an output file with the collected rules in Marpa syntax.
#                       the sequence of rules is identical to that from the original
#                       input files. Subrules are aligned with parent rules.
## -------------------------------------------------------------------------------------
sub writeMarpaGrammar
{
    my ($self) = @_;

    my $symboltable     = $self->{symboltable};
    my $startrule       = $symboltable->startrule;
    my $startrulename   = $startrule->{name};

    my $ruletable       = $symboltable->ruletable;
    my $subrules        = $self->{subrules};

    $self->computeIndentation;

    $self->openOutputFile;

    $self->generateGenericOptions;
    $self->generateStartClause;

    # create a ':discard' rule at the top of the output file
    # from the rules tagged 'redirect'
    $self->convertRedirectToDiscard;

    my $outf = $self->{outf};

    ##
    #   print rules in the order of the input file
    ##
    my $status = 0;
    my $subrulestatus = 0;
    my $rulegeneratedoutput = 1;

    for my $rule (@$ruletable)
    {
        if (exists $rule->{comment} && !$self->testoption('stripallcomments'))
        {
            my $comment = $rule->{comment};
            $comment = [$comment] if ref $comment ne 'ARRAY';
            my $cl = $self->renderComment("grammar", $comment);
            for my $s (@$cl)
            {
                printf $outf "%s\n", $s;
            }
        }

        next if !defined $rule || !exists $rule->{name} || !exists $rule->{generationstatus};

        my $rulename = $rule->{name};

        if ( !$status )
        {
            printf "WARNING : first rule '%s' is not startrule '%s'\n", $rulename, $startrulename if $rulename ne $startrulename;
            $status = 1;
        }

        ##
        #   create a block of text for a rule with its subrules
        ##
        printf $outf "\n" if exists $subrules->{$rulename} && !$subrulestatus && $rulegeneratedoutput;
        $subrulestatus = 0;

        $rulegeneratedoutput = $self->writeMarpaRule($rulename);

        ##
        #   print the generated subrules immediately after the parent rule
        ##
        if (exists $subrules->{$rulename})
        {
            my $subrulegeneratedoutput = 0;

            for my $subrulename (@{$subrules->{$rulename}})
            {
                $subrulegeneratedoutput += $self->writeMarpaRule($subrulename);
            }

            printf $outf "\n" if $subrulegeneratedoutput;
            $subrulestatus = 1;
        }
    }

    ##
    #   print the rest (if any)
    ##
    for my $rulename (sort keys %{$self->{rules}})
    {
        my $g4rule      = $symboltable->rule($rulename);
        next if !exists $g4rule->{generationstatus};

        my $marparule   = $self->getMarpaRule(undef, $rulename);
        next if exists $marparule->{status};

        printf "%s\n", $rulename if $self->{verbosity};
        $self->writeMarpaRule($rulename);
    }

    $self->closeOutputFile;
}

# --------------------------------------------------- #
# driver                                              #
# --------------------------------------------------- #

sub generate
{
    my ($self, $symboltable) = @_;

    $self->{symboltable}  = $symboltable;

    $self->translateG4Grammar;
    $self->dumpStructure("Rules", $self->{rules}) if $self->{verbosity} > 1;
    $self->writeMarpaGrammar;
}

1;

# ABSTRACT: translate parsed antlr4 rules to Marpa2 syntax

=head1 SYNOPSIS
 use MarpaX::G4::MarpaGen;
 my $generator = new MarpaX::MarpaGen;
 $generator->generate($symboltable);
=head1 DESCRIPTION
Translate the rules from the symbol table created from the imported ANTLR4 grammar
into Marpa syntax and write them to output.

use MarpaX::Symboltable;
my $symboltable = new MarpaX::Symboltable;

my $grammartext = readFile($infile);
my $data = MarpaX::G4::parse_rules($grammartext);
$symboltable->importParseTree($data);
$symboltable->validateSymbolTable();

my $generator = new MarpaX::MarpaGen;

$generator->stripallcomments    if exists $options->{c};
$generator->embedactions        if exists $options->{e};
$generator->fragment2class      if exists $options->{f};
$generator->shiftlazytogreedy   if exists $options->{g};
$generator->buildkeywords       if exists $options->{k};
$generator->stripactions        if exists $options->{p};
$generator->setVerbosity(2)     if exists $options->{t};
$generator->matchcaseinsensitive        if exists $options->{u} || exists $options->{k};

my $outputfile  = '-';
$outputfile     = $options->{o} if exists $options->{o};
$generator->setoutputfile($outputfile);

$generator->generate($symboltable);
=cut
