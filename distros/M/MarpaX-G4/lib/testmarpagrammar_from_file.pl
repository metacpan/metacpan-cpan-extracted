#!/usr/bin/perl -w
# #################################################################################### #
# Program   testmarpagrammarfromfile                                                   #
#                                                                                      #
# Author    Axel Zuber                                                                 #
# Created   29.05.2022                                                                 #
#                                                                                      #
# Description   read a Marpa grammar and an input file                                 #
#               apply the grammar to the input and dump the parse tree                 #
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


# ------------------------------------------------------------------------------------ #
# Subroutines                                                                          #
# ------------------------------------------------------------------------------------ #

package MarpaX::Test;
use strict;
use warnings FATAL => 'all';

use strict;

use lib 'lib';
use Data::Dumper;
use Getopt::Std;
use Marpa::R2;
use Data::Dump;

# ------------------------------------------------------------------------------------ #
# Subroutines                                                                          #
# ------------------------------------------------------------------------------------ #

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

# ------------------------------------------------------------------------------------ #
# MAIN                                                                                 #
# ------------------------------------------------------------------------------------ #

my $usage = "testmarpagrammar_from_file -g grammarfile <inputfile>";
my $optStr  = 'g:v';
my $options = {};

die 'Invalid option(s) given' if !getopts( "$optStr", $options );

die "$usage" if !exists $options->{g} || scalar @ARGV < 1;

my $grammartext = readFile($options->{g});

my $dsl = <<"END_OF_DSL";
    ${grammartext}
END_OF_DSL

my $grammar     = Marpa::R2::Scanless::G->new({
    action_object   => 'MarpaX::Test::Actions',
    # default_action  => '[name, values]',
    default_action  => 'default_action',
    # default_action  => 'flattenArray',
    source => \$dsl
});

my $parser  = Marpa::R2::Scanless::R->new({ grammar => $grammar });
my $input   = readFile($ARGV[0]);

$parser->read(\$input);
$input = undef;

my $value_ref   = $parser->value();

print Data::Dump::dump($value_ref);

exit 0;

# ------------------------------------------------------------------------------------ #
# Example grammar actions                                                              #
# ------------------------------------------------------------------------------------ #

package MarpaX::Test::Actions;
use strict;

sub new
{
    my ($class) = @_;
    return bless {}, $class;
}

sub flattenArray
{
    my ($self, $items) = @_;
    my $result = $items;
    if (ref $items eq "ARRAY")
    {
        if (scalar @$items != 1)
        {
            die "\$items must hold exactly 1 items";
        }
        $result = @{$items}[0];
    }
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

    return $result;
}

1;

# ABSTRACT: create a parse tree from an input file by applying a Marpa grammar

=head1 SYNOPSIS

testmarpagrammar_from_file.pl -g ./plsql.mx ./ddl/create_package.sql

=head1 DESCRIPTION
Create the Marpa grammar from option '-g' and apply it to the text from the input file,
then dump the parse tree.
=cut
