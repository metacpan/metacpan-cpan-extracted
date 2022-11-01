Unit MyUnit;

Interface

Function Add( A: Integer; B: Integer): Integer; Cdecl;

Implementation

Function Add( A: Integer; B: Integer) : Integer; Cdecl;
Begin
  Add := A + B;
End;

End.
