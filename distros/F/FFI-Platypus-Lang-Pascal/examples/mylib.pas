{ compile and link with: fpc mylib.pas }

Library MyLib;

Function Add(A: Integer; B: Integer): Integer; Cdecl;
Begin
  Add := A + B;
End;

Exports
  Add;

End.
