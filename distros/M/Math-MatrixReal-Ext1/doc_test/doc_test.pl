  use Math::MatrixReal::Ext1;

  $ident3x3 = Math::MatrixReal::Ext1->new_from_cols([[1,0,0],[0,1,0],[0,0,1]]);
  $upper_tri = Math::MatrixReal::Ext1->new_from_rows([[1,1,1],[0,1,1],[0,0,1]]);

  $col1 = Math::MatrixReal->new_from_string("[ 1 ]\n[ 3 ]\n[ 5 ]\n");
  $col2 = Math::MatrixReal->new_from_string("[ 2 ]\n[ 4 ]\n[ 6 ]\n");

  $mat = Math::MatrixReal::Ext1->new_from_cols( [ $col1, $col2 ]);
  print "$ident3x3\n\n$upper_tri\n\n$mat\n\n";


