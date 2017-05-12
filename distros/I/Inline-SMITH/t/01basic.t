use strict;
use Inline "SMITH";
use Test;

# Vars.
my $tests;
BEGIN { $tests = 0 };

# Basic loading.
ok(1);
BEGIN { $tests +=1 };

BEGIN { plan tests => $tests };


__END__
__SMITH__

function hello_world {{
  ; Hello, world in SMITH - version 2 (loop)
  ; R0 -> index into string (starts at R10)
  ; R2 -> -1
  MOV R0, 10
  MOV R2, 0
  SUB R2, 1
  MOV R[R0], "Hello, world!"
  MOV TTY, R[R0]
  SUB R0, R2
  MOV R1, R0
  SUB R1, 23
  NOT R1
  NOT R1
  MUL R1, 8
  COR +1, -7, R1
}}
