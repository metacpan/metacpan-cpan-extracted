Unit MyUnit;

Interface

Uses
  Crt;

Function Add( A: Integer; B: Integer): Integer; Cdecl;
{ Function Add( A: Real; B: Real ): Real; Cdecl; }
Function Add2( A: Integer; B: Integer ): Integer; Cdecl;
Procedure OneArg( I: Integer ); Cdecl;
Procedure OneArg( S: String ); Cdecl;
Procedure NoArgs(); Cdecl;
Procedure F1(I: Integer); Cdecl;
Procedure F1(R: Real); Cdecl;

Implementation

Function Add( A: Integer; B: Integer) : Integer; Cdecl;
Begin
  Add := A + B;
End;

Function Add2( A: Integer; B: Integer) : Integer; Cdecl;
Begin
  Add2 := A + B;
End;

{Function Add( A: Real; B: Real) : Real; Cdecl;
Begin
  Add := A + B;
End;}

Procedure OneArg( I: Integer ); Cdecl;
Begin
  WriteLn(I);
End;

Procedure OneArg( S: String ); Cdecl;
Begin
  WriteLn(S);
End;

Procedure NoArgs(); Cdecl;
Begin
  WriteLn('[X,Y]=[', WhereX(), ',', WhereY(), ']');
End;

Procedure F1(I:Integer); Cdecl;
Begin
End;

Procedure F1(R:Real); Cdecl;
Begin
End;

End.
