package Karel::Parser::Czech;

=head1 NAME

=encoding UTF-8

Karel::Parser::Czech

=head1 DESCRIPTION

Implements the Czech version of the Karel language:

  příkaz
  vlevo
  krok
  polož
  zvedni
  stůj
  když|dokud je|není značka|zeď|sever|východ|jih|západ
  jinak
  opakuj 5 krát|x
  hotovo
  konec

=cut

use warnings;
use strict;
use utf8;

use Moo;
extends 'Karel::Parser';
use namespace::clean;

{   package # Hide from CPAN.
        Karel::Parser::Czech::Actions;

    'Karel::Parser::Actions'->import(qw( def concat left forward pick
                                         drop stop repeat While If
                                         negate call list defs run ));

    sub object {
        { značka => 'm',
          zeď    => 'w',
          sever  => 'N',
          východ => 'E',
          jih    => 'S',
          západ  => 'W',
        }->{ $_[1] }
    }
}

my %terminals = (
    poloz      => 'polož',
    stuj       => 'stůj',
    kdyz       => 'když',
    prikaz     => 'příkaz',
    octothorpe => '#',
    neni       => 'není',
    znacka     => 'značka',
    zed        => 'zeď',
    vychod     => 'východ',
    zapad      => 'západ',
    krat       => 'krát',
);
$terminals{$_} = $_
    for qw( vlevo krok hotovo jinak opakuj konec dokud zvedni je sever jih );
sub _terminals { \%terminals }

my $dsl = << '__DSL__';

:default ::= action => ::undef
lexeme default = latm => 1

START      ::= Defs                       action => ::first
             | (Run SC) Command           action => run
Run        ::= 'run'                      action => [ values, start, length ]

Defs       ::= Def+  separator => SC      action => defs
Def        ::= Def2                       action => [ values, start, length ]
Def2       ::= (SCMaybe) (prikaz) (SC) CommandDef (SC) Prog (SC) (konec)
                                          action => def
NewCommand ::= CommandDef                 action => [ values, start, length ]
CommandDef ::= alpha valid_name           action => concat
Prog       ::= Commands                   action => ::first
Commands   ::= Command+  separator => SC  action => list
Command    ::= Vlevo                      action => left
             | Krok                       action => forward
             | Poloz                      action => drop
             | Zvedni                     action => pick
             | Stuj                       action => stop
             | Opakuj                     action => repeat
             | Dokud                      action => While
             | Kdyz                       action => If
             | NewCommand                 action => call
Vlevo      ::= vlevo                      action => [ start, length ]
Krok       ::= krok                       action => [ start, length ]
Poloz      ::= poloz                      action => [ start, length ]
Zvedni     ::= zvedni                     action => [ start, length ]
Stuj       ::= stuj                       action => [ start, length ]
Opakuj     ::= (opakuj SC) Num (SC Times SC) Prog (SC hotovo)
                                          action => [ values, start, length ]
Dokud      ::= (dokud SC) Condition (SC) Prog (hotovo)
                                          action => [ values, start, length ]
Kdyz       ::= (kdyz SC) Condition (SC) Prog (hotovo)
                                          action => [ values, start, length ]
             | (kdyz SC) Condition (SC) Prog (SC jinak SC) Prog (hotovo)
                                          action => [ values, start, length ]
Condition  ::= (je SC) Object             action => ::first
             | (neni SC) Object           action => negate
Object     ::= znacka                     action => object
             | zed                        action => object
             | sever                      action => object
             | vychod                     action => object
             | jih                        action => object
             | zapad                      action => object
Num        ::= non_zero                   action => ::first
             | non_zero digits            action => concat
Times      ::= krat
             | x
Comment    ::= (octothorpe non_lf lf)
SC         ::= SpComm+
SCMaybe    ::= SpComm*
SpComm     ::= Comment
            || space

alpha      ~ [[:lower:]]
valid_name ~ [-[:lower:]_0-9]+
non_zero   ~ [1-9]
digits     ~ [0-9]+
space      ~ [\s]+
non_lf     ~ [^\n]*
lf         ~ [\n]
x          ~ [x×]

__DSL__

$dsl .= join "\n", map "$_ ~ '$terminals{$_}'", keys %terminals;

around _dsl => sub { $dsl };

around _action_class => sub { 'Karel::Parser::Czech::Actions' };

__PACKAGE__
