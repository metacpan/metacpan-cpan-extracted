{ compile with: fpc add.pas                 |
| link with:    gcc -o add.so -shared add.o }

Unit Add;

Interface

Function Add( A: Integer; B: Integer) : Integer; Cdecl;

Implementation

Function Add( A: Integer; B: Integer) : Integer; Cdecl;
Begin
  Add := A + B;
End;

End.

