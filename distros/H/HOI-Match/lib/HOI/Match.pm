package HOI::Match;

require Exporter;

use Parse::Lex;
use HOI::typeparser;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw( pmatch );
our $VERSION = '0.072';

my @tokens = (
    qw (
        LPAREN      [\(]
        RPAREN      [\)]
        CONCAT      ::
        STRCONCAT   [:]
        NIL         nil
        IDENT       [A-Za-z_][A-Za-z0-9_]*
        CONST       (?:0(?:\.[0-9]+)?)|(?:[1-9][0-9]*(?:\.[0-9]+)?)|(?:\".*\")|(?:\'.*\')
    ),
    COMMA => q/,/
);

my $lexer = Parse::Lex->new(@tokens);
$lexer->skip('\s+');
my $parser = HOI::typeparser->new();

sub lexana {
    my $token = $lexer->next;
    if (not $lexer->eoi) {
        return ($token->name, $token->text);
    } else {
        return ('', undef);
    }
}

my %compiled_patterns;

sub pcompile {
    $lexer->from(shift);
    $parser->YYParse(yylex => \&lexana)
}

sub astmatch {
    my ($ast, $args) = @_;
    return (0, {}) if ($#{$ast} ne $#{$args});
    my %switches = (
        "const" =>
        sub {
            my ($sym, $val) = @_;
            if( (substr($sym, 0, 1) eq '\'') or (substr($sym, 0, 1) eq '"') ) {
                my $quote = substr($sym, 0, 1);
                return ($sym eq $quote.$val.$quote) ? (1, {}) : (0, {});
            } else {
                return ($sym == $val) ? (1, {}) : (0, {});
            }
        },
        "any" => 
        sub { 
            my ($sym, $val) = @_; 
            (1, ((substr($sym, 0, 1) ne '_') ? { $sym => $val } : {})) 
        },
        "list" => 
        sub { 
            my ($l, $val) = @_; 
            if (($#{$l} >= 0) and ($#{$val} >= 0)) {
                my ($s1, $r1) = astmatch([ $l->[0] ], [ $val->[0] ]);
                my ($s2, $r2) = astmatch([ $l->[1] ], [ [ @$val[1..$#{$val}] ] ]);
                return ($s1 * $s2, { %$r1, %$r2 });
            } elsif (($#{$l} < 0) and ($#{$val} < 0)) {
                return (1, {});
            } else {
                return (0, {});
            }
        },
        "adt" =>
        sub { 
            my ($adt, $val) = @_;
            return (0, {}) if ((not defined $val->{"type"}) or (not defined $val->{"val"}));
            my ($sym, $typelist) = ($adt->[0], $adt->[1]);
            return (0, {}) if ($adt->[0] ne $val->{"type"});
            return (0, {}) if ($#{$adt->[1]} != $#{$val->{"val"}});
            astmatch($adt->[1], $val->{"val"})
        },
        "strspl" =>
        sub {
            my ($idents, $val) = @_;
            my ($x, $xs);
            if ( ($x, $xs) = ($val =~ /(.)(.*)/s) ) {
                return (1, { $idents->[0] => $x, $idents->[1] => $xs });
            } else {
                return (0, {});
            }
        }
    );
    my $ret = {};
    for (my $idx = 0; $idx <= $#{$ast}; $idx++) {
        my ($status, $result) = $switches{$ast->[$idx]->{"kind"}}->($ast->[$idx]->{"val"}, $args->[$idx]);
        if ($status) {
            $ret = { %$ret, %$result };
        } else {
            return (0, {})
        }
    }
    (1, $ret)
}

sub pmatch {
    my $patterns = \@_;
    sub {
        my $args = \@_;
        while (@$patterns) {
            my $pattern = shift @$patterns;
            my $handler = shift @$patterns;
            my $pattern_sig = (caller(1))[3].$pattern;
            $compiled_patterns{$pattern_sig} = pcompile($pattern) if (not defined $compiled_patterns{$pattern_sig});
            my $pattern_ast = $compiled_patterns{$pattern_sig};
            my ($status, $results) = astmatch($pattern_ast, $args);
            if ($status) {
                my ($package) = caller(1);
                local $AttrPrefix = $package.'::';
                #attr $results;
                my $evalstr = '';
                for my $key (keys %$results) {
                    $evalstr .= 'local $'."$AttrPrefix"."$key".' = $results->{'."$key".'}; ';
                }
                return eval "{ $evalstr ".'$handler->(%$results); }';
            }
        }
        0
    }
}

1;
__END__

=head1 NAME

HOI::Match - Higher-Order Imperative "Re"features in Perl

=head1 SYNOPSIS

  use HOI::Match;

  sub point_extract {
      HOI::Match::pmatch(
          "point (x _) :: r" => sub { my %args = @_; $args{x} + point_extract($args{r}) },
          "nil" => sub { 0 }
      )->(@_)
  }

  point_extract(
      [ 
          {"type" => "point", "val" => [ 1, 2 ]},
          {"type" => "point", "val" => [ 2, 4 ]},
          {"type" => "point", "val" => [ 3, 6 ]},
      ]
  ) # we will get 6


=head1 DESCRIPTION

HOI::Match offers Erlang-like pattern matching in function parameters. 
Currently only wildcard symbols, lists and algebraic-data-type like hashrefs
are supported.

A wildcard symbol ([A-Za-z_][A-Za-z0-9_]*) matches exactly one argument.
A list is represented as an array reference. 
An algebraic-data-typed object is represented as an hashref with two keys,
namely "type", which gives its typename, and "val", which is an array reference 
containing zero or more wildcard symbols, lists, or algebraic-data-typed objects.
Multiple constructors for a given algebraic data type named A are allowed.

The BNF used to define the pattern grammar is given below:


Types: Type 
     | Type COMMA Types 


Type: CONST
    | IDENT 
    | Type CONCAT Type 
    | NIL 
    | IDENT LPAREN Typelist RPAREN 
    | IDENT STRCONCAT IDENT


Typelist: <eps>
        | Type Typelist 


where

CONST = (?:0(?:\.[0-9]+)?)|(?:[1-9][0-9]*(?:\.[0-9]+)?)|(?:\".*\")|(?:\'.*\')

IDENT = [A-Za-z_][A-Za-z0-9_]*

CONCAT = ::

STRCONCAT = :

NIL = nil

LPAREN = (

RPAREN = )

COMMA = ,

are tokens.

=head2 pmatch

The function pmatch takes an hash-formed array, which contains pattern-
subroutine pairs, where patterns are strings, sequently.

The patterns will be matched sequently. That is,

    "x, y"
    "point (_ x), y"

on arguments 
    ( { "type" => "point", "val" => [ 1, 2 ] }, 3 ) 
will be successfully matched with pattern
    "x, y" 
instead of 
    "point (_ x), y".

On a successful match, the values corresponding to identifiers in the pattern
will be passed to the subroutine in a hash. You can access them as named arguments with

    my %args = @_;

Identifiers that begin with an underscore ('_') will be ignored. They will not
be passed to the subroutine.

Version 0.07 offers aliases for identifiers in the pattern.
See the test files for details.

=head1 AUTHOR

withering <withering@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by withering

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.18.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
