# ----------------------------------------------------------------------------------------------------- #
# MarpaX::MarpaGen                                                                                      #
#                                                                                                       #
# translate the parsed antlr4 rules to Marpa::R2 syntax.                                                #
#                                                                                                       #
# V 0.9.6                                                                                               #
# ----------------------------------------------------------------------------------------------------- #

package MarpaX::G4;

use strict;
use warnings FATAL => 'all';

use Data::Dumper;

use MarpaX::G4::Parser;
use MarpaX::G4::Symboltable;
use MarpaX::G4::MarpaGen;

our $VERSION = '0.9.6';
our $optstr  = 'cdefghiko:prs:tuv';

sub new
{
    my $invocant    = shift;
    my $class       = ref($invocant) || $invocant;  # Object or class name
    my $self        = {};                           # initiate our handy hashref
    bless($self,$class);                            # make it usable

    return $self;
}

sub printHelpScreen
{
    my ($scriptName) = @_;

    my $usage = "Usage: $scriptName [-cdefghikprtuv] [-s <startsymbol>] [-o <outputfile>] <file1>[ <file2> ...]";

    my @helptext = (
        "$scriptName - Antlr4 to MarpaX converter"
        ,""
        ,"$usage"
        ,""
        ,"-c                  strip all comments and actions (except inline actions)"
        ,"-d                  dump the parse tree"
        ,"-e                  embed the g4 inline actions into the marpa grammar"
        ,"                    (default : prefix as comments ahead of the rule)"
        ,"-f                  convert fragments to classes where applicable"
        ,"-g                  convert lazy to greedy quantifiers"
        ,"                    (CAVEAT: this might change the grammar semantics)"
        ,"-h                  print this help and exit"
        ,"-i                  ignore redirects (don't discard redirected rules)"
        ,"-k                  build case-insensitive keywords from single-letter fragments"
        ,"-o <outputfile>     specify the output file. default is stdout"
        ,"-p                  strip inline comments and actions"
        ,"-r                  verify the consistency of the symbol table"
        ,"-s <startsymbol>    specify the start rule of the grammar"
        ,"                    (default: 1st rule of the 1st input file)"
        ,"-t                  trace the grammar generation"
        ,"-u                  make literals and classes case-insensitive"
        ,"-v                  dump the symbol table"
    );

    map { print $_ . "\n"; } @helptext;

    exit 0;
}

##
#   readFile: swallow an entire input file into a string
##
sub readFile
{
    my ($infile) = @_;

    my $inph = *STDIN if $infile eq '-';
    open($inph, "< $infile") || die "can't open input file $infile : $!" if $infile ne '-';

    my $file_text = do
    {
        local $/;
        <$inph>;
    };

    close($inph) if $infile ne '-';

    return $file_text;
}

##
#   processSymboltable: generate the output grammar from the symbol table
##
sub processSymboltable
{
    my ($self, $symboltable, $options ) = @_;

    if ( exists $options->{v} )
    {
        $Data::Dumper::Indent = 1;
        print Dumper($symboltable);
    }

    $symboltable->setStartRule($options->{s}) if exists $options->{s};
    $symboltable->validateSymbolTable()       if exists $options->{r};

    my $generator = new MarpaX::G4::MarpaGen;

    $generator->stripallcomments     if exists $options->{c};
    $generator->embedactions         if exists $options->{e};
    $generator->fragment2class       if exists $options->{f};
    $generator->shiftlazytogreedy    if exists $options->{g};
    $generator->buildkeywords        if exists $options->{k};
    $generator->stripactions         if exists $options->{p};
    $generator->setVerbosity(2)      if exists $options->{t};
    $generator->matchcaseinsensitive if exists $options->{u} || exists $options->{k};

    my $outputfile  = '-';
    $outputfile     = $options->{o}  if exists $options->{o};
    $generator->setoutputfile($outputfile);

    $generator->generate($symboltable);
}

##
#   translatestring: parse the antlr4 input grammar from '$grammartext',
#                    generate the Marpa::R2 output grammar.
##
sub translatestring
{
    my ( $self, $grammartext, $options ) = @_;

    my $parser = new MarpaX::G4::Parser;
    $parser->enabletrace     if exists $options->{t};
    $parser->ignoreredirect  if exists $options->{i};

    my $symboltable = new MarpaX::G4::Symboltable;

    my $data = $parser->parse($grammartext);
    if ( exists $options->{d} )
    {
        printf "===\n=== Parsed Hashtable\n===\n";
        $Data::Dumper::Indent = 2;
        print Dumper($data);
    }
    $symboltable->importParseTree($data);

    $self->processSymboltable($symboltable, $options);
}

##
#   translatefiles:  parse the antlr4 input grammar from the input file(s),
#                    generate the Marpa::R2 output grammar.
##
sub translatefiles
{
    my ( $self, $inputfiles, $options ) = @_;

    my $parser = new MarpaX::G4::Parser;
    $parser->enabletrace     if exists $options->{t};
    $parser->ignoreredirect  if exists $options->{i};

    my $symboltable = new MarpaX::G4::Symboltable;

    while (scalar @$inputfiles)
    {
        my $infile = shift @$inputfiles;
        my $grammartext = readFile($infile);
        my $data = $parser->parse($grammartext);
        if ( exists $options->{d} )
        {
            $Data::Dumper::Indent = 2;
            print Dumper($data);
        }
        $symboltable->importParseTree($data);
    }

    $self->processSymboltable($symboltable, $options);
}

1;

# ABSTRACT: translate parsed antlr4 rules to Marpa2 syntax

=head1 SYNOPSIS
 use MarpaX::G4;

=head1 DESCRIPTION
Translate the rules from the symbol table created from the imported ANTLR4 grammar
into Marpa syntax and write them to output.

=cut
