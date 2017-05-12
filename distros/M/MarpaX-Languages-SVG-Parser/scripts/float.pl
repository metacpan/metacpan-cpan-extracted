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
:start ::= float

float ::= F_CONSTANT action => ::first

F_CONSTANT ~ SIGN_maybe D_many E FS_maybe
           | SIGN_maybe D_any '.' D_many E_maybe FS_maybe
           | SIGN_maybe D_many '.' E_maybe FS_maybe
           | HP H_many P FS_maybe
           | HP H_any '.' H_many P FS_maybe
           | HP H_many '.' P FS_maybe

D          ~ [0-9]
D_any      ~ D*
D_many     ~ D+
E          ~ [Ee] SIGN_maybe D_many
E_maybe    ~ E
E_maybe    ~
FS         ~ [fFlL]
FS_maybe   ~ FS
FS_maybe   ~
HP         ~ '0' [xX]
H          ~ [a-fA-F0-9]
H_any      ~ H*
H_many     ~ H+
P          ~ [Pp] SIGN_maybe D_many
SIGN_maybe ~ [+-]
SIGN_maybe ~

WS         ~ [\s]
WS_many    ~ WS+
:discard   ~ WS_many       # whitespace separates tokens
