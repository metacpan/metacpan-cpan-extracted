package Make::Rule::Vars;

use strict;
use warnings;
use Carp;
## no critic (ValuesAndExpressions::ProhibitConstantPragma)
use constant DEBUG => $ENV{MAKE_DEBUG};
## use critic

our $VERSION = '2.007';
my @KEYS = qw( @ * ^ ? < );
my $i;
## no critic (BuiltinFunctions::RequireBlockMap)
my %NEXTKEY = map +( $_ => ++$i ), @KEYS;
## use critic

# Package to handle automatic variables pertaining to rules e.g. $@ $* $^ $?
# by using tie to this package 'subsvars' can work with array of
# hash references to possible sources of variable definitions.

sub TIEHASH {
    my ( $class, $rule, $target ) = @_;
    return bless [ $rule, $target ], $class;
}

sub FIRSTKEY {
    return $KEYS[0];
}

sub NEXTKEY {
    my ( $self, $lastkey ) = @_;
    return $KEYS[ $NEXTKEY{$lastkey} ];
}

sub EXISTS {
    my ( $self, $key ) = @_;
    return exists $NEXTKEY{$key};
}

sub FETCH {
    my ( $self, $v )      = @_;
    my ( $rule, $target ) = @$self;
    DEBUG and print STDERR "FETCH $v for ", $target->Name, "\n";
    return $target->Name if $v eq '@';
    return $target->Base if $v eq '*';
    return join ' ', @{ $rule->prereqs }         if $v eq '^';
    return join ' ', $rule->out_of_date($target) if $v eq '?';
    return ( @{ $rule->prereqs } )[0] if $v eq '<';
    return;
}

1;
