# ----------------------------------------------------------------------------------------------------- #
# MarpaX::Symboltable                                                                                   #
#                                                                                                       #
# manage a symbol table with rules parsed from an antlr4 grammar.                                       #
#                                                                                                       #
# ----------------------------------------------------------------------------------------------------- #

package MarpaX::G4::Symboltable;

use strict;
use warnings FATAL => 'all';
use Data::Dumper;
use MarpaX::G4::Parser;

sub new
{
    my $invocant            = shift;
    my $class               = ref($invocant) || $invocant;  # Object or class name
    my $self                = {};                           # initiate our handy hashref
    bless($self,$class);                                    # make it usable

    $self->{symboltable}    = {};
    $self->{startrule}      = undef;
    $self->{currentidx}     = -1;
    $self->{ruletable}      = [];

    return $self;
}

sub symbols     { my ($self) = @_; return keys %{$self->{symboltable}}; }
sub startrule   { my ($self) = @_; return $self->{startrule};           }
sub ruletable   { my ($self) = @_; return $self->{ruletable};           }

sub setStartRule
{
    my ($self, $rulename) = @_;
    die "can't set non-existent rule $rulename as start rule" if !exists $self->{symboltable}{$rulename};
    my $symbol = $self->{symboltable}{$rulename};
    $self->{startrule} = { name => $rulename, index => $symbol->{index} };
}

sub rule
{
    my ($self, $rulename) = @_;
    $self->addEOF() if $rulename eq "EOF" && !exists $self->{symboltable}{$rulename};
    return undef if !defined $rulename || !exists $self->{symboltable}{$rulename};
    return $self->{symboltable}{$rulename};
}

sub tagrule
{
    my ($self, $rulename, $status) = @_;
    die "trying to tag nonexistent rule '$rulename'" if !exists $self->{symboltable}{$rulename};
    my $symbol = $self->{symboltable}{$rulename};
    $symbol->{generationstatus} = defined($status) ? $status : 'todo';
}

##
#   create a synthetic 'EOF' token, so that the grammar won't fail.
##
sub addEOF
{
    my ($self) = @_;

    $self->addRule( -1,
        {
            name             => 'EOF',
            type             => 'fragment',
            generationstatus => 'synthetic',
            'rightsides' => [
                {
                    'rhs' => {
                        'token' => {
                            'value' => '\z',
                            'type' => 'literal'
                        }
                    }
                }
            ],
        });
}

sub rulestatus
{
    my ($self, $rulename, $status) = @_;

    $self->addEOF() if $rulename eq "EOF" && !exists $self->{symboltable}{$rulename};

    die "trying to query nonexistent rule '$rulename'" if !exists $self->{symboltable}{$rulename};
    my $symbol = $self->{symboltable}{$rulename};
    return exists $symbol->{generationstatus} ? $symbol->{generationstatus} : undef;
}

## -----------
#   import the parse tree into the symbol table
## -----------
sub importParseTree
{
    my ($self, $tree) = @_;

    die "parse tree must be an array of rules" if ref($tree) ne "ARRAY";
    my $ruleindex = $self->{currentidx};

    for my $rule (@$tree)
    {
        ++$ruleindex;
        die "rule[$ruleindex] is not a hash" if ref($rule) ne "HASH";

        SWITCH: {
            (exists $rule->{name}) && do {
                my $name = $rule->{name};
                # printf "rule[$ruleindex] : %s\n", $name;
                $self->addRule($ruleindex, $rule);
                $self->{startrule} = { name => $name, index => $ruleindex } if !defined $self->{startrule};
                last SWITCH;
            };
            (exists $rule->{grammarspec}) && do {
                # printf "rule[$ruleindex] : grammar %s\n", $rule->{grammarspec};
                last SWITCH;
            };
            (exists $rule->{comment}) && do {
                # printf "rule[$ruleindex] : comment\n";
                $self->addComment($ruleindex, $rule);
                last SWITCH;
            };
            do {
                die "rule[$ruleindex] : can't process";
                last SWITCH;
            };
        }
    }

    $self->{currentidx} = $ruleindex;
}

sub addRule
{
    my ($self, $ruleindex, $rule) = @_;

    my $name        = $rule->{name};
    my $symboltable = \%{$self->{symboltable}};

    SWITCH: {
        (exists  $rule->{rightsides}) && do {
            die "$name is a duplicate rule" if exists $symboltable->{$name};
            $rule->{index}          = $ruleindex;
            $symboltable->{$name}   = $rule;
            last SWITCH;
        };
        do {
            die "can't import rule[$ruleindex] : $name";
            last SWITCH;
        };
    }

    # add the rule to the index-based lookup table if it is not a synthetic rule.
    $self->{ruletable}->[$ruleindex] = $rule if $ruleindex != -1;
}

sub addComment
{
    my ($self, $ruleindex, $rule) = @_;
    $self->{ruletable}->[$ruleindex] = $rule;
}

## -----------
#   recursively walk the symbol table to verify consistency
## -----------

sub walkgroup
{
    my ($rulename, $tokengroup) = @_;

    my $namelist = [];

    my $definition = $tokengroup->{definition};
    for my $e (@$definition)
    {
        if (ref $e->{token} eq "")
        {
            push @$namelist, $e->{token};
        }
        else
        {
            if (ref $e eq "HASH" && exists $e->{token})
            {
                my $sr = walktoken($rulename, $e->{token});
                push (@$namelist, @$sr);
            }
            else
            {
                $Data::Dumper::Indent = 1;
                print Dumper($tokengroup);
                die "can't process group for rule $rulename";
            }
        }
    }

    return $namelist;
}

sub walktoken
{
    my ($rulename, $token) = @_;

    my $namelist = [];

    SWITCH:
    {
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "rulegroup") && do {
            my $sr = walkgroup($rulename, $token->{token});
            push (@$namelist, @$sr);
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "tokengroup") && do {
            my $sr = walkgroup($rulename, $token->{token});
            push (@$namelist, @$sr);
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{token}) && do {
            my $nestedtoken = $token->{token};
            my $sr = walktoken($rulename, $nestedtoken);
            push (@$namelist, @$sr);
            last SWITCH;
        };
        (ref $token eq "") && do {
            push @$namelist, $token;
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "literal") && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "class") && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "regex") && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "range") && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{type} && $token->{type} eq "value") && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{comment}) && do {
            last SWITCH;
        };
        (ref $token eq "HASH" && exists $token->{action}) && do {
            last SWITCH;
        };
        do {
            $Data::Dumper::Indent = 1;
            print Dumper($token);
            die "can't process token for rule $rulename";
            last SWITCH;
        };
    }

    return $namelist;
}

sub walknonterminal
{
    my ( $rulename, $nonterminal ) = @_;

    my $namelist = [];

    SWITCH:
    {
        (exists $nonterminal->{rhs}) && do {
            my $rhs = $nonterminal->{rhs};
            my $sr = walktoken($rulename, $rhs);
            push (@$namelist, @$sr);
            last SWITCH;
        };
        do {
            $Data::Dumper::Indent = 1;
            print Dumper($nonterminal);
            die "can't process nonterminal for rule $rulename";
            last SWITCH;
        };
    }

    return $namelist;
}

sub walksubrule
{
    my ($rulename, $rule) = @_;

    if (ref $rule ne "HASH" || !exists $rule->{rightsides})
    {
        $Data::Dumper::Indent = 1;
        print Dumper($rule);
        die "rule '$rulename' is not a hash";
    }

    my $rhs = $rule->{rightsides};

    return [] if !defined $rhs;

    if (ref $rhs ne "ARRAY")
    {
        $Data::Dumper::Indent = 1;
        print Dumper($rhs);
        die "'rhs' is not an array ref in '$rulename'";
    }

    my $namelist = [];

    for my $r (@$rhs)
    {
        my $sr = walknonterminal($rulename, $r);
        push (@$namelist, @$sr);
    }

    return $namelist;
}

sub joinReferences
{
    my ($sr) = @_;

    my $temp    = {};
    my $result  = "";
    my $delim   = "";

    for my $s (@$sr)
    {
        if (!exists $temp->{$s})
        {
            $temp->{$s} = 1;
            my $len = 16 - length($s);
            my $ts = $s;
            if ($len < 0)
            {
                $len = 0;
                $ts = substr($ts, 0, 16);
            }
            my $pad = "";
            $pad = ' ' x $len if $len > 0;
            $result .= $delim . $ts . $pad;
            $delim   = " ";
        }
    }

    return $result;
}

sub verifySymbolNames
{
    my ($self, $rulename, $symbolnames ) = @_;

    my $symboltable = \%{$self->{symboltable}};

    for my $sn (@$symbolnames)
    {
        if (!exists $symboltable->{$sn})
        {
            printf "[%-1s][%-45s][%-2s] missing from symbol table : %s\n", "", $rulename, "", $sn;
        }
    }
}

sub validateSymbolTable
{
    my ($self) = @_;

    my $symboltable = \%{$self->{symboltable}};

    printf "===\n=== Composite Rules\n===\n\n";
    printf  <<'END_OF_SOURCE';
    +-------------------------------------------------------- rule name
 +--!-------------------------------------------------------- Fragment (F), Lexeme (L) or regular rule
 !  !                                              +--------- redirected (->) or contributing rule
 !  !                                              !   +----- number of rule references
 !  !                                              !   !   +- list of rule references
 !  !                                              !   !   !
 V  V                                              V   V   V
END_OF_SOURCE

    for my $name (sort keys %$symboltable)
    {
        my $rule = $symboltable->{$name};

        SWITCH:
        {
            (exists $rule->{name}) && do
            {
                my $name             = $rule->{name};
                # if ($name eq "alter_table_properties")
                # {
                #     printf "found!\n";
                # }
                my $symbolreferences = walksubrule($name, $rule);

                if (scalar @$symbolreferences > 0)
                {
                    my $strReferences = joinReferences($symbolreferences);
                    my $type = "";
                    $type = "L" if exists $rule->{isLexeme} || (exists $rule->{grammarstate} && $rule->{grammarstate} eq "lexer");
                    $type = "F" if exists $rule->{type} && $rule->{type} eq "fragment";
                    printf "[%-1s][%-45s][%-2s][%2d] %s\n", $type, $name, (exists $rule->{redirect}) ? "->" : "", scalar @$symbolreferences, $strReferences;
                    $self->verifySymbolNames( $name, $symbolreferences );
                }
                last SWITCH;
            };
            do
            {
                die "can't process rule";
                last SWITCH;
            };
        }
    }

    printf "\n===\n=== Basic Rules\n===\n\n";
    printf  <<'END_OF_SOURCE';
    +-------------------------------------------------------- rule name
 +--!-------------------------------------------------------- Fragment (F), Lexeme (L) or regular rule
 !  !                                              +--------- redirected (->) or contributing rule
 !  !                                              !   +----- n/a
 !  !                                              !   !
 V  V                                              V   V
END_OF_SOURCE

    for my $name (sort keys %$symboltable)
    {
        my $rule = $symboltable->{$name};

        SWITCH:
        {
            (exists $rule->{name}) && do
            {
                my $name                = $rule->{name};
                my $symbolreferences    = walksubrule($name, $rule);

                if ($name eq "TILDE_OPERATOR_PART")
                {
                    printf "found!\n";
                }
                if (scalar @$symbolreferences == 0)
                {
                    my $type = "";
                    $type = "L" if exists $rule->{isLexeme} || (exists $rule->{grammarstate} && $rule->{grammarstate} eq "lexer");
                    $type = "F" if exists $rule->{type} && $rule->{type} eq "fragment";
                    printf "[%-1s][%-45s][%-2s][%2s] %s\n", $type, $name, (exists $rule->{redirect}) ? "->" : "", "", "";
                }
                last SWITCH;
            };
            do
            {
                die "can't process rule";
                last SWITCH;
            };
        }
    }

    printf "\n";
}

1;

# ABSTRACT: manage symbol table of rules parsed from antlr grammar

=head1 SYNOPSIS
use MarpaX::G4::Symboltable;
my $symboltable = new MarpaX::G4::Symboltable;

my $grammartext = readFile($infile);
my $data = MarpaX::G4::Parser::parse_rules($grammartext);
$symboltable->importParseTree($data);
$symboltable->validateSymbolTable();

=head1 DESCRIPTION
Import the rules from the ANTLR4 parse tree into a symbol table.
'validateSymbolTable' does a depth-first tree traversal of the symbol table to produce a report of productions and terminal symbols.
=cut

