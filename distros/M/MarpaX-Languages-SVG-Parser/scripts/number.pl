#!/usr/bin/env perl

use strict;
use warnings;

use Marpa::R2;

my $grammar_source = do {local $/; <DATA>};
my $g = Marpa::R2::Scanless::G->new({source => \$grammar_source, bless_package => 'test'});
foreach my $this (@ARGV) {
    my $r = Marpa::R2::Scanless::R->new({grammar => $g});
    $r->read(\$this);
    my $float = eval ${$r->value};
    print "$this\t=>\t$float\n";
}
__DATA__
:default ::= action => ::first
:start ::= number

number  ::= F_CONSTANT
          | I_CONSTANT

:lexeme ~ <I_CONSTANT>         priority => -101
I_CONSTANT ~ HP H_many IS_maybe
           | BP B_many IS_maybe   # Gcc extension: binary constants
           | SIGN_maybe NZ D_any IS_maybe
           | '0' O_any IS_maybe
           | CP_maybe QUOTE I_CONSTANT_INSIDE_many QUOTE

:lexeme ~ <F_CONSTANT>         priority => -102
F_CONSTANT ~ SIGN_maybe D_many E FS_maybe
           | SIGN_maybe D_any '.' D_many E_maybe FS_maybe
           | SIGN_maybe D_many '.' E_maybe FS_maybe
           | HP H_many P FS_maybe
           | HP H_any '.' H_many P FS_maybe
           | HP H_many '.' P FS_maybe

B          ~ [0-1]
B_many     ~ B+
BP         ~ '0' [bB]
BS         ~ '\'
CP         ~ [uUL]
CP_maybe   ~ CP
CP_maybe   ~
D          ~ [0-9]
D_any      ~ D*
D_many     ~ D+
E          ~ [Ee] SIGN_maybe D_many
E_maybe    ~ E
E_maybe    ~
ES_AFTERBS ~ [\'\"\?\\abfnrtv]
           | O
           | O O
           | O O O
           | 'x' H_many
ES         ~ BS ES_AFTERBS
FS         ~ [fFlL]
FS_maybe   ~ FS
FS_maybe   ~
HP         ~ '0' [xX]
H          ~ [a-fA-F0-9]
H_any      ~ H*
H_many     ~ H+
I_CONSTANT_INSIDE ~ [^'\\\n]
I_CONSTANT_INSIDE ~ ES
I_CONSTANT_INSIDE_many ~ I_CONSTANT_INSIDE+
IS         ~ U LL_maybe | LL U_maybe
IS_maybe   ~ IS
IS_maybe   ~
LL         ~ 'll' | 'LL' | [lL]
LL_maybe   ~ LL
LL_maybe   ~
NZ         ~ [1-9]
O          ~ [0-7]
O_any      ~ O*
P          ~ [Pp] SIGN_maybe D_many
QUOTE     ~ [']
SIGN_maybe ~ [+-]
SIGN_maybe ~
U          ~ [uU]
U_maybe    ~ U
U_maybe    ~

WS         ~ [\s]
WS_many    ~ WS+
:discard   ~ WS_many       # whitespace separates tokens
